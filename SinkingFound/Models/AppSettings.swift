import Foundation
import Observation

@Observable
final class AppSettings {
    static let baseCurrencyKey = "baseCurrency"
    static let locationCodesKey = "locationCodes"
    static let decimalPlacesKey = "decimalPlaces"
    private static let iCloudSyncEnabledKey = "iCloudSyncEnabled"
    static let defaultDecimalPlaces = 2
    static let decimalPlacesOptions = Array(0...4)

    var baseCurrency: Currency {
        didSet {
            defaults.set(baseCurrency.rawValue, forKey: Self.baseCurrencyKey)
            mirrorToCloud(baseCurrency.rawValue, forKey: Self.baseCurrencyKey)
        }
    }

    var locationCodes: [String] {
        didSet {
            defaults.set(locationCodes, forKey: Self.locationCodesKey)
            mirrorToCloud(locationCodes, forKey: Self.locationCodesKey)
        }
    }

    var iCloudSyncEnabled: Bool {
        didSet {
            defaults.set(iCloudSyncEnabled, forKey: Self.iCloudSyncEnabledKey)
            guard iCloudSyncEnabled else { return }
            mirrorToCloud(baseCurrency.rawValue, forKey: Self.baseCurrencyKey)
            mirrorToCloud(locationCodes, forKey: Self.locationCodesKey)
            mirrorToCloud(decimalPlaces, forKey: Self.decimalPlacesKey)
        }
    }

    var decimalPlaces: Int {
        didSet {
            decimalPlaces = Self.clampedDecimalPlaces(decimalPlaces)
            guard decimalPlaces != oldValue else { return }
            defaults.set(decimalPlaces, forKey: Self.decimalPlacesKey)
            mirrorToCloud(decimalPlaces, forKey: Self.decimalPlacesKey)
        }
    }

    var hasLocations: Bool { !locationCodes.isEmpty }
    var hasMultipleLocations: Bool { locationCodes.count > 1 }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let ubiquitous: KeyValueStore
    @ObservationIgnored private var externalChangeObserver: (any NSObjectProtocol)?

    init(
        defaults: UserDefaults = .standard,
        ubiquitous: KeyValueStore = NSUbiquitousKeyValueStore.default
    ) {
        self.defaults = defaults
        self.ubiquitous = ubiquitous

        let syncEnabled = defaults.bool(forKey: Self.iCloudSyncEnabledKey)
        iCloudSyncEnabled = syncEnabled

        let cloudCurrency = syncEnabled ? ubiquitous.string(forKey: Self.baseCurrencyKey) : nil
        if let raw = cloudCurrency ?? defaults.string(forKey: Self.baseCurrencyKey),
           let stored = Currency(rawValue: raw) {
            baseCurrency = stored
        } else {
            baseCurrency = .usd
        }

        let cloudCodes = syncEnabled ? ubiquitous.array(forKey: Self.locationCodesKey) as? [String] : nil
        locationCodes = cloudCodes ?? defaults.stringArray(forKey: Self.locationCodesKey) ?? []

        let cloudDecimals = syncEnabled ? ubiquitous.object(forKey: Self.decimalPlacesKey) as? Int : nil
        let storedDecimals = defaults.object(forKey: Self.decimalPlacesKey) as? Int
        decimalPlaces = Self.clampedDecimalPlaces(
            cloudDecimals ?? storedDecimals ?? Self.defaultDecimalPlaces
        )

        observeExternalChanges()
    }

    deinit {
        if let externalChangeObserver {
            NotificationCenter.default.removeObserver(externalChangeObserver)
        }
    }

    static func clampedDecimalPlaces(_ value: Int) -> Int {
        guard let first = decimalPlacesOptions.first, let last = decimalPlacesOptions.last else { return value }
        return min(max(value, first), last)
    }

    func clearCloudMirror() {
        ubiquitous.removeObject(forKey: Self.baseCurrencyKey)
        ubiquitous.removeObject(forKey: Self.locationCodesKey)
        ubiquitous.removeObject(forKey: Self.decimalPlacesKey)
        ubiquitous.synchronize()
    }

    private func mirrorToCloud(_ value: Any, forKey key: String) {
        guard iCloudSyncEnabled else { return }
        ubiquitous.set(value, forKey: key)
        ubiquitous.synchronize()
    }

    private func observeExternalChanges() {
        externalChangeObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.applyCloudValues()
            }
        }
    }

    @MainActor
    private func applyCloudValues() {
        guard iCloudSyncEnabled else { return }

        if let raw = ubiquitous.string(forKey: Self.baseCurrencyKey),
           let stored = Currency(rawValue: raw),
           stored != baseCurrency {
            baseCurrency = stored
        }

        if let codes = ubiquitous.array(forKey: Self.locationCodesKey) as? [String],
           codes != locationCodes {
            locationCodes = codes
        }

        if let decimals = ubiquitous.object(forKey: Self.decimalPlacesKey) as? Int,
           Self.clampedDecimalPlaces(decimals) != decimalPlaces {
            decimalPlaces = decimals
        }
    }
}
