import Foundation

struct ExpenseBackup: Codable {
    static let formatIdentifier = "overhead.backup"
    static let currentVersion = 1

    struct Settings: Codable {
        let baseCurrency: Currency
        let decimalPlaces: Int
        let locationCodes: [String]
    }

    struct Expense: Codable {
        let name: String
        let amount: String
        let currency: Currency
        let frequency: ExpenseFrequency
        let category: ExpenseCategory
        let location: String
        let anchorDueDate: Date
        let intervalMonths: Int
        let endRule: ExpenseEndRule
        let endOccurrences: Int
        let endDate: Date?
        let paidPeriods: [String]
        let createdAt: Date

        var decimalAmount: Decimal? {
            Decimal(string: amount, locale: Locale(identifier: "en_US_POSIX"))
        }
    }

    let format: String
    let version: Int
    let exportedAt: Date
    let settings: Settings
    let expenses: [Expense]
}

enum BackupError: LocalizedError {
    case unreadableFile
    case notABackup
    case newerVersion
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            "The file could not be opened."
        case .notABackup:
            "This file is not an Overhead backup."
        case .newerVersion:
            "This backup was made by a newer version of Overhead."
        case .invalidAmount:
            "The file holds an amount that could not be read."
        }
    }
}

enum BackupCodec {
    static func encode(_ backup: ExpenseBackup) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    static func decode(_ data: Data) throws -> ExpenseBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let backup = try? decoder.decode(ExpenseBackup.self, from: data),
              backup.format == ExpenseBackup.formatIdentifier
        else { throw BackupError.notABackup }

        guard backup.version <= ExpenseBackup.currentVersion else { throw BackupError.newerVersion }
        guard backup.expenses.allSatisfy({ $0.decimalAmount != nil }) else { throw BackupError.invalidAmount }

        return backup
    }
}
