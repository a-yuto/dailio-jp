import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        EntryView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
