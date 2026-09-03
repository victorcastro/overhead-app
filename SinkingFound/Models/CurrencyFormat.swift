import Foundation

enum CurrencySymbolPosition {
    case leading
    case trailing
}

struct CurrencyFormat {
    let symbol: String
    let symbolPosition: CurrencySymbolPosition
    let symbolSpacing: Bool
    let decimalSeparator: Character
    let groupingSeparator: Character
    let inputFractionDigits: Int

    var spacing: String { symbolSpacing ? " " : "" }

    func display(_ digits: String) -> String {
        switch symbolPosition {
        case .leading: symbol + spacing + digits
        case .trailing: digits + spacing + symbol
        }
    }

    var inputPattern: String {
        let separator = NSRegularExpression.escapedPattern(for: String(decimalSeparator))
        return "^\\d*(?:\(separator)\\d{0,\(inputFractionDigits)})?$"
    }

    func accepts(_ text: String) -> Bool {
        text.range(of: inputPattern, options: .regularExpression) != nil
    }
}
