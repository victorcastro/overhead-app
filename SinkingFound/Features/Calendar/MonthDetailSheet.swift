import SwiftUI

struct MonthDetailSheet: View {
    @Environment(\.moneyFormat) private var money
    @Environment(\.dismiss) private var dismiss

    let month: Date
    let expenses: [FixedExpense]
    let base: Currency
    let showsLocation: Bool

    private var plan: MonthPlan {
        MonthPlan(expenses: expenses, month: month, base: base)
    }

    private var monthTitle: String {
        month.formatted(.dateTime.month(.wide))
    }

    private var monthAndYearTitle: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                let plan = plan

                VStack(spacing: 0) {
                    header(plan)
                        .padding(.bottom, 16)

                    if !plan.unpaid.isEmpty {
                        SectionHeader(title: "Unpaid · \(plan.unpaid.count)")
                        CardList(data: plan.unpaid) { occurrence in
                            ExpenseRow(occurrence: occurrence, showsLocation: showsLocation)
                        }
                        .padding(.bottom, 16)
                    }

                    if !plan.paid.isEmpty {
                        SectionHeader(title: "Paid · \(plan.paid.count)")
                        CardList(data: plan.paid) { occurrence in
                            ExpenseRow(occurrence: occurrence, showsLocation: showsLocation)
                        }
                        .padding(.bottom, 16)
                    }

                    if plan.occurrences.isEmpty {
                        EmptyMonthView(monthTitle: monthTitle)
                            .padding(.top, 24)
                    }
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.top, 8)
            }
            .background(Theme.background)
            .scrollIndicators(.hidden)
            .navigationTitle(monthAndYearTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
    }

    private func header(_ plan: MonthPlan) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Total fixed cost")
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText)

            Text(money(plan.dueThisMonth, base))
                .font(.system(size: 44, weight: .bold))
                .kerning(-1)
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .cardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary(plan))
    }

    private func accessibilitySummary(_ plan: MonthPlan) -> String {
        "\(monthAndYearTitle): \(money(plan.dueThisMonth, base)) in fixed expenses."
    }
}
