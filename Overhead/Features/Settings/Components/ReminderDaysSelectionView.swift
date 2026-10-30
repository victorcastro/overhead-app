import SwiftUI

struct ReminderDaysSelectionView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        List {
            Section {
                ForEach(AppSettings.reminderDaysBeforeOptions, id: \.self) { days in
                    Button { toggle(days) } label: {
                        HStack {
                            Text(label(for: days))
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            if settings.reminderDaysBefore.contains(days) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                    }
                }
            } footer: {
                Text("Pick one or more. At least one stays selected.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
            }
            .listRowBackground(Theme.card)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Remind me")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ days: Int) {
        var selected = settings.reminderDaysBefore
        if let index = selected.firstIndex(of: days) {
            selected.remove(at: index)
        } else {
            selected.append(days)
        }
        settings.reminderDaysBefore = selected
    }

    private func label(for days: Int) -> String {
        switch days {
        case 0: "On the due date"
        case 1: "1 day before"
        default: "\(days) days before"
        }
    }
}
