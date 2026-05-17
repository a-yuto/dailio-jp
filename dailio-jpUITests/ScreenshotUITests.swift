//
//  ScreenshotUITests.swift
//  dailio-jpUITests
//
//  App Store 申請用スクリーンショットを自動撮影する。
//
//  アプリ側の DEBUG 起動引数（ScreenshotLaunch）が目的の画面・状態で起動するため、
//  ここではタブ操作を一切せず「起動 → 安定待ち →（必要なら）スクロール → 撮影」
//  だけ行う。iPhone/iPad で同一手順。要素が見つからなくてもアプリは起動引数で
//  正しい画面を出しているので、撮影自体は成立する（best-effort・ハードアサート無し）。
//
//  撮影結果は xcresult から `xcrun xcresulttool export attachments` で取り出す
//  （scripts/screenshots.sh 参照）。各テストが 1 枚だけ撮る。
//

import XCTest

final class ScreenshotUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func launch(_ extra: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-screenshotMode"] + extra
        app.launch()
        return app
    }

    private func snap(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 安定待ち（見つからなくても続行＝アプリは起動引数で正しい画面を出している）
    private func settle(_ app: XCUIApplication, _ label: String, timeout: TimeInterval = 25) {
        _ = app.staticTexts[label].waitForExistence(timeout: timeout)
        Thread.sleep(forTimeInterval: 1.2) // Charts 等の描画余裕
    }

    // MARK: - Shots

    @MainActor
    func testEntry() throws {
        let app = launch(["-screenshotTab", "entry"])
        settle(app, "今日の気分")
        snap("01-entry")
    }

    @MainActor
    func testHistoryMovingAverage() throws {
        let app = launch(["-screenshotTab", "history", "-screenshotMA", "on"])
        settle(app, "履歴")
        snap("02-history-movingaverage")
    }

    @MainActor
    func testHistoryRaw() throws {
        let app = launch(["-screenshotTab", "history", "-screenshotMA", "off"])
        settle(app, "履歴")
        snap("03-history-raw")
    }

    @MainActor
    func testWeekdaySummary() throws {
        let app = launch(["-screenshotTab", "history", "-screenshotMA", "on"])
        settle(app, "履歴")
        let scroll = app.scrollViews.firstMatch
        if scroll.waitForExistence(timeout: 5) {
            scroll.swipeUp()
            scroll.swipeUp()
            Thread.sleep(forTimeInterval: 1.0)
        }
        snap("04-weekday-summary")
    }

    @MainActor
    func testOnboarding() throws {
        let app = launch(["-screenshotOnboarding"])
        settle(app, "きぶんログ へようこそ")
        snap("05-onboarding")
    }
}
