import Foundation
import SwiftData

enum ExpenseStore {
    static let cloudContainerIdentifier = "iCloud.dev.victorcastro.SinkingFound"

    static func makeContainer(cloudSyncEnabled: Bool) -> ModelContainer {
        let schema = Schema([FixedExpense.self])

        if cloudSyncEnabled {
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(cloudContainerIdentifier)
            )
            if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
                return container
            }
            print("[SinkingFound] CloudKit store unavailable, falling back to local storage.")
        }

        return makeLocalContainer(schema: schema)
    }

    private static func makeLocalContainer(schema: Schema) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            let path = configuration.url.path
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: path + suffix)
            }
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }
}
