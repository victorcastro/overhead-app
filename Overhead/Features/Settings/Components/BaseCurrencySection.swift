import SwiftUI

struct BaseCurrencySection: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Section {
            Picker("Base currency", selection: $settings.baseCurrency) {
                ForEach(Currency.allCases) { currency in
                    Text("\(currency.displayName) · \(currency.rawValue)").tag(currency)
                }
            }
            .pickerStyle(.menu)
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
    }
}
