import Foundation
import SwiftData

@Model
final class FixedExpense {
    var name: String = ""
    var amount: Decimal = 0
    var currency: Currency = Currency.usd
    var frequency: ExpenseFrequency = ExpenseFrequency.monthly
    var category: ExpenseCategory = ExpenseCategory.utilities
    var location: String = ""
    var anchorDueDate: Date = Date.now
    var intervalMonths: Int = 1
    var endRule: ExpenseEndRule = ExpenseEndRule.never
    var endOccurrences: Int = 12
    var endDate: Date?
    var paidPeriods: [String] = []
    var createdAt: Date = Date.now

    init(
        name: String,
        amount: Decimal,
        currency: Currency = .usd,
        frequency: ExpenseFrequency = .monthly,
        category: ExpenseCategory = .utilities,
        location: String = "",
        anchorDueDate: Date,
        intervalMonths: Int = 1,
        endRule: ExpenseEndRule = .never,
        endOccurrences: Int = 12,
        endDate: Date? = nil,
        paidPeriods: [String] = [],
        createdAt: Date = .now
    ) {
        self.name = name
        self.amount = amount
        self.currency = currency
        self.frequency = frequency
        self.category = category
        self.location = location
        self.anchorDueDate = anchorDueDate
        self.intervalMonths = intervalMonths
        self.endRule = endRule
        self.endOccurrences = endOccurrences
        self.endDate = endDate
        self.paidPeriods = paidPeriods
        self.createdAt = createdAt
    }

    func amount(in base: Currency) -> Decimal { currency.amount(amount, to: base) }

    func dueDate(in month: Date, calendar: Calendar = .current) -> Date? {
        guard let monthStart = calendar.dateInterval(of: .month, for: month)?.start,
              let anchorMonthStart = calendar.dateInterval(of: .month, for: anchorDueDate)?.start,
              monthStart >= anchorMonthStart
        else { return nil }

        let anchor = calendar.dateComponents([.year, .month, .day], from: anchorDueDate)
        let target = calendar.dateComponents([.year, .month], from: monthStart)

        switch frequency {
        case .monthly:
            break
        case .annual:
            guard anchor.month == target.month else { return nil }
        case .oneTime:
            guard anchorMonthStart == monthStart else { return nil }
        case .other:
            let elapsed = calendar.dateComponents([.month], from: anchorMonthStart, to: monthStart).month ?? 0
            let interval = max(intervalMonths, 1)
            guard elapsed % interval == 0 else { return nil }
        }

        guard let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count else { return nil }
        let day = min(anchor.day ?? 1, daysInMonth)
        guard let date = calendar.date(from: DateComponents(year: target.year, month: target.month, day: day)),
              allowsOccurrence(on: date, calendar: calendar)
        else { return nil }
        return date
    }

    private var stepMonths: Int {
        switch frequency {
        case .monthly, .oneTime: 1
        case .annual: 12
        case .other: max(intervalMonths, 1)
        }
    }

    func allowsOccurrence(on date: Date, calendar: Calendar = .current) -> Bool {
        guard frequency != .oneTime else { return true }

        switch endRule {
        case .never:
            return true
        case .onDate:
            guard let endDate else { return true }
            return calendar.startOfDay(for: date) <= calendar.startOfDay(for: endDate)
        case .afterOccurrences:
            guard let index = occurrenceIndex(on: date, calendar: calendar) else { return true }
            return index <= max(endOccurrences, 1)
        }
    }

    private func occurrenceIndex(on date: Date, calendar: Calendar = .current) -> Int? {
        guard let monthStart = calendar.dateInterval(of: .month, for: date)?.start,
              let anchorMonthStart = calendar.dateInterval(of: .month, for: anchorDueDate)?.start,
              let elapsed = calendar.dateComponents([.month], from: anchorMonthStart, to: monthStart).month,
              elapsed >= 0
        else { return nil }
        return elapsed / stepMonths + 1
    }

    func isFinalOccurrence(in month: Date, calendar: Calendar = .current) -> Bool {
        guard frequency != .oneTime, endRule != .never,
              dueDate(in: month, calendar: calendar) != nil,
              let monthStart = calendar.dateInterval(of: .month, for: month)?.start,
              let next = calendar.date(byAdding: .month, value: stepMonths, to: monthStart)
        else { return false }
        return dueDate(in: next, calendar: calendar) == nil
    }

    func nextDueDate(onOrAfter date: Date = .now, calendar: Calendar = .current, monthsAhead: Int = 240) -> Date? {
        let start = calendar.startOfDay(for: date)
        guard let anchorMonth = calendar.dateInterval(of: .month, for: anchorDueDate)?.start,
              let startMonth = calendar.dateInterval(of: .month, for: start)?.start
        else { return nil }

        var month = max(anchorMonth, startMonth)

        for _ in 0..<monthsAhead {
            if let due = dueDate(in: month, calendar: calendar), calendar.startOfDay(for: due) >= start {
                return due
            }
            guard let next = calendar.date(byAdding: .month, value: 1, to: month) else { return nil }
            month = next
        }

        return nil
    }

    func finalDueDate(calendar: Calendar = .current) -> Date? {
        guard frequency != .oneTime, endRule == .afterOccurrences,
              let anchorMonthStart = calendar.dateInterval(of: .month, for: anchorDueDate)?.start,
              let month = calendar.date(
                  byAdding: .month,
                  value: (max(endOccurrences, 1) - 1) * stepMonths,
                  to: anchorMonthStart
              )
        else { return nil }
        return dueDate(in: month, calendar: calendar)
    }

    func isPaid(in month: Date) -> Bool {
        paidPeriods.contains(Self.periodKey(for: month))
    }

    func setPaid(_ paid: Bool, in month: Date) {
        let key = Self.periodKey(for: month)
        if paid {
            guard !paidPeriods.contains(key) else { return }
            paidPeriods.append(key)
        } else {
            paidPeriods.removeAll { $0 == key }
        }
    }

    private static func periodKey(for month: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month], from: month)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }
}
