import SwiftUI

struct ExpenseRow: View {
    @Environment(\.moneyFormat) private var money

    let occurrence: ExpenseOccurrence
    let showsLocation: Bool
    var onTogglePaid: (() -> Void)?

    private var expense: FixedExpense { occurrence.expense }

    private var subtitle: String {
        var parts: [String] = [Self.cadenceLabel(for: expense)]
        var status = occurrence.isPaid ? "Paid" : Self.dueDescription(occurrence.dueDate)
        if occurrence.isFinal {
            status += " (last payment)"
        }
        parts.append(status)
        if showsLocation, let name = Location.name(for: expense.location) {
            parts.append(name)
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            if let onTogglePaid {
                Button(action: onTogglePaid) {
                    PaidCircle(isPaid: occurrence.isPaid)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    occurrence.isPaid ? "Mark \(expense.name) as unpaid" : "Mark \(expense.name) as paid"
                )
            } else {
                PaidCircle(isPaid: occurrence.isPaid)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.system(size: 15))
                    .foregroundStyle(occurrence.isPaid ? Theme.secondaryText : Theme.primaryText)
                    .strikethrough(occurrence.isPaid, color: Theme.secondaryText)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text(money(expense.amount, expense.currency))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(occurrence.isPaid ? Theme.mutedText : Theme.primaryText)
                if expense.currency != occurrence.base {
                    Text("≈ \(money(occurrence.amountInBase, occurrence.base))")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private static func cadenceLabel(for expense: FixedExpense) -> String {
        switch expense.frequency {
        case .monthly: expense.frequency.label
        case .annual: expense.frequency.label
        case .oneTime: expense.frequency.label
        case .other:
            expense.intervalMonths > 1
                ? "Every \(expense.intervalMonths) months"
                : ExpenseFrequency.monthly.label
        }
    }

    static func dueDescription(_ dueDate: Date, calendar: Calendar = .current, now: Date = .now) -> String {
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: dueDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        switch days {
        case 0: return "today"
        case 1: return "tomorrow"
        case let value where value < 0: return "\(-value) \(-value == 1 ? "day" : "days") overdue"
        default: return "in \(days) days"
        }
    }
}
