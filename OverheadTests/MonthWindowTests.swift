import Foundation
import Testing
@testable import Overhead

struct MonthWindowTests {
    private let calendar = Calendar.current

    @Test func spansThreeYearsOfMonths() {
        let months = MonthWindow.months()

        #expect(months.count == 36)
        #expect(months.first == MonthWindow.firstYear())
        #expect(calendar.component(.month, from: months.first ?? .now) == 1)
        #expect(calendar.component(.month, from: months.last ?? .now) == 12)
    }

    @Test func containsTheCurrentMonthExactly() {
        let months = MonthWindow.months()

        #expect(months.contains(MonthWindow.currentMonth()))
    }

    @Test func everyMonthIsAMonthStart() {
        for month in MonthWindow.months() {
            #expect(month == MonthWindow.monthStart(for: month))
        }
    }

    @Test func boundsSitOneYearAroundToday() {
        let currentYear = MonthWindow.yearStart(for: .now)

        #expect(calendar.date(byAdding: .year, value: -1, to: currentYear) == MonthWindow.firstYear())
        #expect(calendar.date(byAdding: .year, value: 1, to: currentYear) == MonthWindow.lastYear())
    }

    @Test func clampingKeepsYearsInsideTheWindow() {
        let farPast = calendar.date(from: DateComponents(year: 1998, month: 4, day: 3)) ?? .now
        let farFuture = calendar.date(from: DateComponents(year: 2099, month: 4, day: 3)) ?? .now

        #expect(MonthWindow.clampedYear(for: farPast) == MonthWindow.firstYear())
        #expect(MonthWindow.clampedYear(for: farFuture) == MonthWindow.lastYear())
        #expect(MonthWindow.clampedYear(for: .now) == MonthWindow.yearStart(for: .now))
    }
}
