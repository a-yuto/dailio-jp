import Foundation

/// HealthKit から独立した睡眠セグメント表現。
/// テストとロジックを HealthKit から切り離すための中間値型。
struct SleepSegment: Hashable, Sendable {
    let start: Date
    let end: Date
    let stage: Stage

    enum Stage: String, Sendable, CaseIterable {
        case inBed
        case asleepUnspecified
        case asleepCore
        case asleepDeep
        case asleepREM
        case awake
    }

    var duration: TimeInterval { end.timeIntervalSince(start) }

    /// 「実際に眠っている」とみなすステージ。
    /// inBed と awake は除外、asleepUnspecified は古い計測機器互換のため含める。
    static let asleepStages: Set<Stage> = [
        .asleepCore,
        .asleepDeep,
        .asleepREM,
        .asleepUnspecified
    ]

    var isAsleep: Bool { Self.asleepStages.contains(stage) }
}
