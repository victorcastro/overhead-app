import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                NotificationSettingsSection()
                GeneralSettingsSection()
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
