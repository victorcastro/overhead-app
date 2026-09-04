import SwiftUI
import SwiftData

struct ExpenseFormView: View {
    private static let amountLimit: Decimal = 1_000_000

    private enum Field {
        case name
        case amount
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    private let expense: FixedExpense?
    private let month: Date
    private let showsCancelButton: Bool

    @State private var name: String
    @State private var amountText: String
    @State private var currency: Currency
    @State private var frequency: ExpenseFrequency
    @State private var intervalMonths: Int
    @State private var endRule: ExpenseEndRule
    @State private var endOccurrences: Int
    @State private var endDate: Date
    @State private var category: ExpenseCategory
    @State private var location: String
    @State private var dueDate: Date
    @State private var isConfirmingDelete = false
    @State private var didAppear = false
    @FocusState private var focusedField: Field?

    private var isEditing: Bool { expense != nil }
    private var amount: Decimal? { AmountInput.parse(amountText, for: currency) }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && (amount ?? 0) > 0 }

    private var sortedLocationCodes: [String] {
        settings.locationCodes.sorted {
            (Location.name(for: $0) ?? $0).localizedStandardCompare(Location.name(for: $1) ?? $1) == .orderedAscending
        }
    }

    private var activeEndRule: ExpenseEndRule {
        frequency == .oneTime ? .never : endRule
    }

    private var endSummary: String? { ExpenseSummary.end(draft(amount: amount ?? 1)) }

    private var frequencySummary: String { ExpenseSummary.frequency(draft(amount: amount ?? 1)) }

    init(expense: FixedExpense?, month: Date, showsCancelButton: Bool = true) {
        self.expense = expense
        self.month = month
        self.showsCancelButton = showsCancelButton
        _name = State(initialValue: expense?.name ?? "")
        let resolvedCurrency = expense?.currency ?? .usd
        _amountText = State(initialValue: expense.map { AmountInput.editable($0.amount, for: resolvedCurrency) } ?? "")
        _currency = State(initialValue: resolvedCurrency)
        _frequency = State(initialValue: expense?.frequency ?? .monthly)
        _intervalMonths = State(initialValue: expense?.intervalMonths ?? 3)
        _endRule = State(initialValue: expense?.endRule ?? .never)
        _endOccurrences = State(initialValue: expense?.endOccurrences ?? 12)
        let anchor = expense?.anchorDueDate ?? month
        _endDate = State(
            initialValue: expense?.endDate ?? Calendar.current.date(byAdding: .year, value: 1, to: anchor) ?? anchor
        )
        _category = State(initialValue: expense?.category ?? .utilities)
        _location = State(initialValue: expense?.location ?? "")
        _dueDate = State(initialValue: expense?.dueDate(in: month) ?? expense?.anchorDueDate ?? month)
    }

    private var amountFontSize: CGFloat {
        switch amountText.count {
        case ...7: 56
        case 8...9: 48
        case 10: 42
        default: 36
        }
    }

    private var currencyMenu: some View {
        Menu {
            Picker("Currency", selection: $currency) {
                ForEach(Currency.allCases) { Text($0.rawValue).tag($0) }
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(currency.format.symbol)
                    .font(.system(size: amountFontSize * 0.6, weight: .semibold, design: .rounded))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(Theme.secondaryText)
        }
    }

    private var amountField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if currency.format.symbolPosition == .leading {
                currencyMenu
            }

            TextField("0", text: $amountText)
                .keyboardType(.decimalPad)
                .font(.system(size: amountFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.primaryText)
                .focused($focusedField, equals: .amount)
                .textFieldStyle(.plain)
                .fixedSize()
                .onChange(of: amountText) { oldValue, newValue in
                    amountText = AmountInput.accepted(newValue, for: currency, limit: Self.amountLimit) ?? oldValue
                }
                .onChange(of: currency) {
                    amountText = AmountInput.accepted(amountText, for: currency, limit: Self.amountLimit) ?? amountText
                }

            if currency.format.symbolPosition == .trailing {
                currencyMenu
            }
        }
    }

    private var amountHeader: some View {
        amountField
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { focusedField = .amount }
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.bottom, 8)
    }

    var body: some View {
        Form {
            Section {
                amountHeader
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listSectionSpacing(8)

            Section {
                Picker("Frequency", selection: $frequency) {
                    ForEach(ExpenseFrequency.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                if frequency == .other {
                    Stepper("Every \(intervalMonths) months", value: $intervalMonths, in: 2...36)
                        .listRowBackground(Theme.card)
                }
            } footer: {
                Text(frequencySummary)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
            }

            Section {
                LabeledRow(label: "Name") {
                    TextField("", text: $name)
                        .foregroundStyle(Theme.primaryText)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.done)
                }
            }
            .listRowBackground(Theme.card)

            Section {
                DatePicker("Due date", selection: $dueDate, displayedComponents: .date)

                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.navigationLink)

                if settings.hasLocations {
                    Picker("Location", selection: $location) {
                        Text("None").tag("")
                        ForEach(sortedLocationCodes, id: \.self) { code in
                            Text(Location.name(for: code) ?? code).tag(code)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            .listRowBackground(Theme.card)

            if frequency != .oneTime {
                Section {
                    Picker("Ends", selection: $endRule) {
                        ForEach(ExpenseEndRule.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.navigationLink)

                    if endRule == .afterOccurrences {
                        Stepper("Repetitions: \(endOccurrences)", value: $endOccurrences, in: 1...240)
                    }

                    if endRule == .onDate {
                        DatePicker("Last due date", selection: $endDate, displayedComponents: .date)
                    }
                } footer: {
                    if let endSummary {
                        Text(endSummary)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .listRowBackground(Theme.card)
            }

            if isEditing {
                Section {
                    Button("Delete expense", role: .destructive) {
                        isConfirmingDelete = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(Theme.destructive)
                }
                .listRowBackground(Theme.card)
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .contentMargins(.top, 0, for: .scrollContent)
        .background(Theme.background)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCancelButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
            }
        }
        .confirmationDialog(
            "Delete this expense?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete expense", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It will be removed from every month, including the ones already recorded.")
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .onAppear {
            guard !didAppear else { return }
            didAppear = true

            if !location.isEmpty, !settings.locationCodes.contains(location) {
                location = ""
            }
            if !isEditing {
                currency = settings.baseCurrency
                if location.isEmpty, settings.locationCodes.count == 1 {
                    location = settings.locationCodes[0]
                }
                focusedField = .amount
            }
        }
    }

    private func draft(amount: Decimal) -> FixedExpense {
        FixedExpense(
            name: name,
            amount: amount,
            currency: currency,
            frequency: frequency,
            category: category,
            location: location,
            anchorDueDate: dueDate,
            intervalMonths: intervalMonths,
            endRule: activeEndRule,
            endOccurrences: endOccurrences,
            endDate: activeEndRule == .onDate ? endDate : nil
        )
    }

    private func save() {
        guard let amount else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        let target = expense ?? {
            let created = FixedExpense(name: trimmedName, amount: amount, anchorDueDate: dueDate)
            modelContext.insert(created)
            return created
        }()

        target.name = trimmedName
        target.amount = amount
        target.currency = currency
        target.frequency = frequency
        target.intervalMonths = intervalMonths
        target.endRule = activeEndRule
        target.endOccurrences = endOccurrences
        target.endDate = activeEndRule == .onDate ? endDate : nil
        target.category = category
        target.location = location
        target.anchorDueDate = dueDate

        dismiss()
    }

    private func delete() {
        if let expense {
            modelContext.delete(expense)
        }
        dismiss()
    }
}

struct LabeledRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .frame(width: 96, alignment: .leading)
                .foregroundStyle(Theme.primaryText)
            content
        }
    }
}
