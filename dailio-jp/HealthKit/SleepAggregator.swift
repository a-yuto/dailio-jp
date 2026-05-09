import Foundation

/// 睡眠セグメントを範囲にクリップして合計時間を算出する純関数。
/// HealthKit のサンプル数や境界跨ぎに依存しない、テスト可能なロジック。
struct SleepAggregator: Sendable {

    /// 範囲内の asleep 時間を時間単位で返す。
    /// セグメントが範囲を跨ぐ場合は範囲端でクリップする。
    func totalSleepHours(segments: [SleepSegment], in range: Range<Date>) -> Double {
        var totalSeconds: TimeInterval = 0
        for segment in segments where segment.isAsleep {
            let start = max(segment.start, range.lowerBound)
            let end = min(segment.end, range.upperBound)
            guard end > start else { continue }
            totalSeconds += end.timeIntervalSince(start)
        }
        return totalSeconds / 3600
    }
}
