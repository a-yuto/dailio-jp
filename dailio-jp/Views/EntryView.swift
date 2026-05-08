import SwiftUI
import SwiftData

/// 1 日 1 回の記録画面。気分スライダー + 睡眠時間 + ストリーク。
struct EntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodEntry.date, order: .reverse) private var allEntries: [MoodEntry]

    @State private var mood: Double = 5
    @State private var sleepHours: Double? = 7.0
    @State private var sleepSource: SleepSource = .manual
    @State private var saveConfirmation: ConfirmationState = .idle

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
                }
                .padding()
            }
            .navigationTitle("dailio")
            .onAppear(perform: loadTodayIfExists)
        }
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
    }

    private func save() {
        saveConfirmation = .saving
        do {
            let repository = MoodRepository(context: modelContext)
            try repository.upsert(
                on: .now,
                mood: mood,
                sleepHours: sleepHours,
                sleepSource: sleepSource
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
