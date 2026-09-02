import SwiftUI
import SwiftData

struct ExpenseFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Query private var allExpenses: [FixedExpense]

    private let expense: FixedExpense?
    private let month: Date

    @State private var name: String
    @State private var amountText: String
    @State private var currency: Currency
    @State private var frequency: ExpenseFrequency
    @State private var intervalMonths: Int
    @State private var category: ExpenseCategory
    @State private var location: ExpenseLocation
    @State private var dueDate: Date
    @State private var isPaidThisCycle: Bool
    @State private var isConfirmingDelete = false

    init(expense: FixedExpense?, month: Date) {
        self.expense = expense
        self.month = month
        _name = State(initialValue: expense?.name ?? "")
        _amountText = State(initialValue: expense.map { Self.editableAmount($0.amount) } ?? "")
        _currency = State(initialValue: expense?.currency ?? .usd)
        _frequency = State(initialValue: expense?.frequency ?? .monthly)
        _intervalMonths = State(initialValue: expense?.intervalMonths ?? 3)
        _category = State(initialValue: expense?.category ?? .utilities)
        _location = State(initialValue: expense?.location ?? .spain)
        _dueDate = State(initialValue: expense?.dueDate(in: month) ?? expense?.anchorDueDate ?? month)
        _isPaidThisCycle = State(initialValue: expense?.isPaid(in: month) ?? false)
    }

    private var isEditing: Bool { expense != nil }
    private var amount: Decimal? { Self.parseAmount(amountText) }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && (amount ?? 0) > 0 }
    private var monthName: String { month.formatted(.dateTime.month(.wide)) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledRow(label: "Name") {
                        TextField("Electricity", text: $name)
                            .foregroundStyle(Theme.primaryText)
                    }
                    LabeledRow(label: "Amount") {
                        HStack(spacing: 8) {
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .foregroundStyle(Theme.primaryText)
                            Menu {
                                Picker("Currency", selection: $currency) {
                                    ForEach(Currency.allCases) { Text($0.rawValue).tag($0) }
                                }
                            } label: {
                                HStack(spacing: 2) {
                                    Text(currency.rawValue)
                                    Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
                                }
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.secondaryText)
                            }
                        }
                    }
                }
                .listRowBackground(Theme.card)

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
                } header: {
                    Text("Frequency")
                }

                Section {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.navigationLink)

                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)

                    Picker("Location", selection: $location) {
                        ForEach(ExpenseLocation.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.navigationLink)
                }
                .listRowBackground(Theme.card)

                Section {
                    Toggle("Marked as paid", isOn: $isPaidThisCycle)
                        .listRowBackground(Theme.card)
                } header: {
                    Text("This cycle")
                } footer: {
                    Text(impactSummary)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText)
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
            .background(Theme.background)
            .navigationTitle(isEditing ? "Edit Expense" : "New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
    }

    private var impactSummary: String {
        guard let amount, amount > 0 else {
            return "Enter an amount to see how it changes \(monthName)."
        }

        let others = allExpenses.filter { $0 !== expense }
        let currentTotal = MonthPlan(expenses: allExpenses, month: month, base: settings.baseCurrency).total
        let baseTotal = MonthPlan(expenses: others, month: month, base: settings.baseCurrency).total
        let newTotal = baseTotal + draftContribution(amount: amount)
        let delta = newTotal - currentTotal

        let newTotalText = Money.string(newTotal, currency: settings.baseCurrency)
        if delta == 0 {
            return "\(monthName) total stays at \(newTotalText)."
        }
        let verb = delta > 0 ? "Adds" : "Removes"
        let direction = delta > 0 ? "to" : "from"
        return "\(verb) \(Money.string(abs(delta), currency: settings.baseCurrency)) "
            + "\(direction) \(monthName) — new total \(newTotalText)."
    }

    private func draftContribution(amount: Decimal) -> Decimal {
        let draft = FixedExpense(
            name: name,
            amount: amount,
            currency: currency,
            frequency: frequency,
            category: category,
            location: location,
            anchorDueDate: dueDate,
            intervalMonths: intervalMonths
        )
        if draft.dueDate(in: month) != nil {
            return draft.amount(in: settings.baseCurrency)
        }
        return frequency == .annual ? draft.amount(in: settings.baseCurrency) / 12 : 0
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
        target.category = category
        target.location = location
        target.anchorDueDate = dueDate
        target.setPaid(isPaidThisCycle, in: month)

        dismiss()
    }

    private func delete() {
        if let expense {
            modelContext.delete(expense)
        }
        dismiss()
    }

    private static func parseAmount(_ text: String) -> Decimal? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty else { return nil }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US"))
    }

    private static func editableAmount(_ value: Decimal) -> String {
        var rounded = Decimal()
        var source = value
        NSDecimalRound(&rounded, &source, 0, .plain)
        let digits = rounded == value ? 0 : 2
        return String(format: "%.\(digits)f", (value as NSDecimalNumber).doubleValue)
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
