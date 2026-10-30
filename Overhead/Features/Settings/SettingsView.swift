import SwiftUI

struct SettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack {
            content
                .scrollContentBackground(.hidden)
                .background(Theme.background)
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var content: some View {
        if horizontalSizeClass == .regular {
            HStack(alignment: .top, spacing: 24) {
                Form { NotificationSettingsSection() }
                Form { GeneralSettingsSection() }
            }
        } else {
            Form {
                NotificationSettingsSection()
                GeneralSettingsSection()
            }
        }
    }
}
