import Foundation
import SwiftData

struct ExpenseOccurrence: Identifiable {
    let expense: FixedExpense
    let dueDate: Date
    let isPaid: Bool
    let isFinal: Bool
    let base: Currency

    var id: PersistentIdentifier { expense.persistentModelID }
    var amountInBase: Decimal { expense.amount(in: base) }
}

struct CategoryGroup: Identifiable {
    let category: ExpenseCategory
    let occurrences: [ExpenseOccurrence]

    var id: String { category.rawValue }
    var total: Decimal { occurrences.reduce(0) { $0 + $1.amountInBase } }
}

struct MonthPlan {
    let month: Date
    let base: Currency
    let occurrences: [ExpenseOccurrence]

    init(expenses: [FixedExpense], month: Date, base: Currency, calendar: Calendar = .current) {
        let monthStart = calendar.dateInterval(of: .month, for: month)?.start ?? month
        self.month = monthStart
        self.base = base

        var occurrences: [ExpenseOccurrence] = []

        for expense in expenses {
            guard let dueDate = expense.dueDate(in: month, calendar: calendar) else { continue }
            occurrences.append(
                ExpenseOccurrence(
                    expense: expense,
                    dueDate: dueDate,
                    isPaid: expense.isPaid(in: month),
                    isFinal: expense.isFinalOccurrence(in: month, calendar: calendar),
                    base: base
                )
            )
        }

        self.occurrences = occurrences.sorted { $0.dueDate < $1.dueDate }
    }

    var paid: [ExpenseOccurrence] { occurrences.filter(\.isPaid) }
    var unpaid: [ExpenseOccurrence] { occurrences.filter { !$0.isPaid } }

    var unpaidByCategory: [CategoryGroup] {
        ExpenseCategory.allCases.compactMap { category in
            let matches = unpaid.filter { $0.expense.category == category }
            guard !matches.isEmpty else { return nil }
            return CategoryGroup(category: category, occurrences: matches)
        }
    }

    var dueThisMonth: Decimal { occurrences.reduce(0) { $0 + $1.amountInBase } }
    var paidTotal: Decimal { paid.reduce(0) { $0 + $1.amountInBase } }
    var unpaidThisMonth: Decimal { unpaid.reduce(0) { $0 + $1.amountInBase } }

    var total: Decimal { dueThisMonth }
    var leftToPayThisMonth: Decimal { unpaidThisMonth }

    var progress: Double {
        guard total > 0 else { return 0 }
        let ratio = (paidTotal / total) as NSDecimalNumber
        return min(max(ratio.doubleValue, 0), 1)
    }
}
