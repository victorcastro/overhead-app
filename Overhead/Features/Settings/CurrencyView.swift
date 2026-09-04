import SwiftUI

struct CurrencyView: View {
    var body: some View {
        Form {
            BaseCurrencySection()
            DecimalsSection()
            ExchangeRatesSection()
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
