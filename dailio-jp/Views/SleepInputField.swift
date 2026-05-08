import SwiftUI

/// 睡眠時間の入力。時間直接入力モードのみ（時刻入力モードは Phase 1 末で追加可）。
struct SleepInputField: View {
    @Binding var sleepHours: Double?
    let source: SleepSource

    private var sleepBinding: Binding<Double> {
        Binding(
            get: { sleepHours ?? 7.0 },
            set: { sleepHours = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("睡眠時間")
                    .font(.headline)
                Spacer()
                sourceBadge
            }

            HStack {
                Stepper(
                    value: sleepBinding,
                    in: 0...14,
                    step: 0.5
                ) {
                    Text(formatted(sleepHours ?? 7.0))
                        .monospacedDigit()
                }
            }
        }
    }

    private var sourceBadge: some View {
        Text(source == .healthKit ? "HealthKit 自動" : "手動")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(
                    source == .healthKit
                        ? Color.blue.opacity(0.15)
                        : Color.gray.opacity(0.15)
                )
            )
            .foregroundStyle(source == .healthKit ? Color.blue : Color.secondary)
    }

    private func formatted(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m == 0 ? "\(h) 時間" : "\(h) 時間 \(m) 分"
    }
}

#Preview {
    @Previewable @State var hours: Double? = 7.5
    SleepInputField(sleepHours: $hours, source: .manual)
        .padding()
}
