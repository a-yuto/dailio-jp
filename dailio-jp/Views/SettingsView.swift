import SwiftUI
import SwiftData
import UserNotifications

/// 設定画面: リマインダー時刻 / ON-OFF / 通知許可 / Pro。
struct SettingsView: View {
    @Environment(EntitlementStore.self) private var entitlementStore
    @Environment(\.modelContext) private var modelContext

    @AppStorage(ReminderSettingsKey.isEnabled)
    private var isReminderEnabled: Bool = ReminderSettingsDefaults.isEnabled

    @AppStorage(ReminderSettingsKey.hour)
    private var reminderHour: Int = ReminderSettingsDefaults.hour

    @AppStorage(ReminderSettingsKey.minute)
    private var reminderMinute: Int = ReminderSettingsDefaults.minute

    @AppStorage(LockSettingsKey.isEnabled)
    private var isLockEnabled: Bool = false

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isPaywallPresented: Bool = false
    @State private var debugMessage: String?

    private let scheduler = NotificationScheduler()
    private let auth = AuthService()

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: reminderHour,
                    minute: reminderMinute,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { newValue in
                let comp = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = comp.hour ?? ReminderSettingsDefaults.hour
                reminderMinute = comp.minute ?? ReminderSettingsDefaults.minute
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                proSection

                Section {
                    Toggle("毎日のリマインダー", isOn: $isReminderEnabled)

                    if isReminderEnabled {
                        DatePicker(
                            "通知時刻",
                            selection: reminderTime,
                            displayedComponents: [.hourAndMinute]
                        )
                    }

                    if authorizationStatus == .denied {
                        Label("通知が iOS 設定でオフになっています", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.footnote)
                    } else if authorizationStatus == .notDetermined {
                        Button("通知を許可") {
                            Task { await requestAuthorization() }
                        }
                    }
                } header: {
                    Text("通知")
                } footer: {
                    Text("毎日の同じ時刻に記録を促す通知を送ります")
                }

                Section {
                    Toggle(isOn: $isLockEnabled) {
                        Label("アプリロック", systemImage: "lock.fill")
                    }
                    .disabled(!auth.isAvailable())

                    if !auth.isAvailable() {
                        Text("この端末では Face ID / Touch ID / パスコードが設定されていません")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("プライバシー")
                } footer: {
                    if auth.isAvailable() {
                        Text("起動時とバックグラウンド復帰時に \(auth.biometryName()) で認証を求めます")
                    }
                }

                Section {
                    LabeledContent("iCloud 同期") {
                        Image(systemName: "checkmark.icloud.fill")
                            .foregroundStyle(.blue)
                    }
                } header: {
                    Text("データ")
                } footer: {
                    Text("記録は iCloud のあなた専用コンテナに同期されます。同期を停止するには iOS 設定 > Apple ID > iCloud から きぶんログ をオフにしてください")
                }

                Section("このアプリについて") {
                    LabeledContent("バージョン", value: appVersion)
                }

                #if DEBUG
                debugSection
                #endif
            }
            .navigationTitle("設定")
            .task {
                await refreshAuthorization()
            }
            .onChange(of: isReminderEnabled) { _, _ in
                Task { await applyReminder() }
            }
            .onChange(of: reminderHour) { _, _ in
                Task { await applyReminder() }
            }
            .onChange(of: reminderMinute) { _, _ in
                Task { await applyReminder() }
            }
            .sheet(isPresented: $isPaywallPresented) {
                PurchaseView()
            }
        }
    }

    // MARK: - Pro section

    @ViewBuilder
    private var proSection: some View {
        Section("Pro") {
            if entitlementStore.isPro {
                Label("Pro 加入中", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                Button {
                    isPaywallPresented = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.tint)
                        Text("Pro にアップグレード")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption.bold())
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Debug

    #if DEBUG
    @ViewBuilder
    private var debugSection: some View {
        Section("Debug") {
            Button {
                runSeed(days: 60)
            } label: {
                Label("ダミーデータを生成 (60 日)", systemImage: "wand.and.stars")
            }

            Button(role: .destructive) {
                runClear()
            } label: {
                Label("全データを削除", systemImage: "trash")
            }

            if let debugMessage {
                Text(debugMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func runSeed(days: Int) {
        do {
            let count = try DummyDataSeeder().seed(context: modelContext, days: days)
            debugMessage = "\(count) 件のダミーデータを投入しました"
        } catch {
            debugMessage = "失敗: \(error.localizedDescription)"
        }
    }

    private func runClear() {
        do {
            try DummyDataSeeder().clear(context: modelContext)
            debugMessage = "全データを削除しました"
        } catch {
            debugMessage = "失敗: \(error.localizedDescription)"
        }
    }
    #endif

    // MARK: - Helpers

    private var appVersion: String {
        let dictionary = Bundle.main.infoDictionary ?? [:]
        let version = dictionary["CFBundleShortVersionString"] as? String ?? "—"
        let build = dictionary["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func refreshAuthorization() async {
        authorizationStatus = await scheduler.authorizationStatus()
    }

    private func requestAuthorization() async {
        do {
            _ = try await scheduler.requestAuthorization()
        } catch {
            // ユーザー操作中の取消などは握りつぶし
        }
        await refreshAuthorization()
        await applyReminder()
    }

    private func applyReminder() async {
        guard isReminderEnabled, authorizationStatus == .authorized else {
            scheduler.cancelDailyReminder()
            return
        }
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        try? await scheduler.scheduleDailyReminder(at: components)
    }
}

#Preview {
    SettingsView()
        .environment(EntitlementStore())
}
