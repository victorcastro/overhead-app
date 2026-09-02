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
    @Query(sort: \FixedExpense.anchorDueDate) private var expenses: [FixedExpense]

    @State private var filter: LocationFilter = .all
    @State private var isPaidExpanded = false
    @State private var editorTarget: ExpenseEditorTarget?
    @State private var selectedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var isAnnualCalendarPresented = false

    private var visibleExpenses: [FixedExpense] {
        expenses.filter(filter.matches)
    }

    private var plan: MonthPlan {
        MonthPlan(expenses: visibleExpenses, month: selectedMonth)
    }

    private var monthTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide))
    }

    private var monthAndYearTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                let plan = plan

                VStack(spacing: 0) {
                    MonthSummaryCard(plan: plan, monthName: monthTitle)
                        .padding(.bottom, 16)

                    LocationFilterPills(selection: $filter)
                        .padding(.bottom, 16)

                    if !plan.unpaid.isEmpty {
                        SectionHeader(title: "Unpaid · \(plan.unpaid.count)")
                        CardList(data: plan.unpaid) { occurrence in
                            ExpenseRow(occurrence: occurrence, showsLocation: filter == .all) {
                                togglePaid(occurrence)
                            }
                            .onTapGesture { editorTarget = .edit(occurrence.expense) }
                        }
                        .padding(.bottom, 16)
                    }

                    if !plan.paid.isEmpty {
                        PaidSummaryCard(
                            paid: plan.paid,
                            showsLocation: filter == .all,
                            isExpanded: $isPaidExpanded,
                            onTogglePaid: togglePaid,
                            onSelect: { editorTarget = .edit($0.expense) }
                        )
                    }

                    if !plan.annualAhead.isEmpty {
                        SectionHeader(title: "Saving ahead · \(plan.annualAhead.count)")
                        CardList(data: plan.annualAhead) { item in
                            AnnualShareRow(item: item, showsLocation: filter == .all)
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
                    HStack(spacing: 16) {
                        Button {
                            isAnnualCalendarPresented = true
                        } label: {
                            Image(systemName: "calendar")
                        }
                        .accessibilityLabel("Show annual calendar")

                        Button {
                            editorTarget = .new
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add fixed expense")
                    }
                }
            }
            .sheet(item: $editorTarget) { target in
                switch target {
                case .new:
                    ExpenseFormView(expense: nil, month: selectedMonth)
                case .edit(let expense):
                    ExpenseFormView(expense: expense, month: selectedMonth)
                }
            }
            .sheet(isPresented: $isAnnualCalendarPresented) {
                AnnualCalendarView(expenses: visibleExpenses, selection: $selectedMonth)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: selectedMonth) {
                isPaidExpanded = false
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
    }

    private func togglePaid(_ occurrence: ExpenseOccurrence) {
        withAnimation(.easeInOut(duration: 0.2)) {
            occurrence.expense.setPaid(!occurrence.isPaid, in: selectedMonth)
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
