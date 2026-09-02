import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                DashboardView()
            }

            Tab("Calendar", systemImage: "calendar") {
                CalendarView()
            }

            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
    }
}
