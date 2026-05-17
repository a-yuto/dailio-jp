#if DEBUG
import Foundation
import SwiftData

/// App Store スクリーンショット撮影用の起動引数ハンドラ。Debug ビルドのみ。
///
/// UITest（`ScreenshotUITests`）が起動引数で決定論的な状態を作る。アプリ自身が
/// 目的の画面・状態で立ち上がるので、UITest 側はタブ操作不要（iPhone/iPad で同一、
/// フレーク最小）:
/// - `-screenshotMode`           … マスタースイッチ。ロック無効化。
/// - `-screenshotOnboarding`     … オンボーディング welcome を撮るため未完了のまま。
/// - `-screenshotTab <name>`     … 起動タブ: entry / history / settings
/// - `-screenshotMA <on|off>`    … 履歴の 7 日移動平均トグル初期値
///
/// 本番ビルドには `#if DEBUG` により一切含まれない。
@MainActor
enum ScreenshotLaunch {
    private static var args: [String] { ProcessInfo.processInfo.arguments }

    static var isActive: Bool { args.contains("-screenshotMode") }

    static func configure(container: ModelContainer) {
        guard isActive else { return }
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: LockSettingsKey.isEnabled)

        if args.contains("-screenshotOnboarding") {
            defaults.set(false, forKey: OnboardingKey.isCompleted)
            return
        }
        defaults.set(true, forKey: OnboardingKey.isCompleted)

        // グラフ・曜日別・ひとこと履歴が映えるよう 60 日分を投入（毎回作り直し）
        try? DummyDataSeeder().seed(context: container.mainContext, days: 60)
        // 記録画面が「ひとこと」入りで映えるよう、今日の記録を固定値で上書き
        let repo = MoodRepository(context: container.mainContext)
        _ = try? repo.upsert(
            on: .now, mood: 7, sleepHours: 7.5,
            sleepSource: .healthKit, note: "散歩で気分転換できた"
        )
        try? container.mainContext.save()
    }

    /// `-screenshotTab <entry|history|settings>`
    static var initialTab: ContentView.Tab? {
        guard isActive,
              let i = args.firstIndex(of: "-screenshotTab"),
              i + 1 < args.count else { return nil }
        switch args[i + 1] {
        case "entry": return .entry
        case "history": return .history
        case "settings": return .settings
        default: return nil
        }
    }

    /// `-screenshotMA <on|off>`
    static var movingAverageOverride: Bool? {
        guard isActive,
              let i = args.firstIndex(of: "-screenshotMA"),
              i + 1 < args.count else { return nil }
        switch args[i + 1] {
        case "on": return true
        case "off": return false
        default: return nil
        }
    }
}
#endif
