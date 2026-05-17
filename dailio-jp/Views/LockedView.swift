import SwiftUI

/// アプリロック中に表示するフルスクリーンの認証画面。
struct LockedView: View {
    let lock: LockController

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: lock.biometryName == "Face ID" ? "faceid" : "lock.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text("ロック中")
                    .font(.title2.bold())

                Text("ロックを解除して きぶんログ を使う")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    Task { await lock.unlock() }
                } label: {
                    HStack {
                        Image(systemName: "lock.open.fill")
                        Text(String(localized: "\(lock.biometryName) で解除"))
                    }
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(lock.isAuthenticating)

                if let error = lock.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .task {
            await lock.unlock()
        }
    }
}

#Preview {
    LockedView(lock: LockController())
}
