import Foundation

enum Location {
    static func name(for code: String) -> String? {
        guard !code.isEmpty else { return nil }
        return CountryCatalog.names[code]
    }
}

enum CountryCatalog {
    struct Country: Identifiable, Hashable {
        let code: String
        let name: String
        var id: String { code }
    }

    static let all: [Country] = {
        let denylist: Set<String> = ["EU", "QO", "UN", "ZZ", "XA", "XB", "EZ", "UK"]
        return Locale.Region.isoRegions
            .map(\.identifier)
            .filter { $0.count == 2 && $0.allSatisfy(\.isLetter) && !denylist.contains($0) }
            .compactMap { code -> Country? in
                guard let name = Locale.current.localizedString(forRegionCode: code) else { return nil }
                return Country(code: code, name: name)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }()

    static let names: [String: String] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.code, $0.name) }
    )
}
