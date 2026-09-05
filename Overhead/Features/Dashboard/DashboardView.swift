import SwiftUI
import SwiftData

enum DashboardSheet: Identifiable {
    case editExpense(FixedExpense)
    case monthPicker

    var id: String {
        switch self {
        case .editExpense(let expense): String(describing: expense.persistentModelID)
        case .monthPicker: "monthPicker"
        }
    }
}

struct DashboardView: View {
    let resetToken: Int

    @Environment(\.moneyFormat) private var money
    @Environment(AppSettings.self) private var settings
    @Query(sort: \FixedExpense.anchorDueDate) private var expenses: [FixedExpense]

    @State private var filter: LocationFilter = .all
    @State private var isPaidExpanded = false
    @State private var activeSheet: DashboardSheet?
    @State private var isAddingExpense = false
    @State private var selectedMonth = MonthWindow.currentMonth()

    private let currentMonth = MonthWindow.currentMonth()
    private let availableMonths = MonthWindow.months()

    private var activeFilter: LocationFilter {
        guard settings.hasMultipleLocations else { return .all }
        if case .code(let code) = filter, !settings.locationCodes.contains(code) { return .all }
        return filter
    }

    private var visibleExpenses: [FixedExpense] {
        expenses.filter(activeFilter.matches)
    }

    private var showsLocation: Bool {
        settings.hasMultipleLocations && activeFilter == .all
    }

    private func plan(for month: Date) -> MonthPlan {
        MonthPlan(expenses: visibleExpenses, month: month, base: settings.baseCurrency)
    }

    private func monthTitle(for month: Date) -> String {
        month.formatted(.dateTime.month(.wide))
    }

    private var monthNameTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide))
    }

    private var yearSubtitle: String {
        selectedMonth.formatted(.dateTime.year())
    }

    private var monthScrollPosition: Binding<Date?> {
        Binding {
            selectedMonth
        } set: { newValue in
            guard let newValue, newValue != selectedMonth else { return }
            selectedMonth = newValue
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(availableMonths, id: \.self) { month in
                        monthPage(month)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: monthScrollPosition)
            .scrollIndicators(.hidden)
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(monthNameTitle)
            .navigationSubtitle(yearSubtitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        activeSheet = .monthPicker
                    } label: {
                        Image(systemName: "calendar")
                    }
                    .tint(Theme.primaryText)
                    .accessibilityLabel("Choose month")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Theme.primaryText)
                    .accessibilityLabel("Add fixed expense")
                }
            }
            .navigationDestination(isPresented: $isAddingExpense) {
                ExpenseFormView(expense: nil, month: selectedMonth, showsCancelButton: false)
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .editExpense(let expense):
                    NavigationStack {
                        ExpenseFormView(expense: expense, month: selectedMonth)
                    }
                case .monthPicker:
                    MonthPickerSheet(selection: $selectedMonth)
                }
            }
            .onChange(of: selectedMonth) {
                isPaidExpanded = false
            }
            .onChange(of: settings.locationCodes) {
                if !settings.hasMultipleLocations {
                    filter = .all
                } else if case .code(let code) = filter, !settings.locationCodes.contains(code) {
                    filter = .all
                }
            }
            .onChange(of: resetToken) { _, _ in
                guard selectedMonth != currentMonth else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedMonth = currentMonth
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
            MonthSummaryCard(plan: plan, monthName: monthTitle(for: month), isCurrentMonth: month == currentMonth)
                .padding(.bottom, 16)

            if settings.hasMultipleLocations {
                LocationFilterPills(codes: settings.locationCodes, selection: $filter)
                    .padding(.bottom, 16)
            }

            ForEach(plan.unpaidByCategory) { group in
                SectionHeader(
                    title: "\(group.category.label) · \(money(group.total, plan.base))",
                    icon: group.category.sfSymbol
                )
                CardList(data: group.occurrences) { occurrence in
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

            if plan.occurrences.isEmpty {
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
