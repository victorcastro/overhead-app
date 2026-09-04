import Foundation
import Testing
@testable import Overhead

struct ExpenseEndRuleTests {
    private let calendar = Calendar.current

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }

    private func makeExpense(
        amount: Decimal = 100,
        frequency: ExpenseFrequency = .monthly,
        intervalMonths: Int = 1,
        anchor: Date,
        endRule: ExpenseEndRule = .never,
        endOccurrences: Int = 12,
        endDate: Date? = nil
    ) -> FixedExpense {
        FixedExpense(
            name: "Car loan",
            amount: amount,
            currency: .usd,
            frequency: frequency,
            anchorDueDate: anchor,
            intervalMonths: intervalMonths,
            endRule: endRule,
            endOccurrences: endOccurrences,
            endDate: endDate
        )
    }

    @Test func neverKeepsRecurringIndefinitely() {
        let expense = makeExpense(anchor: date(2026, 1, 10))

        #expect(expense.dueDate(in: date(2026, 1, 1)) == date(2026, 1, 10))
        #expect(expense.dueDate(in: date(2030, 7, 1)) == date(2030, 7, 10))
        #expect(expense.isFinalOccurrence(in: date(2030, 7, 1)) == false)
    }

    @Test func afterOccurrencesCountsTheFirstPayment() {
        let expense = makeExpense(anchor: date(2026, 1, 10), endRule: .afterOccurrences, endOccurrences: 6)

        #expect(expense.dueDate(in: date(2026, 1, 1)) == date(2026, 1, 10))
        #expect(expense.dueDate(in: date(2026, 6, 1)) == date(2026, 6, 10))
        #expect(expense.dueDate(in: date(2026, 7, 1)) == nil)
        #expect(expense.finalDueDate() == date(2026, 6, 10))
    }

    @Test func afterOccurrencesMarksTheLastPayment() {
        let expense = makeExpense(anchor: date(2026, 1, 10), endRule: .afterOccurrences, endOccurrences: 6)

        #expect(expense.isFinalOccurrence(in: date(2026, 5, 1)) == false)
        #expect(expense.isFinalOccurrence(in: date(2026, 6, 1)))
        #expect(expense.isFinalOccurrence(in: date(2026, 7, 1)) == false)
    }

    @Test func afterOccurrencesFollowsTheCustomInterval() {
        let expense = makeExpense(
            frequency: .other,
            intervalMonths: 3,
            anchor: date(2026, 1, 10),
            endRule: .afterOccurrences,
            endOccurrences: 3
        )

        #expect(expense.dueDate(in: date(2026, 1, 1)) == date(2026, 1, 10))
        #expect(expense.dueDate(in: date(2026, 4, 1)) == date(2026, 4, 10))
        #expect(expense.dueDate(in: date(2026, 7, 1)) == date(2026, 7, 10))
        #expect(expense.dueDate(in: date(2026, 10, 1)) == nil)
        #expect(expense.isFinalOccurrence(in: date(2026, 7, 1)))
    }

    @Test func onDateStopsAfterTheChosenDay() {
        let expense = makeExpense(anchor: date(2026, 1, 10), endRule: .onDate, endDate: date(2026, 4, 10))

        #expect(expense.dueDate(in: date(2026, 4, 1)) == date(2026, 4, 10))
        #expect(expense.dueDate(in: date(2026, 5, 1)) == nil)
        #expect(expense.isFinalOccurrence(in: date(2026, 4, 1)))
    }

    @Test func onDateExcludesADueDayThatFallsAfterTheLimit() {
        let expense = makeExpense(anchor: date(2026, 1, 20), endRule: .onDate, endDate: date(2026, 4, 10))

        #expect(expense.dueDate(in: date(2026, 3, 1)) == date(2026, 3, 20))
        #expect(expense.dueDate(in: date(2026, 4, 1)) == nil)
        #expect(expense.isFinalOccurrence(in: date(2026, 3, 1)))
    }

    @Test func oneTimeIgnoresTheEndRule() {
        let expense = makeExpense(
            frequency: .oneTime,
            anchor: date(2026, 1, 10),
            endRule: .afterOccurrences,
            endOccurrences: 1
        )

        #expect(expense.dueDate(in: date(2026, 1, 1)) == date(2026, 1, 10))
        #expect(expense.isFinalOccurrence(in: date(2026, 1, 1)) == false)
        #expect(expense.finalDueDate() == nil)
    }

    @Test func endedAnnualExpenseIsDueOnceThenStops() {
        let expense = makeExpense(
            amount: 1200,
            frequency: .annual,
            anchor: date(2026, 9, 15),
            endRule: .afterOccurrences,
            endOccurrences: 1
        )

        let beforeTheOnlyDueDate = MonthPlan(expenses: [expense], month: date(2026, 5, 1), base: .usd)
        #expect(beforeTheOnlyDueDate.occurrences.isEmpty)
        #expect(beforeTheOnlyDueDate.total == 0)

        let theOnlyDueDate = MonthPlan(expenses: [expense], month: date(2026, 9, 1), base: .usd)
        #expect(theOnlyDueDate.occurrences.count == 1)
        #expect(theOnlyDueDate.dueThisMonth == 1200)

        let afterTheOnlyDueDate = MonthPlan(expenses: [expense], month: date(2027, 9, 1), base: .usd)
        #expect(afterTheOnlyDueDate.occurrences.isEmpty)
        #expect(afterTheOnlyDueDate.total == 0)
    }

    @Test func planFlagsTheLastOccurrence() {
        let expense = makeExpense(anchor: date(2026, 1, 10), endRule: .afterOccurrences, endOccurrences: 3)

        let february = MonthPlan(expenses: [expense], month: date(2026, 2, 1), base: .usd)
        #expect(february.occurrences.first?.isFinal == false)

        let march = MonthPlan(expenses: [expense], month: date(2026, 3, 1), base: .usd)
        #expect(march.occurrences.first?.isFinal == true)

        let april = MonthPlan(expenses: [expense], month: date(2026, 4, 1), base: .usd)
        #expect(april.occurrences.isEmpty)
        #expect(april.dueThisMonth == 0)
    }
}
