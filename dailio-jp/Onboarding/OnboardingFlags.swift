import Foundation

/// オンボーディング完了状態の AppStorage キー。
enum OnboardingKey {
    static let isCompleted = "onboarding.isCompleted"
    static let lastReachedStep = "onboarding.lastReachedStep"
}

/// オンボーディングのステップ。順序が ID とラベルを規定する。
enum OnboardingStep: Int, CaseIterable, Identifiable, Sendable {
    case welcome
    case healthKit
    case notifications
    case tutorial
    case complete

    var id: Int { rawValue }

    /// プログレスバー用に 0...1 の進捗を返す。
    var progress: Double {
        Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
    }

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    var previous: OnboardingStep? {
        OnboardingStep(rawValue: rawValue - 1)
    }
}
