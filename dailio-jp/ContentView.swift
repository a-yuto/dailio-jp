import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Tab = .entry

    init() {
        #if DEBUG
        if let tab = ScreenshotLaunch.initialTab {
            _selectedTab = State(initialValue: tab)
        }
        #endif
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            EntryView()
                .tabItem {
                    Label("記録", systemImage: "square.and.pencil")
                }
                .tag(Tab.entry)

            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.history)

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationDelegate.openDestinationNotification)) { notification in
            guard let destination = notification.object as? NotificationDelegate.Destination else { return }
            switch destination {
            case .entry:
                selectedTab = .entry
            }
        }
    }

    enum Tab: Hashable {
        case entry
        case history
        case settings
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
