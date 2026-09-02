import Foundation
import Observation

@Observable
final class AppSettings {
    var baseCurrency: Currency {
        didSet { defaults.set(baseCurrency.rawValue, forKey: Self.baseCurrencyKey) }
    }

    var locationCodes: [String] {
        didSet { defaults.set(locationCodes, forKey: Self.locationCodesKey) }
    }

    var hasLocations: Bool { !locationCodes.isEmpty }

    @ObservationIgnored private let defaults: UserDefaults
    private static let baseCurrencyKey = "baseCurrency"
    private static let locationCodesKey = "locationCodes"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let raw = defaults.string(forKey: Self.baseCurrencyKey),
           let stored = Currency(rawValue: raw) {
            baseCurrency = stored
        } else {
            baseCurrency = .usd
        }

        locationCodes = defaults.stringArray(forKey: Self.locationCodesKey) ?? []
    }
}
