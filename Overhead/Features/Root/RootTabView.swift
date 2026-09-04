import SwiftUI

struct RootTabView: View {
    @Environment(AppSettings.self) private var settings

    @State private var selection = 0
    @State private var homeResetToken = 0
    @State private var calendarResetToken = 0

    private var selectionBinding: Binding<Int> {
        Binding {
            selection
        } set: { newValue in
            if newValue == selection {
                if newValue == 0 { homeResetToken += 1 }
                if newValue == 1 { calendarResetToken += 1 }
            }
            selection = newValue
        }
    }

    var body: some View {
        TabView(selection: selectionBinding) {
            Tab("Home", systemImage: "house", value: 0) {
                DashboardView(resetToken: homeResetToken)
                    .id(settings.iCloudSyncEnabled)
            }

            Tab("Calendar", systemImage: "calendar", value: 1) {
                CalendarView(resetToken: calendarResetToken)
                    .id(settings.iCloudSyncEnabled)
            }

            Tab("Settings", systemImage: "gearshape", value: 2) {
                SettingsView()
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .background { ReminderSyncView() }
    }
}
