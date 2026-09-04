import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct CloudSettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [FixedExpense]

    @State private var isEraseConfirmationPresented = false
    @State private var isErasing = false
    @State private var eraseError: String?
    @State private var exportDocument: BackupDocument?
    @State private var isExporterPresented = false
    @State private var isImporterPresented = false
    @State private var pendingImport: PendingImport?
    @State private var isImportDialogPresented = false
    @State private var isReplaceConfirmationPresented = false
    @State private var fileError: String?
    @State private var importSummary: String?

    private struct PendingImport: Identifiable {
        let backup: ExpenseBackup
        var id: Date { backup.exportedAt }
    }

    private var hasICloudAccount: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    var body: some View {
        Form {
            syncSection
            dataFileSection
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
        .fileExporter(
            isPresented: $isExporterPresented,
            document: exportDocument,
            contentType: .json,
            defaultFilename: ExpenseBackupService.defaultFilename()
        ) { result in
            if case let .failure(error) = result {
                fileError = error.localizedDescription
            }
            exportDocument = nil
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.json]
        ) { result in
            load(result)
        }
        .confirmationDialog(
            importTitle,
            isPresented: $isImportDialogPresented,
            titleVisibility: .visible
        ) {
            Button("Merge") { apply(.merge) }
            Button("Replace all", role: .destructive) { isReplaceConfirmationPresented = true }
            Button("Cancel", role: .cancel) { pendingImport = nil }
        } message: {
            Text("The file also carries its own base currency, decimals, and locations.")
        }
        .alert("Replace everything on this device?", isPresented: $isReplaceConfirmationPresented) {
            Button("Replace all", role: .destructive) { apply(.replace) }
            Button("Cancel", role: .cancel) { pendingImport = nil }
        } message: {
            Text(replaceMessage)
        }
        .alert("Could not read this file", isPresented: binding(for: $fileError)) {
            Button("OK", role: .cancel) { fileError = nil }
        } message: {
            Text(fileError ?? "")
        }
        .alert("Import finished", isPresented: binding(for: $importSummary)) {
            Button("OK", role: .cancel) { importSummary = nil }
        } message: {
            Text(importSummary ?? "")
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

    private var dataFileSection: some View {
        Section {
            Button("Download data") { export() }
                .foregroundStyle(Theme.primaryText)

            Button("Upload data") { isImporterPresented = true }
                .foregroundStyle(Theme.primaryText)
        } header: {
            Text("Data file")
        } footer: {
            Text(
                "The file holds your expenses with their payment history, plus your base currency, "
                    + "decimals, and locations. Uploading one asks how to combine it with what is "
                    + "already on this device before anything changes."
            )
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

    private var importTitle: String {
        let count = pendingImport?.backup.expenses.count ?? 0
        return count == 1 ? "Import 1 expense from this file?" : "Import \(count) expenses from this file?"
    }

    private var replaceMessage: String {
        let local = expenses.count == 1 ? "1 expense" : "\(expenses.count) expenses"
        let syncing = settings.iCloudSyncEnabled
            ? " Because iCloud sync is on, the deletion also reaches your other devices."
            : ""
        return "This deletes the \(local) on this device and their payment history, and replaces "
            + "your base currency, decimals, and locations with the file's."
            + syncing
            + " This cannot be undone."
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

    private func export() {
        do {
            let backup = ExpenseBackupService.snapshot(expenses: expenses, settings: settings)
            exportDocument = BackupDocument(data: try BackupCodec.encode(backup))
            isExporterPresented = true
        } catch {
            fileError = error.localizedDescription
        }
    }

    private func load(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            guard url.startAccessingSecurityScopedResource() else { throw BackupError.unreadableFile }
            defer { url.stopAccessingSecurityScopedResource() }
            pendingImport = PendingImport(backup: try BackupCodec.decode(Data(contentsOf: url)))
            isImportDialogPresented = true
        } catch {
            fileError = error.localizedDescription
        }
    }

    private func apply(_ strategy: BackupMergeStrategy) {
        guard let backup = pendingImport?.backup else { return }
        pendingImport = nil

        do {
            let result = try ExpenseBackupService.apply(
                backup,
                strategy: strategy,
                existing: expenses,
                context: modelContext,
                settings: settings
            )
            importSummary = summary(for: result, strategy: strategy)
        } catch {
            fileError = error.localizedDescription
        }
    }

    private func summary(for result: BackupImportResult, strategy: BackupMergeStrategy) -> String {
        switch strategy {
        case .merge:
            "Added \(result.inserted), updated \(result.updated)."
        case .replace:
            "Replaced everything with \(result.inserted) expenses from the file."
        }
    }
}
