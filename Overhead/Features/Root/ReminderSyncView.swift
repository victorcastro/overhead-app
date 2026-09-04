import SwiftData
import SwiftUI

struct ReminderSyncView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase
    @Query private var expenses: [FixedExpense]

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .task(id: signature) { await refresh() }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await refresh() }
            }
    }

    private var signature: String {
        let expenseKeys = expenses.map { expense in
            [
                ExpenseIdentity.key(for: expense),
                expense.endRule.rawValue,
                String(expense.endOccurrences),
                expense.endDate.map { ExpenseIdentity.dayKey(for: $0) } ?? "",
                expense.paidPeriods.sorted().joined(separator: ",")
            ].joined(separator: "|")
        }

        return ([
            String(settings.remindersEnabled),
            String(settings.reminderDaysBefore),
            String(expenses.count)
        ] + expenseKeys).joined(separator: "\n")
    }

    private func refresh() async {
        await ExpenseReminderScheduler.shared.refresh(expenses: expenses, settings: settings)
    }
}
