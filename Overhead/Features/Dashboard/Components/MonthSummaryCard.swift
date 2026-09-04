import SwiftUI

struct MonthSummaryCard: View {
    @Environment(\.moneyFormat) private var money

    let plan: MonthPlan
    let monthName: String
    var isCurrentMonth = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Left to pay this month")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
                if isCurrentMonth {
                    Spacer()
                    Text("CURRENT")
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(0.4)
                        .foregroundStyle(Theme.positive)
                }
            }

            Text(money(plan.leftToPayThisMonth, plan.base))
                .font(.system(size: 44, weight: .bold))
                .kerning(-1)
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            ProgressBar(progress: plan.progress)
                .padding(.top, 14)
                .padding(.bottom, 8)

            HStack {
                Text("\(money(plan.paidTotal, plan.base)) paid")
                Spacer(minLength: 8)
                Text("of \(money(plan.total, plan.base)) total")
            }
            .font(.system(size: 12))
            .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .cardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        "Left to pay in \(monthName): \(money(plan.leftToPayThisMonth, plan.base)). "
            + "\(money(plan.paidTotal, plan.base)) paid "
            + "of \(money(plan.total, plan.base))."
    }
}
