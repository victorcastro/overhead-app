import Foundation

enum Currency: String, Codable, CaseIterable, Identifiable {
    case eur = "EUR"
    case pen = "PEN"
    case usd = "USD"
    case gbp = "GBP"

    var id: String { rawValue }

    var format: CurrencyFormat {
        switch self {
        case .eur:
            CurrencyFormat(
                symbol: "€",
                symbolPosition: .leading,
                symbolSpacing: true,
                decimalSeparator: ",",
                groupingSeparator: ".",
                inputFractionDigits: 2
            )
        case .pen:
            CurrencyFormat(
                symbol: "S/",
                symbolPosition: .leading,
                symbolSpacing: true,
                decimalSeparator: ".",
                groupingSeparator: ",",
                inputFractionDigits: 2
            )
        case .usd:
            CurrencyFormat(
                symbol: "$",
                symbolPosition: .leading,
                symbolSpacing: false,
                decimalSeparator: ".",
                groupingSeparator: ",",
                inputFractionDigits: 2
            )
        case .gbp:
            CurrencyFormat(
                symbol: "£",
                symbolPosition: .leading,
                symbolSpacing: false,
                decimalSeparator: ".",
                groupingSeparator: ",",
                inputFractionDigits: 2
            )
        }
    }

    var symbol: String { format.symbol }

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
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    static func sample(decimals: Int) -> String {
        digits(NSDecimalNumber(value: 1234.5678), format: Currency.usd.format, decimals: decimals)
    }

    static func string(_ value: Decimal, currency: Currency, decimals: Int) -> String {
        let format = currency.format
        return format.display(digits(value as NSDecimalNumber, format: format, decimals: decimals))
    }

    private static func digits(_ value: NSDecimalNumber, format: CurrencyFormat, decimals: Int) -> String {
        formatter.decimalSeparator = String(format.decimalSeparator)
        formatter.groupingSeparator = String(format.groupingSeparator)
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: value) ?? "0"
    }
}
