import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
    }
}
