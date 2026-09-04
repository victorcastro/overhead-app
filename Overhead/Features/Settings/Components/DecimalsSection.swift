import SwiftUI

struct DecimalsSection: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

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
    }
}
