import SwiftUI

struct LocationFilterPills: View {
    let codes: [String]
    @Binding var selection: LocationFilter

    private var filters: [LocationFilter] {
        let sorted = codes.sorted {
            (Location.name(for: $0) ?? $0).localizedStandardCompare(Location.name(for: $1) ?? $1) == .orderedAscending
        }
        return [.all] + sorted.map(LocationFilter.code)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters) { filter in
                    let isSelected = filter == selection
                    Button {
                        selection = filter
                    } label: {
                        Text(filter.label)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                            .foregroundStyle(isSelected ? Color.black : Theme.secondaryText)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 7)
                            .background(isSelected ? Color.white : Theme.card, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
        }
    }
}
