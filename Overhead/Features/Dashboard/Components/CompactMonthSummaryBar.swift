import SwiftUI

struct CompactMonthSummaryBar: View {
    @Environment(\.moneyFormat) private var money

    let plan: MonthPlan

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Left to pay this month")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
                Spacer(minLength: 8)
                Text(money(plan.leftToPayThisMonth, plan.base))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
            }
            ProgressBar(progress: plan.progress)
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Theme.background.opacity(0.85))
    }
}
