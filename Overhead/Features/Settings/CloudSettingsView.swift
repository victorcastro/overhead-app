import SwiftUI

struct CloudSettingsView: View {
    @Environment(AppSettings.self) private var settings

    @State private var isEraseConfirmationPresented = false
    @State private var isErasing = false
    @State private var eraseError: String?

    private var hasICloudAccount: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    var body: some View {
        Form {
            syncSection
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("iCloud")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .confirmationDialog(
            "Delete the iCloud copy of your data?",
            isPresented: $isEraseConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete from iCloud", role: .destructive) { erase() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This removes the expenses and settings stored in your private iCloud "
                    + "database. The data on this device is kept, and syncing is turned off. "
                    + "This cannot be undone."
            )
        }
        .alert("Could not delete iCloud data", isPresented: binding(for: $eraseError)) {
            Button("OK", role: .cancel) { eraseError = nil }
        } message: {
            Text(eraseError ?? "")
        }
    }

    private var syncSection: some View {
        @Bindable var settings = settings

        return Section {
            Toggle("Sync with iCloud", isOn: $settings.iCloudSyncEnabled)
                .foregroundStyle(Theme.primaryText)
                .disabled(!hasICloudAccount)

            Button(role: .destructive) {
                isEraseConfirmationPresented = true
            } label: {
                HStack {
                    Text("Delete iCloud data")
                    Spacer()
                    if isErasing {
                        ProgressView()
                    }
                }
            }
            .disabled(!hasICloudAccount || isErasing)
        } header: {
            Text("Sync")
        } footer: {
            Text(syncFooter)
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText)
        }
        .listRowBackground(Theme.card)
    }

    private var syncFooter: String {
        guard hasICloudAccount else {
            return "Sign in to iCloud in the Settings app to sync your expenses across devices."
        }
        return "Syncs your expenses, base currency, and locations across your devices. "
            + "Turning it off keeps both the data on this device and the copy in iCloud. "
            + "Deleting the iCloud data only removes that copy; if another device still has "
            + "syncing on, it will upload its own copy again."
    }

    private func binding<Value>(for state: Binding<Value?>) -> Binding<Bool> {
        Binding(
            get: { state.wrappedValue != nil },
            set: { if !$0 { state.wrappedValue = nil } }
        )
    }

    private func erase() {
        isErasing = true
        Task {
            do {
                try await CloudDataEraser.eraseAll(settings: settings)
            } catch {
                eraseError = error.localizedDescription
            }
            isErasing = false
        }
    }
}
