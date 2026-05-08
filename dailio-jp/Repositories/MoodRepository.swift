import Foundation
import SwiftData

/// MoodEntry の CRUD と論理日 upsert を担うリポジトリ。
@MainActor
struct MoodRepository {
    let context: ModelContext

    /// 同一論理日があれば更新、なければ新規作成。
    @discardableResult
    func upsert(
        on date: Date,
        mood: Double,
        sleepHours: Double?,
        sleepSource: SleepSource,
        calendar: Calendar = .current
    ) throws -> MoodEntry {
        let day = LogicalDay(of: date, calendar: calendar)
        let canonical = day.canonicalDate
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

        let predicate = #Predicate<MoodEntry> { entry in
            entry.date >= dayStart && entry.date < dayEnd
        }
        var descriptor = FetchDescriptor<MoodEntry>(predicate: predicate)
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.mood = mood
            existing.sleepHours = sleepHours
            existing.sleepSource = sleepSource
            existing.updatedAt = .now
            return existing
        }

        let new = MoodEntry(
            date: canonical,
            mood: mood,
            sleepHours: sleepHours,
            sleepSource: sleepSource
        )
        context.insert(new)
        return new
    }

    /// 直近 N 日のエントリを古い順で返す。
    func recent(days: Int, until date: Date = .now, calendar: Calendar = .current) throws -> [MoodEntry] {
        let end = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: date) ?? date)
        let start = calendar.date(byAdding: .day, value: -days, to: end) ?? end
        let predicate = #Predicate<MoodEntry> { entry in
            entry.date >= start && entry.date < end
        }
        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try context.fetch(descriptor)
    }
}
