import SwiftUI

struct ExchangeRatesSection: View {
    @Environment(AppSettings.self) private var settings

    private var others: [Currency] {
        Currency.allCases.filter { $0 != settings.baseCurrency }
    }

    var body: some View {
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
}
