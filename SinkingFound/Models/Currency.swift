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

    var unitsPerEUR: Decimal {
        switch self {
        case .eur: 1
        case .pen: Decimal(407) / 100
        case .usd: Decimal(108) / 100
        case .gbp: Decimal(84) / 100
        }
    }

    func amount(_ value: Decimal, to target: Currency) -> Decimal {
        guard self != target else { return value }
        let valueInEUR = value / unitsPerEUR
        return valueInEUR * target.unitsPerEUR
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

    static func string(_ value: Decimal, currency: Currency, decimals: Int = 0) -> String {
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        let digits = formatter.string(from: value as NSDecimalNumber) ?? "0"
        return currency.symbol + digits
    }
}
