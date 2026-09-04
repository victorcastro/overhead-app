import Foundation

enum ExpenseIdentity {
    private static let separator = "\u{1F}"

    private struct Fields {
        let name: String
        let amount: Decimal
        let currency: Currency
        let frequency: ExpenseFrequency
        let intervalMonths: Int
        let location: String
        let anchorDueDate: Date
    }

    static func key(for expense: FixedExpense, calendar: Calendar = .current) -> String {
        key(
            Fields(
                name: expense.name,
                amount: expense.amount,
                currency: expense.currency,
                frequency: expense.frequency,
                intervalMonths: expense.intervalMonths,
                location: expense.location,
                anchorDueDate: expense.anchorDueDate
            ),
            calendar: calendar
        )
    }

    static func key(for expense: ExpenseBackup.Expense, calendar: Calendar = .current) -> String {
        key(
            Fields(
                name: expense.name,
                amount: expense.decimalAmount ?? 0,
                currency: expense.currency,
                frequency: expense.frequency,
                intervalMonths: expense.intervalMonths,
                location: expense.location,
                anchorDueDate: expense.anchorDueDate
            ),
            calendar: calendar
        )
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    private static func key(_ fields: Fields, calendar: Calendar) -> String {
        let normalizedName = fields.name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let effectiveInterval = fields.frequency == .other ? max(fields.intervalMonths, 1) : 1

        return [
            normalizedName,
            fields.amount.description,
            fields.currency.rawValue,
            fields.frequency.rawValue,
            String(effectiveInterval),
            fields.location,
            dayKey(for: fields.anchorDueDate, calendar: calendar)
        ].joined(separator: separator)
    }
}
