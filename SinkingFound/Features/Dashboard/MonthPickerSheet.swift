import SwiftUI

struct MonthPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: Date

    @State private var displayedYear: Date

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    init(selection: Binding<Date>) {
        _selection = selection
        _displayedYear = State(initialValue: Self.clampedYear(for: selection.wrappedValue))
    }

    private static func yearStart(of date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .year, for: date)?.start ?? date
    }

    private static var currentYear: Date {
        yearStart(of: .now)
    }

    private static var earliestYear: Date {
        Calendar.current.date(byAdding: .year, value: -1, to: currentYear) ?? currentYear
    }

    private static var latestYear: Date {
        Calendar.current.date(byAdding: .year, value: 1, to: currentYear) ?? currentYear
    }

    private static func clampedYear(for date: Date) -> Date {
        min(max(yearStart(of: date), earliestYear), latestYear)
    }

    private var currentMonth: Date {
        calendar.dateInterval(of: .month, for: .now)?.start ?? .now
    }

    private var canGoBack: Bool {
        displayedYear > Self.earliestYear
    }

    private var canGoForward: Bool {
        displayedYear < Self.latestYear
    }

    private var isOnCurrentMonth: Bool {
        calendar.isDate(selection, equalTo: .now, toGranularity: .month)
    }

    private var yearTitle: String {
        displayedYear.formatted(.dateTime.year())
    }

    private var months: [Date] {
        (0..<12).compactMap { calendar.date(byAdding: .month, value: $0, to: displayedYear) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                yearHeader

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(months, id: \.self) { month in
                        monthButton(month)
                    }
                }

                Button("This month") {
                    select(currentMonth)
                }
                .font(.system(size: 15, weight: .semibold))
                .disabled(isOnCurrentMonth)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.background)
            .navigationTitle("Choose month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
    }

    private var yearHeader: some View {
        HStack {
            Button {
                moveYear(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 32, height: 32)
            }
            .disabled(!canGoBack)
            .accessibilityLabel("Previous year")

            Text(yearTitle)
                .font(.title2.bold())
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity)

            Button {
                moveYear(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 32, height: 32)
            }
            .disabled(!canGoForward)
            .accessibilityLabel("Next year")
        }
    }

    private func monthButton(_ month: Date) -> some View {
        let isSelected = calendar.isDate(month, equalTo: selection, toGranularity: .month)
        let isCurrent = calendar.isDate(month, equalTo: .now, toGranularity: .month)

        return Button {
            select(month)
        } label: {
            Text(month.formatted(.dateTime.month(.abbreviated)).uppercased())
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? Color.black : Theme.primaryText)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    isSelected ? Color.white : Theme.card,
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(strokeColor(isSelected: isSelected, isCurrent: isCurrent), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel(accessibilityLabel(for: month, isCurrent: isCurrent))
    }

    private func strokeColor(isSelected: Bool, isCurrent: Bool) -> Color {
        if isSelected { return .clear }
        return isCurrent ? Theme.positive : Theme.separator
    }

    private func accessibilityLabel(for month: Date, isCurrent: Bool) -> String {
        let name = month.formatted(.dateTime.month(.wide).year())
        return isCurrent ? "\(name), current month" : name
    }

    private func select(_ month: Date) {
        selection = calendar.dateInterval(of: .month, for: month)?.start ?? month
        dismiss()
    }

    private func moveYear(by offset: Int) {
        guard let year = calendar.date(byAdding: .year, value: offset, to: displayedYear) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedYear = Self.clampedYear(for: year)
        }
    }
}
