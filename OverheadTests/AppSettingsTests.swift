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
