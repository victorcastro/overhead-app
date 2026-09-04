import SwiftUI
import SwiftData

struct LocationSettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [FixedExpense]

    @State private var query = ""
    @State private var pendingDeletion: PendingDeletion?

    private struct PendingDeletion: Identifiable {
        let code: String
        let count: Int
        var id: String { code }
    }

    private var selectedCountries: [CountryCatalog.Country] {
        settings.locationCodes
            .map { code in
                CountryCatalog.Country(code: code, name: Location.name(for: code) ?? code)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var searchResults: [CountryCatalog.Country] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let existing = Set(settings.locationCodes)
        return CountryCatalog.all.filter { country in
            !existing.contains(country.code)
                && country.name.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    var body: some View {
        List {
            Section {
                if selectedCountries.isEmpty {
                    Text("No locations yet. Search below to add countries.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    ForEach(selectedCountries) { country in
                        Text(country.name)
                            .foregroundStyle(Theme.primaryText)
                    }
                    .onDelete(perform: requestDelete)
                }
            } header: {
                Text("Your locations")
                    .textCase(nil)
            } footer: {
                Text("Deleting a location moves any expense using it back to Undefined.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
            }
            .listRowBackground(Theme.card)

            if !searchResults.isEmpty {
                Section {
                    ForEach(searchResults) { country in
                        Button {
                            settings.locationCodes.append(country.code)
                            query = ""
                        } label: {
                            HStack {
                                Text(country.name)
                                    .foregroundStyle(Theme.primaryText)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                    }
                } header: {
                    Text("Add a country")
                        .textCase(nil)
                }
                .listRowBackground(Theme.card)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .searchable(text: $query, prompt: "Search countries")
        .navigationTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete this location?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingDeletion
        ) { deletion in
            Button("Delete", role: .destructive) { performDelete(deletion.code) }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: { deletion in
            Text("\(deletion.count) \(deletion.count == 1 ? "expense" : "expenses") will move to Undefined.")
        }
    }

    private func requestDelete(_ offsets: IndexSet) {
        let codes = offsets.map { selectedCountries[$0].code }
        guard let code = codes.first else { return }
        let count = expenses.filter { $0.location == code }.count
        if count == 0 {
            performDelete(code)
        } else {
            pendingDeletion = PendingDeletion(code: code, count: count)
        }
    }

    private func performDelete(_ code: String) {
        settings.locationCodes.removeAll { $0 == code }
        for expense in expenses where expense.location == code {
            expense.location = ""
        }
        pendingDeletion = nil
    }
}
