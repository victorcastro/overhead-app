import Foundation
import Testing
@testable import SinkingFound

struct MonthPlanTests {
    private let calendar = Calendar.current

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }

    private func makeExpense(
        name: String = "Rent",
        amount: Decimal = 100,
        frequency: ExpenseFrequency = .monthly,
        anchor: Date,
        paidPeriods: [String] = []
    ) -> FixedExpense {
        FixedExpense(
            name: name,
            amount: amount,
            currency: .usd,
            frequency: frequency,
            anchorDueDate: anchor,
            paidPeriods: paidPeriods
        )
    }

    @Test func monthlyExpenseAppearsInAMonthAfterTheAnchor() {
        let expense = makeExpense(anchor: date(2026, 1, 10))
        let plan = MonthPlan(expenses: [expense], month: date(2026, 5, 20), base: .usd)

        #expect(plan.occurrences.count == 1)
        #expect(plan.occurrences.first?.dueDate == date(2026, 5, 10))
        #expect(plan.dueThisMonth == 100)
        #expect(plan.month == calendar.dateInterval(of: .month, for: date(2026, 5, 20))?.start)
    }

    @Test func monthlyExpenseIsAbsentBeforeTheAnchorMonth() {
        let expense = makeExpense(anchor: date(2026, 1, 10))
        let plan = MonthPlan(expenses: [expense], month: date(2025, 12, 1), base: .usd)

        #expect(plan.occurrences.isEmpty)
        #expect(plan.dueThisMonth == 0)
    }

    @Test func paidStateIsScopedToItsOwnMonth() {
        let expense = makeExpense(anchor: date(2026, 1, 10), paidPeriods: ["2026-05"])

        let may = MonthPlan(expenses: [expense], month: date(2026, 5, 1), base: .usd)
        #expect(may.paid.count == 1)
        #expect(may.unpaid.isEmpty)
        #expect(may.paidTotal == 100)

        let june = MonthPlan(expenses: [expense], month: date(2026, 6, 1), base: .usd)
        #expect(june.paid.isEmpty)
        #expect(june.unpaid.count == 1)
        #expect(june.unpaidThisMonth == 100)
    }

    @Test func annualExpenseIsDueOnlyInItsAnchorMonth() {
        let expense = makeExpense(amount: 1200, frequency: .annual, anchor: date(2026, 9, 15))

        let may = MonthPlan(expenses: [expense], month: date(2026, 5, 1), base: .usd)
        #expect(may.occurrences.isEmpty)
        #expect(may.total == 0)

        let september = MonthPlan(expenses: [expense], month: date(2026, 9, 1), base: .usd)
        #expect(september.occurrences.count == 1)
        #expect(september.occurrences.first?.dueDate == date(2026, 9, 15))
        #expect(september.dueThisMonth == 1200)

        let nextSeptember = MonthPlan(expenses: [expense], month: date(2027, 9, 1), base: .usd)
        #expect(nextSeptember.occurrences.count == 1)
        #expect(nextSeptember.occurrences.first?.dueDate == date(2027, 9, 15))
    }
}
