import Foundation

enum AmountInput {
    private static let separators: Set<Character> = [".", ","]

    static func accepted(_ text: String, for currency: Currency, limit: Decimal? = nil) -> String? {
        let format = currency.format
        guard text.allSatisfy({ $0.isASCII && ($0.isNumber || separators.contains($0)) }) else { return nil }

        var integerDigits = text.filter(\.isNumber)
        var fractionDigits: String?

        if let index = text.lastIndex(where: { separators.contains($0) }) {
            let tail = String(text[text.index(after: index)...])
            guard tail.allSatisfy(\.isNumber) else { return nil }

            if text[index] == format.decimalSeparator || tail.isEmpty {
                guard tail.count <= format.inputFractionDigits else { return nil }
                integerDigits = text[..<index].filter(\.isNumber)
                fractionDigits = tail
            }
        }

        let result = display(integer: integerDigits, fraction: fractionDigits, format: format)

        if let limit, let value = parse(result, for: currency), value > limit { return nil }

        return result
    }

    static func parse(_ text: String, for currency: Currency) -> Decimal? {
        let format = currency.format
        let normalized = text
            .replacingOccurrences(of: String(format.groupingSeparator), with: "")
            .replacingOccurrences(of: String(format.decimalSeparator), with: ".")
        guard !normalized.isEmpty else { return nil }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US"))
    }

    static func editable(_ value: Decimal, for currency: Currency) -> String {
        let parts = "\(value)".split(separator: ".", maxSplits: 1)
        let integer = parts.first.map(String.init) ?? "0"
        let fraction = parts.count > 1 ? String(parts[1].prefix(currency.format.inputFractionDigits)) : nil
        return display(integer: integer, fraction: fraction, format: currency.format)
    }

    private static func display(integer: String, fraction: String?, format: CurrencyFormat) -> String {
        let trimmed = trimLeadingZeros(integer)
        let grouped = group(trimmed, separator: format.groupingSeparator)
        guard let fraction else { return grouped }
        return (grouped.isEmpty ? "0" : grouped) + String(format.decimalSeparator) + fraction
    }

    private static func trimLeadingZeros(_ digits: String) -> String {
        let trimmed = digits.drop { $0 == "0" }
        return trimmed.isEmpty ? String(digits.prefix(1)) : String(trimmed)
    }

    private static func group(_ digits: String, separator: Character) -> String {
        var grouped = ""

        for (offset, character) in digits.reversed().enumerated() {
            if offset > 0, offset.isMultiple(of: 3) { grouped.append(separator) }
            grouped.append(character)
        }

        return String(grouped.reversed())
    }
}
