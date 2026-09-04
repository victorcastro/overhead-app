import SwiftUI

struct MoneyFormat {
    let decimals: Int

    func callAsFunction(_ value: Decimal, _ currency: Currency) -> String {
        Money.string(value, currency: currency, decimals: decimals)
    }
}

extension EnvironmentValues {
    @Entry var moneyFormat = MoneyFormat(decimals: AppSettings.defaultDecimalPlaces)
}
