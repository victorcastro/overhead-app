import SwiftUI
import SwiftData

@main
struct SinkingFoundApp: App {
    @State private var settings = AppSettings()

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([FixedExpense.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            let path = modelConfiguration.url.path
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: path + suffix)
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(settings)
        }
        .modelContainer(sharedModelContainer)
    }
}
