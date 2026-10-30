import Foundation
import Observation

@Observable
final class AppSettings {
    static let baseCurrencyKey = "baseCurrency"
    static let locationCodesKey = "locationCodes"
    static let decimalPlacesKey = "decimalPlaces"
    private static let iCloudSyncEnabledKey = "iCloudSyncEnabled"
    static let remindersEnabledKey = "remindersEnabled"
    static let reminderDaysBeforeKey = "reminderDaysBefore"
    static let reminderMinutesKey = "reminderMinutes"
    static let defaultDecimalPlaces = 2
    static let decimalPlacesOptions = Array(0...4)
    static let defaultReminderDaysBefore = [1]
    static let reminderDaysBeforeOptions = [0, 1, 3, 5, 7]
    static let defaultReminderMinutes = 9 * 60
    static let reminderMinutesRange = 0...(24 * 60 - 1)

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
            mirrorToCloud(remindersEnabled, forKey: Self.remindersEnabledKey)
            mirrorToCloud(reminderDaysBefore, forKey: Self.reminderDaysBeforeKey)
            mirrorToCloud(reminderMinutes, forKey: Self.reminderMinutesKey)
        }
    }

    var decimalPlaces: Int {
        didSet {
            let clamped = Self.clampedDecimalPlaces(decimalPlaces)
            guard clamped == decimalPlaces else {
                decimalPlaces = clamped
                return
            }
            guard decimalPlaces != oldValue else { return }
            defaults.set(decimalPlaces, forKey: Self.decimalPlacesKey)
            mirrorToCloud(decimalPlaces, forKey: Self.decimalPlacesKey)
        }
    }

    var remindersEnabled: Bool {
        didSet {
            guard remindersEnabled != oldValue else { return }
            defaults.set(remindersEnabled, forKey: Self.remindersEnabledKey)
            mirrorToCloud(remindersEnabled, forKey: Self.remindersEnabledKey)
        }
    }

    var reminderDaysBefore: [Int] {
        didSet {
            let normalized = Self.normalizedReminderDaysBefore(reminderDaysBefore)
            guard normalized == reminderDaysBefore else {
                reminderDaysBefore = normalized
                return
            }
            guard reminderDaysBefore != oldValue else { return }
            defaults.set(reminderDaysBefore, forKey: Self.reminderDaysBeforeKey)
            mirrorToCloud(reminderDaysBefore, forKey: Self.reminderDaysBeforeKey)
        }
    }

    var reminderMinutes: Int {
        didSet {
            let clamped = Self.clampedReminderMinutes(reminderMinutes)
            guard clamped == reminderMinutes else {
                reminderMinutes = clamped
                return
            }
            guard reminderMinutes != oldValue else { return }
            defaults.set(reminderMinutes, forKey: Self.reminderMinutesKey)
            mirrorToCloud(reminderMinutes, forKey: Self.reminderMinutesKey)
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

        let cloudReminders = syncEnabled ? ubiquitous.object(forKey: Self.remindersEnabledKey) as? Bool : nil
        let storedReminders = defaults.object(forKey: Self.remindersEnabledKey) as? Bool
        remindersEnabled = cloudReminders ?? storedReminders ?? false

        let cloudDaysBefore = syncEnabled
            ? Self.reminderDaysBefore(from: ubiquitous.object(forKey: Self.reminderDaysBeforeKey))
            : nil
        let storedDaysBefore = Self.reminderDaysBefore(from: defaults.object(forKey: Self.reminderDaysBeforeKey))
        reminderDaysBefore = Self.normalizedReminderDaysBefore(
            cloudDaysBefore ?? storedDaysBefore ?? Self.defaultReminderDaysBefore
        )

        let cloudMinutes = syncEnabled ? ubiquitous.object(forKey: Self.reminderMinutesKey) as? Int : nil
        let storedMinutes = defaults.object(forKey: Self.reminderMinutesKey) as? Int
        reminderMinutes = Self.clampedReminderMinutes(
            cloudMinutes ?? storedMinutes ?? Self.defaultReminderMinutes
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

    static func clampedReminderMinutes(_ value: Int) -> Int {
        min(max(value, reminderMinutesRange.lowerBound), reminderMinutesRange.upperBound)
    }

    static func normalizedReminderDaysBefore(_ values: [Int]) -> [Int] {
        let valid = Set(values).intersection(reminderDaysBeforeOptions).sorted()
        return valid.isEmpty ? defaultReminderDaysBefore : valid
    }

    private static func reminderDaysBefore(from object: Any?) -> [Int]? {
        if let days = object as? [Int] { return days }
        if let day = object as? Int { return [day] }
        return nil
    }

    func clearCloudMirror() {
        ubiquitous.removeObject(forKey: Self.baseCurrencyKey)
        ubiquitous.removeObject(forKey: Self.locationCodesKey)
        ubiquitous.removeObject(forKey: Self.decimalPlacesKey)
        ubiquitous.removeObject(forKey: Self.remindersEnabledKey)
        ubiquitous.removeObject(forKey: Self.reminderDaysBeforeKey)
        ubiquitous.removeObject(forKey: Self.reminderMinutesKey)
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

        if let enabled = ubiquitous.object(forKey: Self.remindersEnabledKey) as? Bool,
           enabled != remindersEnabled {
            remindersEnabled = enabled
        }

        if let daysBefore = Self.reminderDaysBefore(from: ubiquitous.object(forKey: Self.reminderDaysBeforeKey)),
           Self.normalizedReminderDaysBefore(daysBefore) != reminderDaysBefore {
            reminderDaysBefore = daysBefore
        }

        if let minutes = ubiquitous.object(forKey: Self.reminderMinutesKey) as? Int,
           Self.clampedReminderMinutes(minutes) != reminderMinutes {
            reminderMinutes = minutes
        }
    }
}
