import SwiftUI
import SwiftData

@main
struct dailio_jpApp: App {
    @UIApplicationDelegateAdaptor(NotificationDelegate.self) private var notificationDelegate

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MoodEntry.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private let sleepProvider: any SleepProvider = HealthKitSleepProvider()
    @State private var entitlementStore = EntitlementStore()
    @State private var lockController = LockController()

    @AppStorage(LockSettingsKey.isEnabled) private var isLockEnabled: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.sleepProvider, sleepProvider)
                .environment(entitlementStore)
                .environment(lockController)
                .overlay {
                    if isLockEnabled, lockController.isLocked {
                        LockedView(lock: lockController)
                    }
                }
                .task {
                    await entitlementStore.refresh()
                    lockController.setLockEnabled(isLockEnabled)
                }
                .onChange(of: isLockEnabled) { _, newValue in
                    lockController.setLockEnabled(newValue)
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    // バックグラウンド or インアクティブから active 遷移時に再ロック
                    if newPhase == .active, oldPhase != .active {
                        lockController.relockIfEnabled(isLockEnabled)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
