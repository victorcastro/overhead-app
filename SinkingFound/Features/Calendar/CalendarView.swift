import SwiftUI
import SwiftData

struct CalendarView: View {
    let resetToken: Int

    @Environment(\.moneyFormat) private var money
    @Environment(AppSettings.self) private var settings
    @Query(sort: \FixedExpense.anchorDueDate) private var expenses: [FixedExpense]

    @State private var selectedMonth: AnnualMonthSummary?
    @State private var displayedYear = MonthWindow.yearStart(for: .now)

    private let currentYear = MonthWindow.yearStart(for: .now)
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    private var base: Currency { settings.baseCurrency }

    private var availableYears: [Date] {
        YearWindow.years(for: expenses, calendar: calendar)
    }

    private var yearTitle: String {
        displayedYear.formatted(.dateTime.year())
    }

    private var isOnCurrentYear: Bool {
        calendar.isDate(displayedYear, equalTo: .now, toGranularity: .year)
    }

    private func summary(for year: Date) -> YearSummary {
        let months: [AnnualMonthSummary] = (0..<12).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: offset, to: year) else { return nil }
            let total = MonthPlan(expenses: expenses, month: date, base: base).dueThisMonth
            return AnnualMonthSummary(date: date, total: total)
        }
        return YearSummary(months: months)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $displayedYear) {
                ForEach(availableYears, id: \.self) { year in
                    yearPage(year)
                        .tag(year)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Theme.background)
            .navigationTitle(yearTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isOnCurrentYear {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("This year") {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                displayedYear = currentYear
                            }
                        }
                        .accessibilityLabel("Go back to this year")
                    }
                }
            }
            .sheet(item: $selectedMonth) { month in
                MonthDetailSheet(
                    month: month.date,
                    expenses: expenses,
                    base: base,
                    showsLocation: settings.hasLocations
                )
            }
            .onChange(of: availableYears) { _, years in
                guard !years.contains(displayedYear) else { return }
                displayedYear = years.contains(currentYear) ? currentYear : (years.first ?? currentYear)
            }
            .onChange(of: resetToken) { _, _ in
                guard !isOnCurrentYear else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    displayedYear = currentYear
                }
            }
        }
    }

    private func yearPage(_ year: Date) -> some View {
        ScrollView {
            let summary = summary(for: year)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total fixed cost this year")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                    Text(money(summary.total, base))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(summary.months) { month in
                        Button {
                            selectedMonth = month
                        } label: {
                            monthCard(month, summary: summary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                calendarLegend
            }
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.vertical, 12)
        }
        .background(Theme.background)
        .scrollIndicators(.hidden)
    }

    private func monthCard(_ month: AnnualMonthSummary, summary: YearSummary) -> some View {
        let isCurrent = calendar.isDate(month.date, equalTo: .now, toGranularity: .month)
        let color = summary.statusColor(for: month.total)

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

            Text(money(month.total, base))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.control.opacity(0.45))
                    Capsule()
                        .fill(color)
                        .frame(width: summary.barWidth(total: month.total, available: proxy.size.width))
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
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(monthAccessibilityLabel(month, isCurrent: isCurrent))
        .accessibilityHint("Shows this month's expenses")
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

    private func monthAccessibilityLabel(_ month: AnnualMonthSummary, isCurrent: Bool) -> String {
        let date = month.date.formatted(.dateTime.month(.wide).year())
        let current = isCurrent ? ", current month" : ""
        return "\(date), \(money(month.total, base)) in fixed expenses\(current)"
    }
}

private struct AnnualMonthSummary: Identifiable {
    let date: Date
    let total: Decimal

    var id: Date { date }
}

private struct YearSummary {
    let months: [AnnualMonthSummary]
    let total: Decimal
    let average: Double
    let largest: Double

    init(months: [AnnualMonthSummary]) {
        self.months = months
        let total = months.reduce(Decimal(0)) { $0 + $1.total }
        self.total = total
        self.average = months.isEmpty ? 0 : (total as NSDecimalNumber).doubleValue / Double(months.count)
        self.largest = months.map { ($0.total as NSDecimalNumber).doubleValue }.max() ?? 0
    }

    func statusColor(for total: Decimal) -> Color {
        let value = (total as NSDecimalNumber).doubleValue
        guard average > 0 else { return Theme.mutedText }
        if value > average * 1.5 { return Theme.destructive }
        if value > average * 1.1 { return .orange }
        return Theme.positive
    }

    func barWidth(total: Decimal, available: CGFloat) -> CGFloat {
        guard largest > 0 else { return 0 }
        let ratio = (total as NSDecimalNumber).doubleValue / largest
        return available * max(0, min(ratio, 1))
    }
}
