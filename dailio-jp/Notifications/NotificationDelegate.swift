import UIKit
import UserNotifications

/// 通知の前景表示と、タップ時の deep link を扱う AppDelegate。
/// SwiftUI からは UIApplicationDelegateAdaptor 経由で接続する。
final class NotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    /// deep link の宛先キー。userInfo の "destination" 値と対応。
    enum Destination: String {
        case entry
    }

    /// 通知タップ時に送出する Notification.Name。
    static let openDestinationNotification = Notification.Name("kibunlog.openDestination")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// アプリ前景時にも通知を表示する。
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    /// 通知タップ → 宛先を NotificationCenter にブロードキャスト。
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let raw = response.notification.request.content.userInfo["destination"] as? String,
           let destination = Destination(rawValue: raw) {
            NotificationCenter.default.post(
                name: Self.openDestinationNotification,
                object: destination
            )
        }
        completionHandler()
    }
}
