import Foundation

/// The slice of `NSUbiquitousKeyValueStore` that `AppSettings` needs, so the mirroring can
/// be exercised in tests without an iCloud account.
protocol KeyValueStore: AnyObject {
    func string(forKey key: String) -> String?
    func array(forKey key: String) -> [Any]?
    func set(_ value: Any?, forKey key: String)
    func removeObject(forKey key: String)
    @discardableResult func synchronize() -> Bool
}

extension NSUbiquitousKeyValueStore: KeyValueStore {}
