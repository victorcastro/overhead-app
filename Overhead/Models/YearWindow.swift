import Foundation

enum YearWindow {
    static let yearsForwardCap = 5
    private static let maximumYears = 200

    static func years(for expenses: [FixedExpense], calendar: Calendar = .current) -> [Date] {
        let currentYear = MonthWindow.yearStart(for: .now, calendar: calendar)
        let horizon = calendar.date(byAdding: .year, value: yearsForwardCap, to: currentYear) ?? currentYear

        let first = expenses
            .map { MonthWindow.yearStart(for: $0.anchorDueDate, calendar: calendar) }
            .min()
            .map { min($0, currentYear) } ?? currentYear

        let last = expenses
            .compactMap { lastOccurrenceYear(of: $0, horizon: horizon, calendar: calendar) }
            .max()
            .map { min(max($0, currentYear), horizon) } ?? currentYear

        return range(from: first, to: last, calendar: calendar)
    }

    private static func lastOccurrenceYear(
        of expense: FixedExpense,
        horizon: Date,
        calendar: Calendar
    ) -> Date? {
        guard expense.frequency != .oneTime else {
            return MonthWindow.yearStart(for: expense.anchorDueDate, calendar: calendar)
        }

        switch expense.endRule {
        case .never:
            return horizon
        case .afterOccurrences:
            guard let last = expense.finalDueDate(calendar: calendar) else { return nil }
            return MonthWindow.yearStart(for: last, calendar: calendar)
        case .onDate:
            guard let endDate = expense.endDate else { return horizon }
            return MonthWindow.yearStart(for: endDate, calendar: calendar)
        }
    }

    private static func range(from first: Date, to last: Date, calendar: Calendar) -> [Date] {
        var years: [Date] = []
        var cursor = first
        while cursor <= last, years.count < maximumYears {
            years.append(cursor)
            guard let next = calendar.date(byAdding: .year, value: 1, to: cursor) else { break }
            cursor = next
        }
        return years.isEmpty ? [MonthWindow.yearStart(for: .now, calendar: calendar)] : years
    }
}
