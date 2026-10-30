import Foundation
import Testing
@testable import Overhead

private final class FakeKeyValueStore: KeyValueStore {
    var storage: [String: Any] = [:]
    private(set) var synchronizeCount = 0

    func string(forKey key: String) -> String? { storage[key] as? String }
    func array(forKey key: String) -> [Any]? { storage[key] as? [Any] }
    func object(forKey key: String) -> Any? { storage[key] }
    func set(_ value: Any?, forKey key: String) { storage[key] = value }
    func removeObject(forKey key: String) { storage.removeValue(forKey: key) }

    @discardableResult func synchronize() -> Bool {
        synchronizeCount += 1
        return true
    }
}

struct AppSettingsTests {

    private func makeDefaults() -> UserDefaults {
        let suite = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func defaultsToNoLocations() {
        let settings = AppSettings(defaults: makeDefaults(), ubiquitous: FakeKeyValueStore())
        #expect(settings.locationCodes.isEmpty)
        #expect(!settings.hasLocations)
    }

    @Test func locationCodesRoundTripThroughUserDefaults() {
        let defaults = makeDefaults()
        let cloud = FakeKeyValueStore()

        let first = AppSettings(defaults: defaults, ubiquitous: cloud)
        first.locationCodes.append("ES")
        first.locationCodes.append("PE")

        let reloaded = AppSettings(defaults: defaults, ubiquitous: cloud)
        #expect(reloaded.locationCodes == ["ES", "PE"])
        #expect(reloaded.hasLocations)

        reloaded.locationCodes.removeAll { $0 == "ES" }
        let again = AppSettings(defaults: defaults, ubiquitous: cloud)
        #expect(again.locationCodes == ["PE"])
    }

    @Test func reminderDaysBeforeKeepsSeveralSelectedDaysSorted() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults, ubiquitous: FakeKeyValueStore())

        settings.reminderDaysBefore = [7, 0, 3]
        #expect(settings.reminderDaysBefore == [0, 3, 7])
        #expect(defaults.array(forKey: AppSettings.reminderDaysBeforeKey) as? [Int] == [0, 3, 7])

        let reloaded = AppSettings(defaults: defaults, ubiquitous: FakeKeyValueStore())
        #expect(reloaded.reminderDaysBefore == [0, 3, 7])
    }

    @Test func reminderDaysBeforeDropsUnknownAndDuplicateValues() {
        let settings = AppSettings(defaults: makeDefaults(), ubiquitous: FakeKeyValueStore())
        settings.reminderDaysBefore = [5, 4, 5, 9]
        #expect(settings.reminderDaysBefore == [5])
    }

    @Test func reminderDaysBeforeFallsBackToDefaultWhenEmpty() {
        let settings = AppSettings(defaults: makeDefaults(), ubiquitous: FakeKeyValueStore())
        settings.reminderDaysBefore = [7]
        settings.reminderDaysBefore = []
        #expect(settings.reminderDaysBefore == AppSettings.defaultReminderDaysBefore)
    }

    @Test func reminderDaysBeforeMigratesTheSingleValueFormat() {
        let defaults = makeDefaults()
        defaults.set(3, forKey: AppSettings.reminderDaysBeforeKey)
        let settings = AppSettings(defaults: defaults, ubiquitous: FakeKeyValueStore())
        #expect(settings.reminderDaysBefore == [3])
    }

    @Test func reminderMinutesDefaultToNineAndPersist() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults, ubiquitous: FakeKeyValueStore())
        #expect(settings.reminderMinutes == 9 * 60)

        settings.reminderMinutes = 20 * 60 + 30
        let reloaded = AppSettings(defaults: defaults, ubiquitous: FakeKeyValueStore())
        #expect(reloaded.reminderMinutes == 20 * 60 + 30)
    }

    @Test func reminderMinutesAreClampedToTheDay() {
        let settings = AppSettings(defaults: makeDefaults(), ubiquitous: FakeKeyValueStore())
        settings.reminderMinutes = 5000
        #expect(settings.reminderMinutes == 24 * 60 - 1)
        settings.reminderMinutes = -10
        #expect(settings.reminderMinutes == 0)
    }

    @Test func decimalPlacesAreClampedWithoutRecursing() {
        let settings = AppSettings(defaults: makeDefaults(), ubiquitous: FakeKeyValueStore())
        settings.decimalPlaces = 9
        #expect(settings.decimalPlaces == AppSettings.decimalPlacesOptions.last)
        settings.decimalPlaces = 3
        #expect(settings.decimalPlaces == 3)
    }

    @Test func syncIsOffByDefault() {
        let settings = AppSettings(defaults: makeDefaults(), ubiquitous: FakeKeyValueStore())
        #expect(!settings.iCloudSyncEnabled)
    }

    @Test func writesStayLocalWhileSyncIsOff() {
        let cloud = FakeKeyValueStore()
        let settings = AppSettings(defaults: makeDefaults(), ubiquitous: cloud)

        settings.baseCurrency = .eur
        settings.locationCodes = ["PE"]

        #expect(cloud.storage.isEmpty)
    }

    @Test func writesReachBothBackendsWhileSyncIsOn() {
        let defaults = makeDefaults()
        let cloud = FakeKeyValueStore()
        let settings = AppSettings(defaults: defaults, ubiquitous: cloud)

        settings.iCloudSyncEnabled = true
        settings.baseCurrency = .gbp
        settings.locationCodes = ["ES", "PE"]

        #expect(cloud.storage[AppSettings.baseCurrencyKey] as? String == "GBP")
        #expect(cloud.storage[AppSettings.locationCodesKey] as? [String] == ["ES", "PE"])
        #expect(defaults.string(forKey: AppSettings.baseCurrencyKey) == "GBP")
        #expect(defaults.stringArray(forKey: AppSettings.locationCodesKey) == ["ES", "PE"])
    }

    @Test func turningSyncOnUploadsTheCurrentValues() {
        let cloud = FakeKeyValueStore()
        let settings = AppSettings(defaults: makeDefaults(), ubiquitous: cloud)

        settings.baseCurrency = .pen
        settings.locationCodes = ["PE"]
        #expect(cloud.storage.isEmpty)

        settings.iCloudSyncEnabled = true

        #expect(cloud.storage[AppSettings.baseCurrencyKey] as? String == "PEN")
        #expect(cloud.storage[AppSettings.locationCodesKey] as? [String] == ["PE"])
    }

    @Test func cloudValuesWinOnLoadWhileSyncIsOn() {
        let defaults = makeDefaults()
        let cloud = FakeKeyValueStore()

        let first = AppSettings(defaults: defaults, ubiquitous: cloud)
        first.baseCurrency = .usd
        first.iCloudSyncEnabled = true

        cloud.storage[AppSettings.baseCurrencyKey] = "EUR"
        cloud.storage[AppSettings.locationCodesKey] = ["GB"]

        let reloaded = AppSettings(defaults: defaults, ubiquitous: cloud)
        #expect(reloaded.baseCurrency == .eur)
        #expect(reloaded.locationCodes == ["GB"])
    }

    @Test func localValuesWinOnLoadWhileSyncIsOff() {
        let defaults = makeDefaults()
        let cloud = FakeKeyValueStore()
        cloud.storage[AppSettings.baseCurrencyKey] = "EUR"

        let settings = AppSettings(defaults: defaults, ubiquitous: cloud)
        #expect(settings.baseCurrency == .usd)
    }

    @Test func syncFlagIsNeverMirrored() {
        let cloud = FakeKeyValueStore()
        let settings = AppSettings(defaults: makeDefaults(), ubiquitous: cloud)

        settings.iCloudSyncEnabled = true

        #expect(cloud.storage["iCloudSyncEnabled"] == nil)
    }

    @Test func clearingTheMirrorLeavesLocalValuesAlone() {
        let defaults = makeDefaults()
        let cloud = FakeKeyValueStore()
        let settings = AppSettings(defaults: defaults, ubiquitous: cloud)

        settings.iCloudSyncEnabled = true
        settings.baseCurrency = .eur
        settings.locationCodes = ["ES"]

        settings.clearCloudMirror()

        #expect(cloud.storage.isEmpty)
        #expect(defaults.string(forKey: AppSettings.baseCurrencyKey) == "EUR")
        #expect(defaults.stringArray(forKey: AppSettings.locationCodesKey) == ["ES"])
        #expect(settings.baseCurrency == .eur)
    }
}
