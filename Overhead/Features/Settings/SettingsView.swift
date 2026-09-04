import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    private var hasICloudAccount: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                iCloudSection
                    .listRowBackground(Theme.card)

                Section {
                    Picker("Base currency", selection: $settings.baseCurrency) {
                        ForEach(Currency.allCases) { currency in
                            Text("\(currency.displayName) · \(currency.rawValue)").tag(currency)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("Currency")
                } footer: {
                    Text(
                        "Every total is shown in this currency. Each expense keeps the currency "
                            + "you enter it in and is converted for the totals."
                    )
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.card)

                Section {
                    Picker("Decimals", selection: $settings.decimalPlaces) {
                        ForEach(AppSettings.decimalPlacesOptions, id: \.self) { places in
                            Text(Money.sample(decimals: places)).tag(places)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("Amounts")
                } footer: {
                    Text("How many decimals every amount shows across the app.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.card)

                Section {
                    NavigationLink {
                        LocationSettingsView()
                    } label: {
                        HStack {
                            Text("Locations")
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            Text(settings.locationCodes.isEmpty ? "None" : "\(settings.locationCodes.count)")
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                } header: {
                    Text("Locations")
                } footer: {
                    Text(
                        "Tag expenses by country. With no locations defined, the location "
                            + "filter and picker stay hidden. Deleting a location moves its "
                            + "expenses back to Undefined."
                    )
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.card)

                NotificationSettingsSection()

                let others = Currency.allCases.filter { $0 != settings.baseCurrency }
                if !others.isEmpty {
                    Section {
                        ForEach(others) { currency in
                            HStack {
                                Text(currency.displayName)
                                    .foregroundStyle(Theme.primaryText)
                                Spacer()
                                Text(
                                    "1 \(currency.rawValue) = "
                                        + Money.string(
                                            currency.amount(1, to: settings.baseCurrency),
                                            currency: settings.baseCurrency,
                                            decimals: 2
                                        )
                                )
                                .foregroundStyle(Theme.secondaryText)
                            }
                        }
                    } header: {
                        Text("Exchange rates")
                    } footer: {
                        Text("Approximate rates, bundled with the app.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .listRowBackground(Theme.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var iCloudSection: some View {
        Section {
            NavigationLink {
                CloudSettingsView()
            } label: {
                HStack {
                    Text("iCloud")
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Text(iCloudStatus)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text("Sync across your devices, and download or upload your data as a file.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private var iCloudStatus: String {
        guard hasICloudAccount else { return "Not signed in" }
        return settings.iCloudSyncEnabled ? "On" : "Off"
    }
}
