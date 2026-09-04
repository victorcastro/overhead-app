import SwiftUI

struct PaidSummaryCard: View {
    @Environment(\.moneyFormat) private var money

    let paid: [ExpenseOccurrence]
    let base: Currency
    let showsLocation: Bool
    @Binding var isExpanded: Bool
    let onTogglePaid: (ExpenseOccurrence) -> Void
    let onSelect: (ExpenseOccurrence) -> Void

    private var total: Decimal { paid.reduce(0) { $0 + $1.amountInBase } }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    PaidCircle(isPaid: true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Paid · \(paid.count)")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.headerText)
                        Text(paid.map(\.expense.name).joined(separator: ", "))
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(money(total, base))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.mutedText)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.mutedText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(paid) { occurrence in
                    Rectangle().fill(Theme.separator).frame(height: 1)
                    ExpenseRow(occurrence: occurrence, showsLocation: showsLocation) {
                        onTogglePaid(occurrence)
                    }
                    .onTapGesture { onSelect(occurrence) }
                }
            }
        }
        .cardBackground()
    }
}
