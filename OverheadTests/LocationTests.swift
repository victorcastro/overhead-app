import Foundation
import Testing
@testable import Overhead

struct LocationTests {

    @Test func nameIsNilForUndefinedOrUnknown() {
        #expect(Location.name(for: "") == nil)
        #expect(Location.name(for: "spain") == nil)
        #expect(Location.name(for: "ZZ") == nil)
    }

    @Test func nameResolvesRealRegionCodes() {
        #expect(Location.name(for: "ES") != nil)
        #expect(Location.name(for: "PE") != nil)
    }

    @Test func catalogHasCountriesAndDropsGroupings() {
        let codes = Set(CountryCatalog.all.map(\.code))
        #expect(codes.contains("ES"))
        #expect(codes.contains("PE"))
        #expect(codes.contains("US"))
        #expect(!codes.contains("EU"))
        #expect(!codes.contains("001"))
        #expect(CountryCatalog.all == CountryCatalog.all.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        })
    }

    @Test func locationFilterMatching() {
        let expense = FixedExpense(name: "Rent", amount: 100, location: "ES", anchorDueDate: .now)
        #expect(LocationFilter.all.matches(expense))
        #expect(LocationFilter.code("ES").matches(expense))
        #expect(!LocationFilter.code("PE").matches(expense))
    }

    @Test func newExpenseIsUndefined() {
        let expense = FixedExpense(name: "Rent", amount: 100, anchorDueDate: .now)
        #expect(expense.location == "")
        #expect(!LocationFilter.code("ES").matches(expense))
    }
}
