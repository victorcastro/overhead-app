import Foundation
import Testing
@testable import SinkingFound

struct AppSettingsTests {

    private func makeDefaults() -> UserDefaults {
        let suite = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func defaultsToNoLocations() {
        let settings = AppSettings(defaults: makeDefaults())
        #expect(settings.locationCodes.isEmpty)
        #expect(!settings.hasLocations)
    }

    @Test func locationCodesRoundTripThroughUserDefaults() {
        let defaults = makeDefaults()

        let first = AppSettings(defaults: defaults)
        first.locationCodes.append("ES")
        first.locationCodes.append("PE")

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.locationCodes == ["ES", "PE"])
        #expect(reloaded.hasLocations)

        reloaded.locationCodes.removeAll { $0 == "ES" }
        let again = AppSettings(defaults: defaults)
        #expect(again.locationCodes == ["PE"])
    }
}
