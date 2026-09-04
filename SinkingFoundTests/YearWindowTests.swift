import Foundation
import Testing
@testable import SinkingFound

struct YearWindowTests {
    private let calendar = Calendar.current

    private var currentYear: Date {
        MonthWindow.yearStart(for: .now)
    }

    private func year(_ value: Int) -> Date {
        calendar.date(from: DateComponents(year: value, month: 1, day: 1)) ?? .now
    }

    private func offsetYear(_ offset: Int) -> Date {
        calendar.date(byAdding: .year, value: offset, to: currentYear) ?? currentYear
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }

    private func makeExpense(
        frequency: ExpenseFrequency = .monthly,
        anchor: Date,
        endRule: ExpenseEndRule = .never,
        endOccurrences: Int = 12,
        endDate: Date? = nil
    ) -> FixedExpense {
        FixedExpense(
            name: "Rent",
            amount: 100,
            frequency: frequency,
            anchorDueDate: anchor,
            endRule: endRule,
            endOccurrences: endOccurrences,
            endDate: endDate
        )
    }

    @Test func withoutExpensesOnlyThisYearIsReachable() {
        #expect(YearWindow.years(for: []) == [currentYear])
    }

    @Test func neverEndingExpenseReachesTheForwardCap() {
        let expense = makeExpense(anchor: offsetYear(0))
        let years = YearWindow.years(for: [expense])

        #expect(years.first == currentYear)
        #expect(years.last == offsetYear(YearWindow.yearsForwardCap))
        #expect(years.count == YearWindow.yearsForwardCap + 1)
    }

    @Test func endedSeriesStopsAtItsLastYear() {
        let expense = makeExpense(
            anchor: offsetYear(0),
            endRule: .afterOccurrences,
            endOccurrences: 24
        )
        let years = YearWindow.years(for: [expense])

        #expect(years.last == offsetYear(1))
        #expect(years.count == 2)
    }

    @Test func endDateStopsTheWindowAtThatYear() {
        let expense = makeExpense(
            anchor: offsetYear(0),
            endRule: .onDate,
            endDate: calendar.date(byAdding: .year, value: 2, to: offsetYear(0)) ?? .now
        )

        #expect(YearWindow.years(for: [expense]).last == offsetYear(2))
    }

    @Test func reachesBackToTheOldestAnchor() {
        let old = makeExpense(anchor: date(2020, 3, 15), endRule: .onDate, endDate: date(2021, 3, 15))
        let years = YearWindow.years(for: [old])

        #expect(years.first == year(2020))
        #expect(years.contains(currentYear))
        #expect(years.last == currentYear)
    }

    @Test func emptyYearsInBetweenStayTraversable() {
        let old = makeExpense(anchor: date(2020, 3, 15), endRule: .onDate, endDate: date(2020, 12, 15))
        let years = YearWindow.years(for: [old])

        #expect(years.contains(year(2023)))
        #expect(years == stride(
            from: 2020,
            through: calendar.component(.year, from: currentYear),
            by: 1
        ).map(year))
    }

    @Test func aFutureAnchorStillKeepsThisYearReachable() {
        let expense = makeExpense(anchor: offsetYear(2))
        let years = YearWindow.years(for: [expense])

        #expect(years.first == currentYear)
        #expect(years.last == offsetYear(YearWindow.yearsForwardCap))
    }

    @Test func oneTimeExpenseOnlyClaimsItsOwnYear() {
        let expense = makeExpense(frequency: .oneTime, anchor: date(2020, 6, 1))
        let years = YearWindow.years(for: [expense])

        #expect(years.first == year(2020))
        #expect(years.last == currentYear)
    }

    @Test func theWidestExpenseSetsEachBound() {
        let old = makeExpense(anchor: date(2021, 1, 10), endRule: .onDate, endDate: date(2021, 6, 10))
        let ongoing = makeExpense(anchor: offsetYear(0))
        let years = YearWindow.years(for: [old, ongoing])

        #expect(years.first == year(2021))
        #expect(years.last == offsetYear(YearWindow.yearsForwardCap))
    }
}
