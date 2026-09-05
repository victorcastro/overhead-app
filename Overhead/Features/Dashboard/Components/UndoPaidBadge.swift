import SwiftUI

struct UndoPaidBadge: View {
    let expenseName: String
    let action: () -> Void

    private var label: Text {
        var prefix = AttributedString("Undo ")
        prefix.font = .system(size: 14, weight: .semibold)

        var name = AttributedString(expenseName)
        name.font = .system(size: 14, weight: .regular)

        return Text(prefix + name)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 13, weight: .semibold))
                label
                    .lineLimit(1)
            }
            .foregroundStyle(Theme.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.control, in: Capsule())
            .overlay(Capsule().stroke(Theme.separator, lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}
