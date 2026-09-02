import SwiftUI
import SwiftData

enum ExpenseEditorTarget: Identifiable {
    case new
    case edit(FixedExpense)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let expense): String(describing: expense.persistentModelID)
        }
    }
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query(sort: \FixedExpense.anchorDueDate) private var expenses: [FixedExpense]

    @State private var filter: LocationFilter = .all
    @State private var isPaidExpanded = false
    @State private var editorTarget: ExpenseEditorTarget?

    private let currentMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now

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

    private var plan: MonthPlan {
        MonthPlan(expenses: visibleExpenses, month: currentMonth, base: settings.baseCurrency)
    }

    private var monthTitle: String {
        currentMonth.formatted(.dateTime.month(.wide))
    }

    private var monthAndYearTitle: String {
        currentMonth.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                let plan = plan

                VStack(spacing: 0) {
                    MonthSummaryCard(plan: plan, monthName: monthTitle)
                        .padding(.bottom, 16)

                    if settings.hasLocations {
                        LocationFilterPills(codes: settings.locationCodes, selection: $filter)
                            .padding(.bottom, 16)
                    }

                    if !plan.unpaid.isEmpty {
                        SectionHeader(title: "Unpaid · \(plan.unpaid.count)")
                        CardList(data: plan.unpaid) { occurrence in
                            ExpenseRow(occurrence: occurrence, showsLocation: showsLocation) {
                                togglePaid(occurrence)
                            }
                            .onTapGesture { editorTarget = .edit(occurrence.expense) }
                        }
                        .padding(.bottom, 16)
                    }

                    if !plan.paid.isEmpty {
                        PaidSummaryCard(
                            paid: plan.paid,
                            base: plan.base,
                            showsLocation: showsLocation,
                            isExpanded: $isPaidExpanded,
                            onTogglePaid: togglePaid,
                            onSelect: { editorTarget = .edit($0.expense) }
                        )
                    }

                    if !plan.annualAhead.isEmpty {
                        SectionHeader(title: "Saving ahead · \(plan.annualAhead.count)")
                        CardList(data: plan.annualAhead) { item in
                            AnnualShareRow(item: item, showsLocation: showsLocation)
                                .onTapGesture { editorTarget = .edit(item.expense) }
                        }
                        .padding(.bottom, 16)
                    }

                    if plan.occurrences.isEmpty && plan.annualAhead.isEmpty {
                        EmptyMonthView(monthTitle: monthTitle)
                            .padding(.top, 24)
                    }
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.top, 8)
            }
            .background(Theme.background)
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(monthAndYearTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorTarget = .new
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add fixed expense")
                }
            }
            .sheet(item: $editorTarget) { target in
                switch target {
                case .new:
                    ExpenseFormView(expense: nil, month: currentMonth)
                case .edit(let expense):
                    ExpenseFormView(expense: expense, month: currentMonth)
                }
            }
            .onChange(of: settings.locationCodes) {
                if case .code(let code) = filter, !settings.locationCodes.contains(code) {
                    filter = .all
                }
            }
        }
    }

    private func togglePaid(_ occurrence: ExpenseOccurrence) {
        withAnimation(.easeInOut(duration: 0.2)) {
            occurrence.expense.setPaid(!occurrence.isPaid, in: currentMonth)
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
