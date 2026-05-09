import SwiftUI

/// 睡眠時間データソースの抽象。
/// 本番は HealthKit、テスト/プレビューはモックを Environment 経由で注入する。
protocol SleepProvider: Sendable {
    /// 必要に応じて権限要求。既に許可済み or 拒否済みなら no-op。
    func requestAuthorization() async throws

    /// 指定日の「前夜」睡眠時間（HealthKit 集計）を返す。
    /// 取得不可・データなしのときは nil。
    func previousNightSleepHours(for date: Date) async throws -> Double?
}

/// テスト/プレビュー/HealthKit 不可端末向けの noop 実装。
struct NullSleepProvider: SleepProvider {
    func requestAuthorization() async throws {}
    func previousNightSleepHours(for date: Date) async throws -> Double? { nil }
}

private struct SleepProviderKey: EnvironmentKey {
    static let defaultValue: any SleepProvider = NullSleepProvider()
}

extension EnvironmentValues {
    var sleepProvider: any SleepProvider {
        get { self[SleepProviderKey.self] }
        set { self[SleepProviderKey.self] = newValue }
    }
}
