import SwiftUI

struct RootTabView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                DashboardView()
                    .id(settings.iCloudSyncEnabled)
            }

            Tab("Calendar", systemImage: "calendar") {
                CalendarView()
                    .id(settings.iCloudSyncEnabled)
            }

            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
    }
}
