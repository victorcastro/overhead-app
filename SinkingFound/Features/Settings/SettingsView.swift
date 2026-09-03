import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    @State private var isEraseConfirmationPresented = false
    @State private var isErasing = false
    @State private var eraseError: String?

    private var hasICloudAccount: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                iCloudSection

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
            .confirmationDialog(
                "Delete the iCloud copy of your data?",
                isPresented: $isEraseConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Delete from iCloud", role: .destructive) { erase() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "This removes the expenses and settings stored in your private iCloud "
                        + "database. The data on this device is kept, and syncing is turned off. "
                        + "This cannot be undone."
                )
            }
            .alert("Could not delete iCloud data", isPresented: eraseErrorBinding) {
                Button("OK", role: .cancel) { eraseError = nil }
            } message: {
                Text(eraseError ?? "")
            }
        }
    }

    private var iCloudSection: some View {
        @Bindable var settings = settings

        return Section {
            Toggle("Sync with iCloud", isOn: $settings.iCloudSyncEnabled)
                .foregroundStyle(Theme.primaryText)
                .disabled(!hasICloudAccount)

            Button(role: .destructive) {
                isEraseConfirmationPresented = true
            } label: {
                HStack {
                    Text("Delete iCloud data")
                    Spacer()
                    if isErasing {
                        ProgressView()
                    }
                }
            }
            .disabled(!hasICloudAccount || isErasing)
        } header: {
            Text("iCloud")
        } footer: {
            Text(iCloudFooter)
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText)
        }
        .listRowBackground(Theme.card)
    }

    private var iCloudFooter: String {
        guard hasICloudAccount else {
            return "Sign in to iCloud in the Settings app to sync your expenses across devices."
        }
        return "Syncs your expenses, base currency, and locations across your devices. "
            + "Turning it off keeps both the data on this device and the copy in iCloud. "
            + "Deleting the iCloud data only removes that copy; if another device still has "
            + "syncing on, it will upload its own copy again."
    }

    private var eraseErrorBinding: Binding<Bool> {
        Binding(
            get: { eraseError != nil },
            set: { if !$0 { eraseError = nil } }
        )
    }

    private func erase() {
        isErasing = true
        Task {
            do {
                try await CloudDataEraser.eraseAll(settings: settings)
            } catch {
                eraseError = error.localizedDescription
            }
            isErasing = false
        }
    }
}
