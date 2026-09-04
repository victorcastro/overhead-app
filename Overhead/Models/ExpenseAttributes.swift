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

enum ExpenseEndRule: String, Codable, CaseIterable, Identifiable {
    case never, afterOccurrences, onDate

    var id: String { rawValue }

    var label: String {
        switch self {
        case .never: "Never"
        case .afterOccurrences: "After"
        case .onDate: "On date"
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

    var sfSymbol: String {
        switch self {
        case .housing: "house.fill"
        case .insurance: "shield.fill"
        case .taxes: "percent"
        case .utilities: "bolt.fill"
        case .subscriptions: "arrow.triangle.2.circlepath"
        case .education: "graduationcap.fill"
        case .transport: "car.fill"
        }
    }
}

enum LocationFilter: Hashable, Identifiable {
    case all
    case code(String)

    var id: String {
        switch self {
        case .all: "all"
        case .code(let code): "code:" + code
        }
    }

    var label: String {
        switch self {
        case .all: "All"
        case .code(let code): Location.name(for: code) ?? code
        }
    }

    func matches(_ expense: FixedExpense) -> Bool {
        switch self {
        case .all: true
        case .code(let code): expense.location == code
        }
    }
}
