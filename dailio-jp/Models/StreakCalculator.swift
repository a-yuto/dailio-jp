import Foundation

/// 連続記録日数を算出する純粋関数群。テスト容易性のため struct で副作用なし。
struct StreakCalculator {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// `entries` の record 日付集合から、`reference` を起点に遡る連続日数を返す。
    /// - Note: reference 当日に記録がなくても「昨日まで N 日連続」として扱う（プレッシャー軽減）。
    func currentStreak(entries: [MoodEntry], reference: Date = .now) -> Int {
        guard !entries.isEmpty else { return 0 }
        let recordedDays: Set<Date> = Set(entries.map { calendar.startOfDay(for: $0.date) })

        let referenceStart = calendar.startOfDay(for: reference)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceStart) ?? referenceStart

        var cursor = recordedDays.contains(referenceStart) ? referenceStart : yesterday
        var count = 0
        while recordedDays.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }
}
