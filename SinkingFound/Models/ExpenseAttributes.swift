import Foundation

enum ExpenseFrequency: String, Codable, CaseIterable, Identifiable {
    case monthly, annual, oneTime, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .monthly: "Monthly"
        case .annual: "Annual"
        case .oneTime: "One-time"
        case .other: "Other"
        }
    }
}

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case housing, insurance, taxes, utilities, subscriptions, education, transport

    var id: String { rawValue }

    var label: String {
        switch self {
        case .housing: "Housing"
        case .insurance: "Insurance"
        case .taxes: "Taxes & Fees"
        case .utilities: "Utilities"
        case .subscriptions: "Subscriptions"
        case .education: "Education"
        case .transport: "Transport"
        }
    }
}

enum ExpenseLocation: String, Codable, CaseIterable, Identifiable {
    case spain, peru

    var id: String { rawValue }

    var label: String {
        switch self {
        case .spain: "Spain"
        case .peru: "Peru"
        }
    }

    var defaultCurrency: Currency {
        switch self {
        case .spain: .eur
        case .peru: .pen
        }
    }
}

enum LocationFilter: Hashable, Identifiable, CaseIterable {
    case all
    case location(ExpenseLocation)

    static var allCases: [LocationFilter] { [.all] + ExpenseLocation.allCases.map(LocationFilter.location) }

    var id: String {
        switch self {
        case .all: "all"
        case .location(let location): location.rawValue
        }
    }

    var label: String {
        switch self {
        case .all: "All"
        case .location(let location): location.label
        }
    }

    func matches(_ expense: FixedExpense) -> Bool {
        switch self {
        case .all: true
        case .location(let location): expense.location == location
        }
    }
}
