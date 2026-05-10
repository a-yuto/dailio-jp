import Foundation

/// リマインダー設定の AppStorage キー。
enum ReminderSettingsKey {
    static let isEnabled = "reminder.isEnabled"
    static let hour = "reminder.hour"
    static let minute = "reminder.minute"
}

/// リマインダー設定のデフォルト値。
enum ReminderSettingsDefaults {
    static let isEnabled = true
    static let hour = 22
    static let minute = 0
}

/// アプリロック設定の AppStorage キー。
enum LockSettingsKey {
    static let isEnabled = "lock.isEnabled"
}
