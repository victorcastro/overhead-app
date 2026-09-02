import Foundation
import SwiftData

enum ExpenseStore {
    static let cloudContainerIdentifier = "iCloud.dev.victorcastro.SinkingFound"

    /// Builds the SwiftData container. Both modes point at the same store file, so turning
    /// sync on uploads the expenses that already exist instead of starting from scratch.
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
            // No iCloud session, unprovisioned container, or no network. Fall back to the
            // local store instead of destroying it.
            print("[SinkingFound] CloudKit store unavailable, falling back to local storage.")
        }

        return makeLocalContainer(schema: schema)
    }

    private static func makeLocalContainer(schema: Schema) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Only the local store is wiped and retried: reaching here means the store file
            // itself is unreadable, which no amount of retrying fixes.
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
