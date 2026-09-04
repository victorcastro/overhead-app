import SwiftUI
import SwiftData

@main
struct SinkingFoundApp: App {
    @State private var settings: AppSettings
    @State private var container: ModelContainer

    init() {
        let settings = AppSettings()
        _settings = State(initialValue: settings)
        _container = State(
            initialValue: ExpenseStore.makeContainer(cloudSyncEnabled: settings.iCloudSyncEnabled)
        )
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(settings)
                .environment(\.moneyFormat, MoneyFormat(decimals: settings.decimalPlaces))
                .onChange(of: settings.iCloudSyncEnabled) { _, enabled in
                    container = ExpenseStore.makeContainer(cloudSyncEnabled: enabled)
                }
        }
        .modelContainer(container)
    }
}
