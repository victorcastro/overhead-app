import Foundation

enum MonthWindow {
    static let yearsBack = 1
    static let yearsForward = 1

    static func monthStart(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? date
    }

    static func yearStart(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .year, for: date)?.start ?? date
    }

    static func currentMonth(calendar: Calendar = .current) -> Date {
        monthStart(for: .now, calendar: calendar)
    }

    static func firstYear(calendar: Calendar = .current) -> Date {
        let current = yearStart(for: .now, calendar: calendar)
        return calendar.date(byAdding: .year, value: -yearsBack, to: current) ?? current
    }

    static func lastYear(calendar: Calendar = .current) -> Date {
        let current = yearStart(for: .now, calendar: calendar)
        return calendar.date(byAdding: .year, value: yearsForward, to: current) ?? current
    }

    static func clampedYear(for date: Date, calendar: Calendar = .current) -> Date {
        let year = yearStart(for: date, calendar: calendar)
        return min(max(year, firstYear(calendar: calendar)), lastYear(calendar: calendar))
    }

    static func months(calendar: Calendar = .current) -> [Date] {
        let count = (yearsBack + yearsForward + 1) * 12
        let start = firstYear(calendar: calendar)
        return (0..<count).compactMap { calendar.date(byAdding: .month, value: $0, to: start) }
    }
}
