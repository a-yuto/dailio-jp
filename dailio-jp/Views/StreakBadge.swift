import SwiftUI

/// 連続記録日数を柔らかく表示するバッジ。プレッシャーを避けるため炎アイコンは抑えめ。
struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "leaf.fill")
                .foregroundStyle(.green)
            Text(streak == 0 ? "今日から記録を始めましょう" : "\(streak)日連続で記録中")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        StreakBadge(streak: 0)
        StreakBadge(streak: 1)
        StreakBadge(streak: 7)
    }
}
