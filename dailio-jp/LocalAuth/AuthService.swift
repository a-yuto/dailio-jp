import Foundation
import LocalAuthentication

/// 生体認証 / パスコード認証を扱う薄いラッパー。
struct AuthService {

    enum AuthError: Error {
        case notAvailable
        case failed
        case cancelled
    }

    /// この端末で生体認証 or パスコード認証が利用可能か。
    func isAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    /// 表示用の認証手段名（Face ID / Touch ID / パスコード）。
    func biometryName() -> String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return String(localized: "パスコード")
        @unknown default: return String(localized: "認証")
        }
    }

    /// 認証を実行する。生体 → ダメならパスコードへフォールバック。
    func authenticate(reason: String) async throws {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw AuthError.notAvailable
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if !success {
                throw AuthError.failed
            }
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .systemCancel, .appCancel:
                throw AuthError.cancelled
            default:
                throw AuthError.failed
            }
        }
    }
}
