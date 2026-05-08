import SwiftUI
import SwiftData

@main
struct TradeTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Trade.self,
            Purchase.self,
            TradeHistory.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedModelContainer)
    }
}
