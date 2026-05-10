import SwiftUI

/// オンボーディング全体のコンテナ。プログレス + 5 ステップを切替。
struct OnboardingView: View {
    @AppStorage(OnboardingKey.isCompleted) private var isCompleted: Bool = false
    @AppStorage(OnboardingKey.lastReachedStep) private var lastReachedStep: Int = 0

    @State private var current: OnboardingStep = .welcome

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: current.progress)
                .progressViewStyle(.linear)
                .padding()

            Group {
                switch current {
                case .welcome:
                    WelcomeStep(onNext: advance)
                case .healthKit:
                    HealthKitStep(onNext: advance, onSkip: advance)
                case .notifications:
                    NotificationStep(onNext: advance, onSkip: advance)
                case .tutorial:
                    TutorialStep(onNext: advance)
                case .complete:
                    CompleteStep(onFinish: finish)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity.combined(with: .move(edge: .trailing)))
            .animation(.easeInOut, value: current)

            HStack {
                if let previous = current.previous, current != .complete {
                    Button {
                        withAnimation { current = previous }
                    } label: {
                        Label("戻る", systemImage: "chevron.backward")
                    }
                }
                Spacer()
            }
            .padding()
        }
        .onChange(of: current) { _, newValue in
            lastReachedStep = max(lastReachedStep, newValue.rawValue)
        }
    }

    private func advance() {
        guard let next = current.next else {
            finish()
            return
        }
        withAnimation { current = next }
    }

    private func finish() {
        isCompleted = true
    }
}

#Preview {
    OnboardingView()
        .environment(\.sleepProvider, NullSleepProvider())
}
