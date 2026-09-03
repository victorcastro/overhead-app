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
