import SwiftUI

struct AnnualShareRow: View {
    @Environment(\.moneyFormat) private var money

    let item: AnnualShareItem
    let showsLocation: Bool

    private var expense: FixedExpense { item.expense }

    private var subtitle: String {
        var parts = ["Due \(item.dueDate.formatted(.dateTime.month(.abbreviated).year()))"]
        if showsLocation, let name = Location.name(for: expense.location) {
            parts.append(name)
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.primaryText)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(money(item.monthlyShareInBase, item.base)) / mo")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.primaryText)
                Text("of \(money(expense.amount(in: item.base), item.base))")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
