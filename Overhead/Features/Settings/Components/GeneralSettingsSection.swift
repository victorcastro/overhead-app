import SwiftUI

struct GeneralSettingsSection: View {
    var body: some View {
        Section {
            ICloudSyncRow()
            CurrencyRow()
            LocationsRow()
        }
        .listRowBackground(Theme.card)
    }

    private struct ICloudSyncRow: View {
        @Environment(AppSettings.self) private var settings

        private var hasICloudAccount: Bool {
            FileManager.default.ubiquityIdentityToken != nil
        }

        private var iCloudStatus: String {
            guard hasICloudAccount else { return "Not signed in" }
            return settings.iCloudSyncEnabled ? "On" : "Off"
        }

        var body: some View {
            NavigationLink {
                CloudSettingsView()
            } label: {
                HStack {
                    Text("iCloud Sync (auto backup)")
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Text(iCloudStatus)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
    }

    private struct CurrencyRow: View {
        @Environment(AppSettings.self) private var settings

        var body: some View {
            NavigationLink {
                CurrencyView()
            } label: {
                HStack {
                    Text("Currency")
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Text(settings.baseCurrency.rawValue)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
    }

    private struct LocationsRow: View {
        @Environment(AppSettings.self) private var settings

        var body: some View {
            NavigationLink {
                LocationSettingsView()
            } label: {
                HStack {
                    Text("Locations expenses")
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Text(settings.locationCodes.isEmpty ? "None" : "\(settings.locationCodes.count)")
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
    }
}
