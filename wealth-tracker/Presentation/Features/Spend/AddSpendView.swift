import SwiftUI
import SwiftData

struct AddSpendView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \BudgetCategory.name) private var categories: [BudgetCategory]
    @Query(sort: \AccountModel.name)   private var accounts:   [AccountModel]

    let initialDate: Date
    var editing: SpendEntry? = nil

    @State private var amount: String
    @State private var note: String
    @State private var selectedCategoryID: UUID?
    @State private var selectedAccountID: UUID?
    @State private var date: Date
    @State private var showingDeleteConfirmation = false

    init(for date: Date, editing: SpendEntry? = nil) {
        self.initialDate = date
        self.editing     = editing
        _amount              = State(initialValue: editing.map { fmtSpend($0.amount) } ?? "")
        _note                = State(initialValue: editing?.note ?? "")
        _selectedCategoryID  = State(initialValue: editing?.category?.id)
        _selectedAccountID   = State(initialValue: editing?.account?.id)
        _date                = State(initialValue: editing?.date ?? date)
    }

    private var isEditing: Bool { editing != nil }

    private var isValid: Bool {
        (Double(amount.replacingOccurrences(of: ",", with: "")) ?? 0) > 0
        && selectedCategoryID != nil
        && selectedAccountID  != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                // Amount + note
                Section {
                    CurrencyTextField(label: "Amount", text: $amount)
                        .themedRow()
                    TextField("Note (optional)", text: $note)
                        .foregroundStyle(Color.appPrimary)
                        .themedRow()
                } header: {
                    ThemedSectionHeader(title: "Spend")
                }

                // Category & account pickers
                Section {
                    Picker("Category", selection: $selectedCategoryID) {
                        Text("Select a category").tag(nil as UUID?)
                        ForEach(categories) { cat in
                            Text(cat.name).tag(cat.id as UUID?)
                        }
                    }
                    .foregroundStyle(Color.appPrimary)
                    .themedRow()

                    Picker("Account", selection: $selectedAccountID) {
                        Text("Select an account").tag(nil as UUID?)
                        ForEach(accounts) { acc in
                            Text(acc.name).tag(acc.id as UUID?)
                        }
                    }
                    .foregroundStyle(Color.appPrimary)
                    .themedRow()
                } header: {
                    ThemedSectionHeader(title: "Details")
                }

                // Date picker
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .foregroundStyle(Color.appPrimary)
                        .themedRow()
                } header: {
                    ThemedSectionHeader(title: "Date")
                }

                // Delete (edit mode)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Text("Delete Spend")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .themedRow()
                    }
                }
            }
            .themedBackground()
            .navigationTitle(isEditing ? "Edit Spend" : "Add Spend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .tint(Color.appMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .confirmationDialog(
                "Delete this spend?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let s = editing {
                        s.account?.reverseSpend(s.amount)   // undo account effect
                        modelContext.delete(s)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func save() {
        let amt = Double(amount.replacingOccurrences(of: ",", with: "")) ?? 0
        let cat = categories.first { $0.id == selectedCategoryID }
        let acc = accounts.first   { $0.id == selectedAccountID  }

        if let spend = editing {
            // Reverse the old account effect, then apply the new one
            spend.account?.reverseSpend(spend.amount)
            acc?.applySpend(amt)

            spend.amount   = amt
            spend.note     = note
            spend.date     = date
            spend.category = cat
            spend.account  = acc
        } else {
            let entry = SpendEntry(amount: amt, date: date, note: note)
            entry.category = cat
            entry.account  = acc
            modelContext.insert(entry)

            acc?.applySpend(amt)   // debit balance / increase credit used
        }
        dismiss()
    }
}

private func fmtSpend(_ v: Double) -> String {
    v == 0 ? "" : String(format: "%g", v)
}
