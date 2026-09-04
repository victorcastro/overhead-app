import CloudKit
import Foundation

enum CloudDataEraser {
    private static let zoneName = "com.apple.coredata.cloudkit.zone"

    static func eraseAll(settings: AppSettings) async throws {
        settings.iCloudSyncEnabled = false

        let database = CKContainer(identifier: ExpenseStore.cloudContainerIdentifier).privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)

        do {
            _ = try await database.deleteRecordZone(withID: zoneID)
        } catch let error as CKError {
            guard error.code == .zoneNotFound || error.code == .unknownItem else { throw error }
        }

        settings.clearCloudMirror()
    }
}
