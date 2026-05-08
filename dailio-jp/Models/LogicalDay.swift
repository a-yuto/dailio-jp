import Foundation

/// 論理日 = ユーザーのカレンダー日。日付の同一性判定と前夜睡眠の集計レンジを担う。
struct LogicalDay: Hashable, Sendable {
    let calendar: Calendar
    let referenceDate: Date

    init(of date: Date, calendar: Calendar = .current) {
        self.calendar = calendar
        self.referenceDate = date
    }

    /// 論理日の安定キー（その日の正午）
    var canonicalDate: Date {
        let components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        var noon = DateComponents()
        noon.year = components.year
        noon.month = components.month
        noon.day = components.day
        noon.hour = 12
        return calendar.date(from: noon) ?? referenceDate
    }

    /// 前夜睡眠の HealthKit クエリ範囲（前日 18:00 〜 当日 12:00）
    var previousNightSleepRange: Range<Date> {
        let startOfDay = calendar.startOfDay(for: referenceDate)
        let prevEvening = calendar.date(byAdding: .hour, value: -6, to: startOfDay) ?? startOfDay
        let noon = calendar.date(byAdding: .hour, value: 12, to: startOfDay) ?? startOfDay
        return prevEvening..<noon
    }

    func isSameDay(as other: Date) -> Bool {
        calendar.isDate(referenceDate, inSameDayAs: other)
    }
}
