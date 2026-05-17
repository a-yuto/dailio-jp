import SwiftUI

// MARK: - Welcome

/// Step 1: ようこそ画面。「2 項目だけ」コンセプト訴求。
struct WelcomeStep: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 96))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("きぶんログ へようこそ")
                    .font(.largeTitle.bold())
                Text("気分と睡眠だけ。30 秒で続けられる")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "slider.horizontal.3", text: "気分は 0〜10 のスライダーだけ")
                FeatureRow(icon: "moon.zzz.fill", text: "睡眠は HealthKit から自動取込")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "気分と睡眠の相関が見える")
            }
            .frame(maxWidth: 320)

            Spacer()

            Button(action: onNext) {
                Text("はじめる")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
        }
        .padding()
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: LocalizedStringResource

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(.tint)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - HealthKit

/// Step 2: HealthKit 睡眠データ許可。
struct HealthKitStep: View {
    @Environment(\.sleepProvider) private var sleepProvider
    let onNext: () -> Void
    let onSkip: () -> Void

    @State private var isRequesting: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 80))
                .foregroundStyle(.red)

            VStack(spacing: 8) {
                Text("睡眠データを連携")
                    .font(.title.bold())
                Text("Apple ヘルスケアから前夜の睡眠を自動で取得します")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task { await request() }
                } label: {
                    if isRequesting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("ヘルスケアを許可")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isRequesting)

                Button("あとで", action: onSkip)
                    .buttonStyle(.borderless)
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private func request() async {
        isRequesting = true
        defer { isRequesting = false }
        try? await sleepProvider.requestAuthorization()
        onNext()
    }
}

// MARK: - Notifications

/// Step 3: 通知許可 + 入力時刻設定。
struct NotificationStep: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    @AppStorage(ReminderSettingsKey.hour) private var reminderHour: Int = ReminderSettingsDefaults.hour
    @AppStorage(ReminderSettingsKey.minute) private var reminderMinute: Int = ReminderSettingsDefaults.minute
    @AppStorage(ReminderSettingsKey.isEnabled) private var isReminderEnabled: Bool = ReminderSettingsDefaults.isEnabled

    @State private var isRequesting: Bool = false

    private let scheduler = NotificationScheduler()

    private var time: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: .now) ?? .now
            },
            set: { newValue in
                let comp = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = comp.hour ?? ReminderSettingsDefaults.hour
                reminderMinute = comp.minute ?? ReminderSettingsDefaults.minute
            }
        )
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("毎日のリマインダー")
                    .font(.title.bold())
                Text("入力を忘れないように 1 日 1 回だけ通知します")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            DatePicker("通知時刻", selection: time, displayedComponents: [.hourAndMinute])
                .datePickerStyle(.wheel)
                .frame(maxHeight: 160)
                .clipped()

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task { await request() }
                } label: {
                    if isRequesting {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("通知を許可")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isRequesting)

                Button("あとで", action: onSkip)
                    .buttonStyle(.borderless)
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private func request() async {
        isRequesting = true
        defer { isRequesting = false }
        let granted = (try? await scheduler.requestAuthorization()) ?? false
        if granted {
            isReminderEnabled = true
            var comp = DateComponents()
            comp.hour = reminderHour
            comp.minute = reminderMinute
            try? await scheduler.scheduleDailyReminder(at: comp)
        }
        onNext()
    }
}

// MARK: - Tutorial

/// Step 4: 初回入力チュートリアル。スライダーを動かしてもらう。
struct TutorialStep: View {
    let onNext: () -> Void

    @State private var mood: Double = 5

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("試しに動かしてみて")
                    .font(.title.bold())
                Text("気分は 0（最悪）〜10（最高）の連続値")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Text("\(Int(mood.rounded())) / 10")
                    .font(.system(size: 72, weight: .bold, design: .rounded).monospacedDigit())
                MoodSlider(value: $mood)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )

            Spacer()

            Button {
                onNext()
            } label: {
                Text("次へ")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Complete

/// Step 5: 完了。明日からのフローを案内。
struct CompleteStep: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 96))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("準備完了")
                    .font(.largeTitle.bold())
                Text("今日から記録を始めましょう。グラフは数日続けると表示されます")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()

            Button(action: onFinish) {
                Text("きぶんログ を開く")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
        }
        .padding()
    }
}
