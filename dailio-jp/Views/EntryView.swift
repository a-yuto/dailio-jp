import SwiftUI
import SwiftData

/// 1 日 1 回の記録画面。気分スライダー + 睡眠時間 + ストリーク。
struct EntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.sleepProvider) private var sleepProvider
    @Query(sort: \MoodEntry.date, order: .reverse) private var allEntries: [MoodEntry]

    @State private var mood: Double = 5
    @State private var sleepHours: Double? = 7.0
    @State private var sleepSource: SleepSource = .manual
    @State private var note: String = ""
    @State private var saveConfirmation: ConfirmationState = .idle

    /// HealthKit prefill 直後の値。これと sleepHours が一致する間は source = .healthKit。
    /// ユーザーが Stepper を動かして値が変わったら source を .manual に切り替える。
    @State private var lastAutoSleepHours: Double? = nil

    private static let noteMaxLength = 100

    private var streak: Int {
        StreakCalculator().currentStreak(entries: allEntries)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    StreakBadge(streak: streak)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("今日の気分")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(mood.rounded())) / 10")
                                .font(.title3.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                        MoodSlider(value: $mood)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )

                    SleepInputField(sleepHours: $sleepHours, source: sleepSource)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                        )

                    noteCard

                    Button(action: save) {
                        Text(saveConfirmation == .saved ? "保存しました" : "今日の記録を保存")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(saveConfirmation == .saved ? Color.green : Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(saveConfirmation == .saving)

                    BannerSlot()
                }
                .padding()
            }
            .navigationTitle("きぶんログ")
            .task {
                loadTodayIfExists()
                await prefillFromHealthKit()
            }
            .onChange(of: sleepHours) { _, newValue in
                if newValue != lastAutoSleepHours {
                    sleepSource = .manual
                }
            }
        }
    }

    // MARK: - Note Card

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("今日のひとこと")
                    .font(.headline)
                Spacer()
                Text("\(note.count) / \(Self.noteMaxLength)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(note.count >= Self.noteMaxLength ? .orange : .secondary)
            }

            TextField(
                "今日の気持ちを一言で（任意）",
                text: $note,
                axis: .horizontal
            )
            .textFieldStyle(.plain)
            .submitLabel(.done)
            .onChange(of: note) { _, newValue in
                if newValue.count > Self.noteMaxLength {
                    note = String(newValue.prefix(Self.noteMaxLength))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Actions

    private func loadTodayIfExists() {
        let calendar = Calendar.current
        guard let today = allEntries.first(where: { calendar.isDateInToday($0.date) }) else {
            return
        }
        mood = today.mood
        sleepHours = today.sleepHours
        sleepSource = today.sleepSource
        note = today.note
        lastAutoSleepHours = today.sleepSource == .healthKit ? today.sleepHours : nil
    }

    private func prefillFromHealthKit() async {
        // 既に手動入力で値が入っていれば上書きしない
        if let existing = allEntries.first(where: { Calendar.current.isDateInToday($0.date) }),
           existing.sleepSource == .manual {
            return
        }
        do {
            try await sleepProvider.requestAuthorization()
            guard let hours = try await sleepProvider.previousNightSleepHours(for: .now) else {
                return
            }
            let rounded = (hours * 2).rounded() / 2  // 0.5 時間刻み
            lastAutoSleepHours = rounded
            sleepHours = rounded
            sleepSource = .healthKit
        } catch {
            // 権限拒否や取得不可は黙ってフォールバック（手動入力のまま）
        }
    }

    private func save() {
        saveConfirmation = .saving
        do {
            let repository = MoodRepository(context: modelContext)
            try repository.upsert(
                on: .now,
                mood: mood,
                sleepHours: sleepHours,
                sleepSource: sleepSource,
                note: note
            )
            try modelContext.save()
            saveConfirmation = .saved
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                saveConfirmation = .idle
            }
        } catch {
            saveConfirmation = .idle
        }
    }

    private enum ConfirmationState {
        case idle, saving, saved
    }
}

#Preview {
    EntryView()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
