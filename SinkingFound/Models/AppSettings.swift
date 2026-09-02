import Foundation
import Observation

@Observable
final class AppSettings {
    var baseCurrency: Currency {
        didSet { defaults.set(baseCurrency.rawValue, forKey: Self.baseCurrencyKey) }
    }

    @ObservationIgnored private let defaults: UserDefaults
    private static let baseCurrencyKey = "baseCurrency"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.baseCurrencyKey),
           let stored = Currency(rawValue: raw) {
            baseCurrency = stored
        } else {
            baseCurrency = .usd
        }
    }
}
