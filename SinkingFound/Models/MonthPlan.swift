import Foundation
import SwiftData

struct ExpenseOccurrence: Identifiable {
    let expense: FixedExpense
    let dueDate: Date
    let isPaid: Bool

    var id: PersistentIdentifier { expense.persistentModelID }
    var amountInEUR: Decimal { expense.amountInEUR }
}

struct AnnualShareItem: Identifiable {
    let expense: FixedExpense
    let dueDate: Date

    var id: PersistentIdentifier { expense.persistentModelID }
    var monthlyShareEUR: Decimal { expense.amountInEUR / 12 }
}

struct MonthPlan {
    let month: Date
    let occurrences: [ExpenseOccurrence]
    let annualAhead: [AnnualShareItem]

    init(expenses: [FixedExpense], month: Date, calendar: Calendar = .current) {
        let monthStart = calendar.dateInterval(of: .month, for: month)?.start ?? month
        self.month = monthStart

        var occurrences: [ExpenseOccurrence] = []
        var annualAhead: [AnnualShareItem] = []

        for expense in expenses {
            if let dueDate = expense.dueDate(in: month, calendar: calendar) {
                occurrences.append(
                    ExpenseOccurrence(expense: expense, dueDate: dueDate, isPaid: expense.isPaid(in: month))
                )
            } else if expense.frequency == .annual {
                let next = Self.nextAnnualDueDate(for: expense, after: monthStart, calendar: calendar)
                annualAhead.append(AnnualShareItem(expense: expense, dueDate: next))
            }
        }

        self.occurrences = occurrences.sorted { $0.dueDate < $1.dueDate }
        self.annualAhead = annualAhead.sorted { $0.dueDate < $1.dueDate }
    }

    private static func nextAnnualDueDate(
        for expense: FixedExpense,
        after monthStart: Date,
        calendar: Calendar
    ) -> Date {
        let anchor = calendar.dateComponents([.month, .day], from: expense.anchorDueDate)
        let year = calendar.component(.year, from: monthStart)
        for candidateYear in [year, year + 1] {
            let components = DateComponents(year: candidateYear, month: anchor.month, day: anchor.day)
            if let date = calendar.date(from: components),
               date >= monthStart {
                return date
            }
        }
        return expense.anchorDueDate
    }

    var annualShare: Decimal { annualAhead.reduce(0) { $0 + $1.monthlyShareEUR } }

    var paid: [ExpenseOccurrence] { occurrences.filter(\.isPaid) }
    var unpaid: [ExpenseOccurrence] { occurrences.filter { !$0.isPaid } }

    var dueThisMonth: Decimal { occurrences.reduce(0) { $0 + $1.amountInEUR } }
    var paidTotal: Decimal { paid.reduce(0) { $0 + $1.amountInEUR } }
    var unpaidThisMonth: Decimal { unpaid.reduce(0) { $0 + $1.amountInEUR } }

    var total: Decimal { dueThisMonth + annualShare }
    var stillToSetAside: Decimal { unpaidThisMonth + annualShare }

    var progress: Double {
        guard total > 0 else { return 0 }
        let ratio = (paidTotal / total) as NSDecimalNumber
        return min(max(ratio.doubleValue, 0), 1)
    }
}
