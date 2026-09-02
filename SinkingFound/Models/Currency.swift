import Foundation

enum Currency: String, Codable, CaseIterable, Identifiable {
    case eur = "EUR"
    case pen = "PEN"
    case usd = "USD"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .eur: "€"
        case .pen: "S/ "
        case .usd: "$"
        }
    }

    var unitsPerEUR: Decimal {
        switch self {
        case .eur: 1
        case .pen: Decimal(407) / 100
        case .usd: Decimal(108) / 100
        }
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

    static func string(_ value: Decimal, currency: Currency = .eur, decimals: Int = 0) -> String {
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        let digits = formatter.string(from: value as NSDecimalNumber) ?? "0"
        return currency.symbol + digits
    }
}
