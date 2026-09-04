import Foundation
import SwiftData

enum BackupMergeStrategy {
    case merge
    case replace
}

struct BackupImportResult {
    let inserted: Int
    let updated: Int
    let removed: Int
}

enum ExpenseBackupService {
    static func snapshot(expenses: [FixedExpense], settings: AppSettings) -> ExpenseBackup {
        ExpenseBackup(
            format: ExpenseBackup.formatIdentifier,
            version: ExpenseBackup.currentVersion,
            exportedAt: .now,
            settings: ExpenseBackup.Settings(
                baseCurrency: settings.baseCurrency,
                decimalPlaces: settings.decimalPlaces,
                locationCodes: settings.locationCodes
            ),
            expenses: expenses
                .sorted { $0.createdAt < $1.createdAt }
                .map(entry(for:))
        )
    }

    static func defaultFilename(date: Date = .now) -> String {
        "Overhead Backup \(ExpenseIdentity.dayKey(for: date))"
    }

    @MainActor
    static func apply(
        _ backup: ExpenseBackup,
        strategy: BackupMergeStrategy,
        existing: [FixedExpense],
        context: ModelContext,
        settings: AppSettings
    ) throws -> BackupImportResult {
        let entries = deduplicated(backup.expenses)
        let result: BackupImportResult

        switch strategy {
        case .replace:
            for expense in existing {
                context.delete(expense)
            }
            for entry in entries {
                context.insert(model(for: entry))
            }
            settings.baseCurrency = backup.settings.baseCurrency
            settings.decimalPlaces = backup.settings.decimalPlaces
            settings.locationCodes = backup.settings.locationCodes
            result = BackupImportResult(inserted: entries.count, updated: 0, removed: existing.count)

        case .merge:
            var index = Dictionary(
                existing.map { (ExpenseIdentity.key(for: $0), $0) },
                uniquingKeysWith: { first, _ in first }
            )
            var inserted = 0
            var updated = 0

            for entry in entries {
                let key = ExpenseIdentity.key(for: entry)
                if let match = index[key] {
                    let merged = Set(match.paidPeriods).union(entry.paidPeriods).sorted()
                    if merged != match.paidPeriods.sorted() {
                        match.paidPeriods = merged
                        updated += 1
                    }
                } else {
                    let expense = model(for: entry)
                    context.insert(expense)
                    index[key] = expense
                    inserted += 1
                }
            }

            settings.locationCodes = mergedLocationCodes(
                current: settings.locationCodes,
                backup: backup.settings.locationCodes,
                entries: entries
            )
            result = BackupImportResult(inserted: inserted, updated: updated, removed: 0)
        }

        try context.save()
        return result
    }

    private static func entry(for expense: FixedExpense) -> ExpenseBackup.Expense {
        ExpenseBackup.Expense(
            name: expense.name,
            amount: expense.amount.description,
            currency: expense.currency,
            frequency: expense.frequency,
            category: expense.category,
            location: expense.location,
            anchorDueDate: expense.anchorDueDate,
            intervalMonths: expense.intervalMonths,
            endRule: expense.endRule,
            endOccurrences: expense.endOccurrences,
            endDate: expense.endDate,
            paidPeriods: expense.paidPeriods.sorted(),
            createdAt: expense.createdAt
        )
    }

    private static func model(for entry: ExpenseBackup.Expense) -> FixedExpense {
        FixedExpense(
            name: entry.name,
            amount: entry.decimalAmount ?? 0,
            currency: entry.currency,
            frequency: entry.frequency,
            category: entry.category,
            location: entry.location,
            anchorDueDate: entry.anchorDueDate,
            intervalMonths: entry.intervalMonths,
            endRule: entry.endRule,
            endOccurrences: entry.endOccurrences,
            endDate: entry.endDate,
            paidPeriods: entry.paidPeriods.sorted(),
            createdAt: entry.createdAt
        )
    }

    private static func deduplicated(_ entries: [ExpenseBackup.Expense]) -> [ExpenseBackup.Expense] {
        var order: [String] = []
        var merged: [String: ExpenseBackup.Expense] = [:]

        for entry in entries {
            let key = ExpenseIdentity.key(for: entry)
            guard let existing = merged[key] else {
                order.append(key)
                merged[key] = entry
                continue
            }
            merged[key] = existing.mergingPaidPeriods(with: entry.paidPeriods)
        }

        return order.compactMap { merged[$0] }
    }

    private static func mergedLocationCodes(
        current: [String],
        backup: [String],
        entries: [ExpenseBackup.Expense]
    ) -> [String] {
        var codes = current
        let candidates = backup + entries.map(\.location)

        for code in candidates where !code.isEmpty && !codes.contains(code) {
            codes.append(code)
        }

        return codes
    }
}

private extension ExpenseBackup.Expense {
    func mergingPaidPeriods(with periods: [String]) -> ExpenseBackup.Expense {
        ExpenseBackup.Expense(
            name: name,
            amount: amount,
            currency: currency,
            frequency: frequency,
            category: category,
            location: location,
            anchorDueDate: anchorDueDate,
            intervalMonths: intervalMonths,
            endRule: endRule,
            endOccurrences: endOccurrences,
            endDate: endDate,
            paidPeriods: Set(paidPeriods).union(periods).sorted(),
            createdAt: createdAt
        )
    }
}
