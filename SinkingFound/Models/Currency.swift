import Foundation

enum Currency: String, Codable, CaseIterable, Identifiable {
    case eur = "EUR"
    case pen = "PEN"
    case usd = "USD"
    case gbp = "GBP"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .eur: "€"
        case .pen: "S/ "
        case .usd: "$"
        case .gbp: "£"
        }
    }

    var displayName: String {
        switch self {
        case .eur: "Euro"
        case .pen: "Peruvian Sol"
        case .usd: "US Dollar"
        case .gbp: "British Pound"
        }
    }

    private var unitsPerUSD: Decimal {
        switch self {
        case .usd: 1
        case .eur: Decimal(93) / 100
        case .pen: Decimal(377) / 100
        case .gbp: Decimal(78) / 100
        }
    }

    func amount(_ value: Decimal, to target: Currency) -> Decimal {
        guard self != target else { return value }
        let valueInUSD = value / unitsPerUSD
        return valueInUSD * target.unitsPerUSD
    }
}

enum Money {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    static func sample(decimals: Int) -> String {
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSDecimalNumber(value: 1234.5678)) ?? "0"
    }

    static func string(_ value: Decimal, currency: Currency, decimals: Int) -> String {
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        let digits = formatter.string(from: value as NSDecimalNumber) ?? "0"
        return currency.symbol + digits
    }
}
