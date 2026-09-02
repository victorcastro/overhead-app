import Foundation
import SwiftData

@Model
final class FixedExpense {
    var name: String
    var amount: Decimal
    var currency: Currency
    var frequency: ExpenseFrequency
    var category: ExpenseCategory
    var location: String = ""
    var anchorDueDate: Date
    var intervalMonths: Int
    var paidPeriods: [String]
    var createdAt: Date

    init(
        name: String,
        amount: Decimal,
        currency: Currency = .usd,
        frequency: ExpenseFrequency = .monthly,
        category: ExpenseCategory = .utilities,
        location: String = "",
        anchorDueDate: Date,
        intervalMonths: Int = 1,
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
        return calendar.date(from: DateComponents(year: target.year, month: target.month, day: day))
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

    static func periodKey(for month: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month], from: month)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }
}
