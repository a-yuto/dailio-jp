import Foundation
import SwiftData

@Model
final class MoodEntry {
    /// 論理日の正午（タイムゾーン依存しない安定キー）
    var date: Date
    /// 0〜10、連続値
    var mood: Double
    /// 前夜の睡眠時間（時間単位）
    var sleepHours: Double?
    var sleepSource: SleepSource
    var createdAt: Date
    var updatedAt: Date

    init(
        date: Date,
        mood: Double,
        sleepHours: Double? = nil,
        sleepSource: SleepSource = .manual,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.date = date
        self.mood = mood
        self.sleepHours = sleepHours
        self.sleepSource = sleepSource
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension MoodEntry {
    /// 表示用の整数気分値
    var displayMood: Int {
        Int(mood.rounded())
    }
}
