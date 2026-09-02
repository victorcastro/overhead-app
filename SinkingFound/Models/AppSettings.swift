import Foundation
import Observation

@Observable
final class AppSettings {
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

    /// Never mirrored to iCloud: turning sync off on one device must not turn it off
    /// everywhere, which would leave no way to turn it back on.
    var iCloudSyncEnabled: Bool {
        didSet {
            defaults.set(iCloudSyncEnabled, forKey: Self.iCloudSyncEnabledKey)
            guard iCloudSyncEnabled else { return }
            mirrorToCloud(baseCurrency.rawValue, forKey: Self.baseCurrencyKey)
            mirrorToCloud(locationCodes, forKey: Self.locationCodesKey)
        }
    }

    var hasLocations: Bool { !locationCodes.isEmpty }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let ubiquitous: KeyValueStore
    @ObservationIgnored private var externalChangeObserver: (any NSObjectProtocol)?

    static let baseCurrencyKey = "baseCurrency"
    static let locationCodesKey = "locationCodes"
    private static let iCloudSyncEnabledKey = "iCloudSyncEnabled"

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

        observeExternalChanges()
    }

    deinit {
        if let externalChangeObserver {
            NotificationCenter.default.removeObserver(externalChangeObserver)
        }
    }

    private func mirrorToCloud(_ value: Any, forKey key: String) {
        guard iCloudSyncEnabled else { return }
        ubiquitous.set(value, forKey: key)
        ubiquitous.synchronize()
    }

    /// Removes the mirrored settings from iCloud. The local copies are left untouched.
    func clearCloudMirror() {
        ubiquitous.removeObject(forKey: Self.baseCurrencyKey)
        ubiquitous.removeObject(forKey: Self.locationCodesKey)
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
    }
}
