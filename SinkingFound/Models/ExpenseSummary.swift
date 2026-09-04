import Foundation

enum ExpenseSummary {
    private static let dayFormat = Date.FormatStyle.dateTime.month(.wide).day().year()

    static func frequency(_ expense: FixedExpense) -> String {
        guard let next = expense.nextDueDate() else {
            return "The last payment was on \(expense.anchorDueDate.formatted(dayFormat))."
        }

        let date = next.formatted(dayFormat)

        switch expense.frequency {
        case .oneTime: return "One-time payment on \(date)."
        case .monthly: return "Next payment on \(date), then every month."
        case .annual: return "Next payment on \(date), then every year."
        case .other: return "Next payment on \(date), then every \(expense.intervalMonths) months."
        }
    }

    static func end(_ expense: FixedExpense) -> String? {
        switch expense.endRule {
        case .never:
            return nil
        case .onDate:
            guard let endDate = expense.endDate else { return nil }
            return "Nothing is due after \(endDate.formatted(dayFormat))."
        case .afterOccurrences:
            guard let last = expense.finalDueDate() else { return nil }
            return "Counting the first one, the last payment falls on \(last.formatted(dayFormat))."
        }
    }
}
