import SwiftUI
struct MonthSummaryCard: View {
    let plan: MonthPlan
    let monthName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Still to set aside")
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText)

            Text(Money.string(plan.stillToSetAside, currency: plan.base))
                .font(.system(size: 44, weight: .bold))
                .kerning(-1)
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            ProgressBar(progress: plan.progress)
                .padding(.top, 14)
                .padding(.bottom, 8)

            HStack {
                Text("\(Money.string(plan.paidTotal, currency: plan.base)) paid")
                Spacer(minLength: 8)
                Text("of \(Money.string(plan.total, currency: plan.base)) total")
            }
            .font(.system(size: 12))
            .foregroundStyle(Theme.secondaryText)

            Text(
                "\(Money.string(plan.unpaidThisMonth, currency: plan.base)) unpaid this month + "
                    + "\(Money.string(plan.annualShare, currency: plan.base)) share of annual"
            )
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .cardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        "Still to set aside in \(monthName): \(Money.string(plan.stillToSetAside, currency: plan.base)). "
            + "\(Money.string(plan.paidTotal, currency: plan.base)) paid "
            + "of \(Money.string(plan.total, currency: plan.base))."
    }
}

struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.control)
                Capsule()
                    .fill(Theme.positive)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 8)
        .animation(.easeInOut(duration: 0.25), value: progress)
    }
}

struct LocationFilterPills: View {
    @Binding var selection: LocationFilter

    var body: some View {
        HStack(spacing: 8) {
            ForEach(LocationFilter.allCases) { filter in
                let isSelected = filter == selection
                Button {
                    selection = filter
                } label: {
                    Text(filter.label)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? Color.black : Theme.secondaryText)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 7)
                        .background(isSelected ? Color.white : Theme.card, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
            Spacer(minLength: 0)
        }
    }
}

struct ExpenseRow: View {
    let occurrence: ExpenseOccurrence
    let showsLocation: Bool
    let onTogglePaid: () -> Void

    private var expense: FixedExpense { occurrence.expense }

    private var subtitle: String {
        var parts: [String] = [Self.leadingLabel(for: expense)]
        let status = occurrence.isPaid
            ? Self.paidDescription(occurrence.dueDate)
            : Self.dueDescription(occurrence.dueDate)
        parts.append(status)
        if showsLocation, expense.location != .spain {
            parts.append(expense.location.label)
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTogglePaid) {
                PaidCircle(isPaid: occurrence.isPaid)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                occurrence.isPaid ? "Mark \(expense.name) as unpaid" : "Mark \(expense.name) as paid"
            )

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
                Text(Money.string(expense.amount, currency: expense.currency))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(occurrence.isPaid ? Theme.mutedText : Theme.primaryText)
                if expense.currency != occurrence.base {
                    Text("≈ \(Money.string(occurrence.amountInBase, currency: occurrence.base))")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private static func leadingLabel(for expense: FixedExpense) -> String {
        switch expense.frequency {
        case .annual, .oneTime: expense.frequency.label
        case .monthly, .other: expense.category.label
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

    static func paidDescription(_ dueDate: Date) -> String {
        "Paid · " + dueDate.formatted(.dateTime.month(.abbreviated).day())
    }
}

struct PaidCircle: View {
    let isPaid: Bool

    var body: some View {
        ZStack {
            if isPaid {
                Circle().fill(Theme.positive)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.black)
            } else {
                Circle().strokeBorder(Theme.circleStroke, lineWidth: 1.5)
            }
        }
        .frame(width: 22, height: 22)
    }
}

struct AnnualShareRow: View {
    let item: AnnualShareItem
    let showsLocation: Bool

    private var expense: FixedExpense { item.expense }

    private var subtitle: String {
        var parts = ["Due \(item.dueDate.formatted(.dateTime.month(.abbreviated).year()))"]
        if showsLocation, expense.location != .spain {
            parts.append(expense.location.label)
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.primaryText)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Money.string(item.monthlyShareInBase, currency: item.base)) / mo")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.primaryText)
                Text("of \(Money.string(expense.amount(in: item.base), currency: item.base))")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct PaidSummaryCard: View {
    let paid: [ExpenseOccurrence]
    let base: Currency
    let showsLocation: Bool
    @Binding var isExpanded: Bool
    let onTogglePaid: (ExpenseOccurrence) -> Void
    let onSelect: (ExpenseOccurrence) -> Void

    private var total: Decimal { paid.reduce(0) { $0 + $1.amountInBase } }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    PaidCircle(isPaid: true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Paid · \(paid.count)")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.headerText)
                        Text(paid.map(\.expense.name).joined(separator: ", "))
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(Money.string(total, currency: base))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.mutedText)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.mutedText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(paid) { occurrence in
                    Rectangle().fill(Theme.separator).frame(height: 1)
                    ExpenseRow(occurrence: occurrence, showsLocation: showsLocation) {
                        onTogglePaid(occurrence)
                    }
                    .onTapGesture { onSelect(occurrence) }
                }
            }
        }
        .cardBackground()
    }
}
