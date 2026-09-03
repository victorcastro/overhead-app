import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(AppSettings.self) private var settings
    @Query(sort: \FixedExpense.anchorDueDate) private var expenses: [FixedExpense]

    private let displayedYear = Calendar.current.dateInterval(of: .year, for: .now)?.start ?? .now

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    private var base: Currency { settings.baseCurrency }

    private var months: [AnnualMonthSummary] {
        (0..<12).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: offset, to: displayedYear) else {
                return nil
            }
            let total = MonthPlan(expenses: expenses, month: date, base: base).dueThisMonth
            return AnnualMonthSummary(date: date, total: total)
        }
    }

    private var annualTotal: Decimal {
        months.reduce(0) { $0 + $1.total }
    }

    private var average: Double {
        guard !months.isEmpty else { return 0 }
        return (annualTotal as NSDecimalNumber).doubleValue / Double(months.count)
    }

    private var largestMonth: Double {
        months.map { ($0.total as NSDecimalNumber).doubleValue }.max() ?? 0
    }

    private var yearTitle: String {
        displayedYear.formatted(.dateTime.year())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    yearHeader

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total fixed cost this year")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(Money.string(annualTotal, currency: base))
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(Theme.primaryText)
                    }

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(months) { month in
                            monthCard(month)
                        }
                    }

                    calendarLegend
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.vertical, 12)
            }
            .background(Theme.background)
            .scrollIndicators(.hidden)
            .navigationTitle("Annual calendar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var yearHeader: some View {
        Text(yearTitle)
            .font(.title2.bold())
            .foregroundStyle(Theme.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func monthCard(_ month: AnnualMonthSummary) -> some View {
        let isCurrent = calendar.isDate(month.date, equalTo: .now, toGranularity: .month)
        let color = statusColor(for: month.total)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(month.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.caption.weight(.semibold))
                Spacer(minLength: 0)
                if isCurrent {
                    Circle()
                        .fill(Theme.positive)
                        .frame(width: 7, height: 7)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(isCurrent ? Theme.positive : Theme.primaryText)

            Spacer()

            Text(Money.string(month.total, currency: base))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.control.opacity(0.45))
                    Capsule()
                        .fill(color)
                        .frame(width: barWidth(total: month.total, available: proxy.size.width))
                }
            }
            .frame(height: 4)
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(isCurrent ? Theme.positive : Theme.separator, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(monthAccessibilityLabel(month, isCurrent: isCurrent))
    }

    private var calendarLegend: some View {
        HStack(spacing: 14) {
            legendItem(color: Theme.positive, title: "normal")
            legendItem(color: .orange, title: "above average")
            legendItem(color: Theme.destructive, title: "heavy")
        }
        .font(.caption2)
        .foregroundStyle(Theme.secondaryText)
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
        }
    }

    private func statusColor(for total: Decimal) -> Color {
        let value = (total as NSDecimalNumber).doubleValue
        guard average > 0 else { return Theme.mutedText }
        if value > average * 1.5 { return Theme.destructive }
        if value > average * 1.1 { return .orange }
        return Theme.positive
    }

    private func barWidth(total: Decimal, available: CGFloat) -> CGFloat {
        guard largestMonth > 0 else { return 0 }
        let ratio = (total as NSDecimalNumber).doubleValue / largestMonth
        return available * max(0, min(ratio, 1))
    }

    private func monthAccessibilityLabel(_ month: AnnualMonthSummary, isCurrent: Bool) -> String {
        let date = month.date.formatted(.dateTime.month(.wide).year())
        let current = isCurrent ? ", current month" : ""
        return "\(date), \(Money.string(month.total, currency: base)) in fixed expenses\(current)"
    }
}

private struct AnnualMonthSummary: Identifiable {
    let date: Date
    let total: Decimal

    var id: Date { date }
}
