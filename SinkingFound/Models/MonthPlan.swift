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

struct AnnualShareItem: Identifiable {
    let expense: FixedExpense
    let dueDate: Date
    let base: Currency

    var id: PersistentIdentifier { expense.persistentModelID }
    var monthlyShareInBase: Decimal { expense.amount(in: base) / 12 }
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
    let annualAhead: [AnnualShareItem]

    init(expenses: [FixedExpense], month: Date, base: Currency, calendar: Calendar = .current) {
        let monthStart = calendar.dateInterval(of: .month, for: month)?.start ?? month
        self.month = monthStart
        self.base = base

        var occurrences: [ExpenseOccurrence] = []
        var annualAhead: [AnnualShareItem] = []

        for expense in expenses {
            if let dueDate = expense.dueDate(in: month, calendar: calendar) {
                occurrences.append(
                    ExpenseOccurrence(
                        expense: expense,
                        dueDate: dueDate,
                        isPaid: expense.isPaid(in: month),
                        isFinal: expense.isFinalOccurrence(in: month, calendar: calendar),
                        base: base
                    )
                )
            } else if expense.frequency == .annual,
                      let next = Self.nextAnnualDueDate(for: expense, after: monthStart, calendar: calendar) {
                annualAhead.append(AnnualShareItem(expense: expense, dueDate: next, base: base))
            }
        }

        self.occurrences = occurrences.sorted { $0.dueDate < $1.dueDate }
        self.annualAhead = annualAhead.sorted { $0.dueDate < $1.dueDate }
    }

    private static func nextAnnualDueDate(
        for expense: FixedExpense,
        after monthStart: Date,
        calendar: Calendar
    ) -> Date? {
        let anchor = calendar.dateComponents([.month, .day], from: expense.anchorDueDate)
        let year = calendar.component(.year, from: monthStart)
        for candidateYear in [year, year + 1] {
            let components = DateComponents(year: candidateYear, month: anchor.month, day: anchor.day)
            if let date = calendar.date(from: components),
               date >= monthStart {
                return expense.allowsOccurrence(on: date, calendar: calendar) ? date : nil
            }
        }
        return expense.allowsOccurrence(on: expense.anchorDueDate, calendar: calendar) ? expense.anchorDueDate : nil
    }

    var annualShare: Decimal { annualAhead.reduce(0) { $0 + $1.monthlyShareInBase } }

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

    var total: Decimal { dueThisMonth + annualShare }
    var stillToSetAside: Decimal { unpaidThisMonth + annualShare }

    var progress: Double {
        guard total > 0 else { return 0 }
        let ratio = (paidTotal / total) as NSDecimalNumber
        return min(max(ratio.doubleValue, 0), 1)
    }
}
