import Foundation
import SwiftData

@Model
final class MoodEntry {
    /// 論理日の正午（タイムゾーン依存しない安定キー）
    /// 既定値は CloudKit 互換のため必須。
    var date: Date = Date.now
    /// 0〜10、連続値
    var mood: Double = 5.0
    /// 前夜の睡眠時間（時間単位）
    var sleepHours: Double?
    var sleepSource: SleepSource = SleepSource.manual
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

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
