import SwiftUI

/// アプリのロック状態を管理する @Observable コントローラ。
/// scenePhase の変化を受けて再ロックを判定する。
@Observable
@MainActor
final class LockController {
    /// ロック設定が ON の間、true ならロック画面を表示。
    private(set) var isLocked: Bool = true

    /// 認証中フラグ（ボタン連打防止）。
    private(set) var isAuthenticating: Bool = false

    /// 直近の失敗メッセージ。
    private(set) var lastError: String?

    private let auth = AuthService()

    /// ロック設定が OFF のとき、isLocked を false にする（外部から呼ぶ）。
    func setLockEnabled(_ enabled: Bool) {
        if !enabled {
            isLocked = false
        }
    }

    /// 必要に応じて再ロックする（バックグラウンドから復帰したときなど）。
    func relockIfEnabled(_ enabled: Bool) {
        if enabled {
            isLocked = true
        }
    }

    /// 認証を実行してロック解除。
    func unlock() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            try await auth.authenticate(reason: String(localized: "アプリのロックを解除します"))
            isLocked = false
            lastError = nil
        } catch AuthService.AuthError.cancelled {
            // ユーザーキャンセルは黙る
        } catch AuthService.AuthError.notAvailable {
            // 認証が利用できない端末ではロックを掛けない
            isLocked = false
            lastError = nil
        } catch {
            lastError = String(localized: "認証に失敗しました")
        }
    }

    var biometryName: String { auth.biometryName() }
}
