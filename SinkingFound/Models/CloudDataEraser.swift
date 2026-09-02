import CloudKit
import Foundation

enum CloudDataEraser {
    /// The single record zone `NSPersistentCloudKitContainer` writes the SwiftData store into.
    private static let zoneName = "com.apple.coredata.cloudkit.zone"

    /// Deletes this app's data from the user's private iCloud database. Local data is left
    /// untouched. Sync must already be off: erasing the zone while the store is still
    /// syncing leaves stale CloudKit metadata behind.
    static func eraseAll(settings: AppSettings) async throws {
        settings.iCloudSyncEnabled = false

        let database = CKContainer(identifier: ExpenseStore.cloudContainerIdentifier).privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)

        do {
            _ = try await database.deleteRecordZone(withID: zoneID)
        } catch let error as CKError where error.code == .zoneNotFound || error.code == .unknownItem {
            // Nothing was ever uploaded. Treat as success.
        }

        settings.clearCloudMirror()
    }
}
