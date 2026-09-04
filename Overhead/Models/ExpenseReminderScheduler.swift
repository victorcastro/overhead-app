import Foundation
import UserNotifications

@MainActor
final class ExpenseReminderScheduler {
    static let shared = ExpenseReminderScheduler()

    private static let identifierPrefix = "overhead.expense-due."
    private static let maxRequests = 60
    private static let maxPerExpense = 6
    private static let horizonMonths = 24

    private let center = UNUserNotificationCenter.current()

    private struct Occurrence {
        let expense: FixedExpense
        let dueDate: Date
        let trigger: DateComponents
        let fireDate: Date
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func cancelAll() async {
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func refresh(expenses: [FixedExpense], settings: AppSettings) async {
        await cancelAll()

        guard settings.remindersEnabled else { return }
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        let occurrences = occurrences(for: expenses, daysBefore: settings.reminderDaysBefore)
            .sorted { $0.fireDate < $1.fireDate }
            .prefix(Self.maxRequests)

        for occurrence in occurrences {
            let request = UNNotificationRequest(
                identifier: identifier(for: occurrence),
                content: content(for: occurrence, decimals: settings.decimalPlaces),
                trigger: UNCalendarNotificationTrigger(dateMatching: occurrence.trigger, repeats: false)
            )
            try? await center.add(request)
        }
    }

    private func occurrences(
        for expenses: [FixedExpense],
        daysBefore: Int,
        calendar: Calendar = .current
    ) -> [Occurrence] {
        expenses.flatMap { occurrences(for: $0, daysBefore: daysBefore, calendar: calendar) }
    }

    private func occurrences(
        for expense: FixedExpense,
        daysBefore: Int,
        calendar: Calendar
    ) -> [Occurrence] {
        var found: [Occurrence] = []
        var cursor = calendar.startOfDay(for: .now)

        while found.count < Self.maxPerExpense {
            guard let dueDate = expense.nextDueDate(
                onOrAfter: cursor,
                calendar: calendar,
                monthsAhead: Self.horizonMonths
            ) else { break }

            if !expense.isPaid(in: dueDate),
               let occurrence = occurrence(
                   for: expense,
                   dueDate: dueDate,
                   daysBefore: daysBefore,
                   calendar: calendar
               ) {
                found.append(occurrence)
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: dueDate)) else {
                break
            }
            cursor = next
        }

        return found
    }

    private func occurrence(
        for expense: FixedExpense,
        dueDate: Date,
        daysBefore: Int,
        calendar: Calendar
    ) -> Occurrence? {
        guard let day = calendar.date(
            byAdding: .day,
            value: -daysBefore,
            to: calendar.startOfDay(for: dueDate)
        ) else { return nil }

        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = AppSettings.reminderHour
        components.minute = 0

        guard let fireDate = calendar.date(from: components), fireDate > .now else { return nil }

        return Occurrence(expense: expense, dueDate: dueDate, trigger: components, fireDate: fireDate)
    }

    private func identifier(for occurrence: Occurrence) -> String {
        let key = ExpenseIdentity.key(for: occurrence.expense)
        return Self.identifierPrefix
            + String(abs(key.hashValue), radix: 36)
            + "."
            + ExpenseIdentity.dayKey(for: occurrence.dueDate)
    }

    private func content(for occurrence: Occurrence, decimals: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = occurrence.expense.name
        content.body = timing(for: occurrence.dueDate)
            + " · "
            + Money.string(occurrence.expense.amount, currency: occurrence.expense.currency, decimals: decimals)
        content.sound = .default
        return content
    }

    private func timing(for dueDate: Date, calendar: Calendar = .current) -> String {
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: .now),
            to: calendar.startOfDay(for: dueDate)
        ).day ?? 0

        switch days {
        case ..<1: return "Due today"
        case 1: return "Due tomorrow"
        default: return "Due in \(days) days"
        }
    }
}
