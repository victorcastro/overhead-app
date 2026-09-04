import Foundation

protocol KeyValueStore: AnyObject {
    func string(forKey key: String) -> String?
    func array(forKey key: String) -> [Any]?
    func object(forKey key: String) -> Any?
    func set(_ value: Any?, forKey key: String)
    func removeObject(forKey key: String)
    @discardableResult func synchronize() -> Bool
}

extension NSUbiquitousKeyValueStore: KeyValueStore {}
