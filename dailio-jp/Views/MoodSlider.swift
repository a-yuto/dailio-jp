import SwiftUI

/// 気分 0〜10 の連続値スライダー。赤（0）→ 緑（10）のグラデーション。
struct MoodSlider: View {
    @Binding var value: Double

    private let range: ClosedRange<Double> = 0...10

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.red, .orange, .yellow, .green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 12)
                    .opacity(0.85)

                GeometryReader { geo in
                    let clamped = min(max(value, range.lowerBound), range.upperBound)
                    let ratio = (clamped - range.lowerBound) / (range.upperBound - range.lowerBound)
                    Circle()
                        .fill(.white)
                        .overlay(Circle().stroke(.black.opacity(0.15), lineWidth: 1))
                        .shadow(radius: 1, y: 1)
                        .frame(width: 28, height: 28)
                        .offset(x: ratio * (geo.size.width - 28), y: -8)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    let raw = drag.location.x / max(geo.size.width - 28, 1)
                                    let bounded = min(max(raw, 0), 1)
                                    value = range.lowerBound + bounded * (range.upperBound - range.lowerBound)
                                }
                        )
                }
                .frame(height: 12)
            }
            .frame(height: 28)

            HStack {
                Text("0：最悪")
                Spacer()
                Text("5：普通")
                Spacer()
                Text("10：最高")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    @Previewable @State var value: Double = 5
    MoodSlider(value: $value)
        .padding()
}
