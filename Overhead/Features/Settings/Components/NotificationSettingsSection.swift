import SwiftUI
import UIKit
import UserNotifications

struct NotificationSettingsSection: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase

    @State private var status: UNAuthorizationStatus = .notDetermined
    @State private var isRequesting = false

    var body: some View {
        @Bindable var settings = settings

        return Section {
            Toggle("Notify before due date", isOn: $settings.remindersEnabled)
                .foregroundStyle(Theme.primaryText)
                .disabled(isRequesting)

            if settings.remindersEnabled {
                Picker("Remind me", selection: $settings.reminderDaysBefore) {
                    ForEach(AppSettings.reminderDaysBeforeOptions, id: \.self) { days in
                        Text(label(for: days)).tag(days)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            if status == .denied {
                Button("Open Settings") { openSystemSettings() }
                    .foregroundStyle(Theme.primaryText)
            }
        } footer: {
            Text(footer)
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText)
        }
        .listRowBackground(Theme.card)
        .task { status = await ExpenseReminderScheduler.shared.authorizationStatus() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { status = await ExpenseReminderScheduler.shared.authorizationStatus() }
        }
        .onChange(of: settings.remindersEnabled) { _, enabled in
            Task { await handle(enabled) }
        }
    }

    private var footer: String {
        guard status != .denied else {
            return "Notifications are turned off for Overhead in the Settings app."
        }
        return "Reminders arrive at \(AppSettings.reminderHour):00 on the chosen day. "
            + "Expenses already marked as paid are skipped."
    }

    private func label(for days: Int) -> String {
        switch days {
        case 0: "On the due date"
        case 1: "1 day before"
        default: "\(days) days before"
        }
    }

    private func handle(_ enabled: Bool) async {
        guard enabled else {
            await ExpenseReminderScheduler.shared.cancelAll()
            return
        }

        let current = await ExpenseReminderScheduler.shared.authorizationStatus()
        status = current

        switch current {
        case .notDetermined:
            isRequesting = true
            let granted = await ExpenseReminderScheduler.shared.requestAuthorization()
            status = await ExpenseReminderScheduler.shared.authorizationStatus()
            isRequesting = false
            if !granted { settings.remindersEnabled = false }
        case .denied:
            settings.remindersEnabled = false
        default:
            break
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
