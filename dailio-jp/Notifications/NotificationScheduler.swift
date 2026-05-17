import Foundation
import UserNotifications

/// 毎日 1 回のリマインダー通知を管理する。MainActor 既定（CLAUDE.md の Concurrency 規約）。
struct NotificationScheduler {
    static let dailyReminderID = "kibunlog.daily-reminder"

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// 通知許可を要求する。既に決定済みなら現在の許可状態をそのまま返す。
    @discardableResult
    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// 現在の許可状態を取得する。
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    /// 毎日指定時刻にリマインダーをスケジュールする（既存の同 ID を置き換え）。
    /// 文言は SeasonalReminderPresets で季節に応じたものを採用。
    func scheduleDailyReminder(at time: DateComponents) async throws {
        cancelDailyReminder()

        let presets = SeasonalReminderPresets()
        let content = UNMutableNotificationContent()
        content.title = presets.title()
        content.body = presets.body()
        content.sound = .default
        content.userInfo = ["destination": "entry"]

        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.dailyReminderID,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    /// 既存のリマインダーをキャンセルする。
    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderID])
    }
}
