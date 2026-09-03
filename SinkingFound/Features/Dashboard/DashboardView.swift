import SwiftUI
import SwiftData

enum DashboardSheet: Identifiable {
    case newExpense
    case editExpense(FixedExpense)
    case monthPicker

    var id: String {
        switch self {
        case .newExpense: "new"
        case .editExpense(let expense): String(describing: expense.persistentModelID)
        case .monthPicker: "monthPicker"
        }
    }
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query(sort: \FixedExpense.anchorDueDate) private var expenses: [FixedExpense]

    @State private var filter: LocationFilter = .all
    @State private var isPaidExpanded = false
    @State private var activeSheet: DashboardSheet?
    @State private var selectedMonth = MonthWindow.currentMonth()

    private let currentMonth = MonthWindow.currentMonth()
    private let availableMonths = MonthWindow.months()

    private var activeFilter: LocationFilter {
        if case .code(let code) = filter, !settings.locationCodes.contains(code) { return .all }
        return filter
    }

    private var visibleExpenses: [FixedExpense] {
        expenses.filter(activeFilter.matches)
    }

    private var showsLocation: Bool {
        settings.hasLocations && activeFilter == .all
    }

    private func plan(for month: Date) -> MonthPlan {
        MonthPlan(expenses: visibleExpenses, month: month, base: settings.baseCurrency)
    }

    private func monthTitle(for month: Date) -> String {
        month.formatted(.dateTime.month(.wide))
    }

    private var monthAndYearTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedMonth) {
                ForEach(availableMonths, id: \.self) { month in
                    monthPage(month)
                        .tag(month)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(monthAndYearTitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        activeSheet = .monthPicker
                    } label: {
                        Image(systemName: "calendar")
                    }
                    .accessibilityLabel("Choose month")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .newExpense
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add fixed expense")
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .newExpense:
                    ExpenseFormView(expense: nil, month: currentMonth)
                case .editExpense(let expense):
                    ExpenseFormView(expense: expense, month: selectedMonth)
                case .monthPicker:
                    MonthPickerSheet(selection: $selectedMonth)
                }
            }
            .onChange(of: selectedMonth) {
                isPaidExpanded = false
            }
            .onChange(of: settings.locationCodes) {
                if case .code(let code) = filter, !settings.locationCodes.contains(code) {
                    filter = .all
                }
            }
        }
    }

    private func monthPage(_ month: Date) -> some View {
        ScrollView {
            monthSections(month)
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.top, 8)
        }
        .background(Theme.background)
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func monthSections(_ month: Date) -> some View {
        let plan = plan(for: month)

        VStack(spacing: 0) {
            MonthSummaryCard(plan: plan, monthName: monthTitle(for: month))
                .padding(.bottom, 16)

            if settings.hasLocations {
                LocationFilterPills(codes: settings.locationCodes, selection: $filter)
                    .padding(.bottom, 16)
            }

            if !plan.unpaid.isEmpty {
                SectionHeader(title: "Unpaid · \(plan.unpaid.count)")
                CardList(data: plan.unpaid) { occurrence in
                    ExpenseRow(occurrence: occurrence, showsLocation: showsLocation) {
                        togglePaid(occurrence, in: month)
                    }
                    .onTapGesture { activeSheet = .editExpense(occurrence.expense) }
                }
                .padding(.bottom, 16)
            }

            if !plan.paid.isEmpty {
                PaidSummaryCard(
                    paid: plan.paid,
                    base: plan.base,
                    showsLocation: showsLocation,
                    isExpanded: $isPaidExpanded,
                    onTogglePaid: { togglePaid($0, in: month) },
                    onSelect: { activeSheet = .editExpense($0.expense) }
                )
            }

            if !plan.annualAhead.isEmpty {
                SectionHeader(title: "Saving ahead · \(plan.annualAhead.count)")
                CardList(data: plan.annualAhead) { item in
                    AnnualShareRow(item: item, showsLocation: showsLocation)
                        .onTapGesture { activeSheet = .editExpense(item.expense) }
                }
                .padding(.bottom, 16)
            }

            if plan.occurrences.isEmpty && plan.annualAhead.isEmpty {
                EmptyMonthView(monthTitle: monthTitle(for: month))
                    .padding(.top, 24)
            }
        }
    }

    private func togglePaid(_ occurrence: ExpenseOccurrence, in month: Date) {
        withAnimation(.easeInOut(duration: 0.2)) {
            occurrence.expense.setPaid(!occurrence.isPaid, in: month)
        }
    }

}

struct EmptyMonthView: View {
    let monthTitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text("Nothing due in \(monthTitle)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
            Text("Add your fixed expenses and they will show up here every cycle.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}
