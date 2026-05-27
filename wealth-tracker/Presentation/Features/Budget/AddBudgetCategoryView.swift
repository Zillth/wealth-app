import SwiftUI
import SwiftData

struct AddBudgetCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editing: BudgetCategory? = nil

    @State private var name: String
    @State private var monthlyLimit: String
    @State private var showingDeleteConfirmation = false

    init(editing: BudgetCategory? = nil) {
        self.editing    = editing
        _name           = State(initialValue: editing?.name ?? "")
        _monthlyLimit   = State(initialValue: editing.map { fmtBudget($0.monthlyLimit) } ?? "")
    }

    private var isEditing: Bool { editing != nil }
    private var isValid:   Bool { !name.isEmpty && !monthlyLimit.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Category name", text: $name)
                        .foregroundStyle(Color.appPrimary)
                        .themedRow()
                } header: {
                    ThemedSectionHeader(title: "Category")
                }

                Section {
                    CurrencyTextField(label: "Monthly limit", text: $monthlyLimit)
                        .themedRow()
                } header: {
                    ThemedSectionHeader(title: "Budget Limit")
                } footer: {
                    Text("Maximum amount you plan to spend in this category each month.")
                        .foregroundStyle(Color.appMuted)
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Text("Delete Category")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .themedRow()
                    }
                }
            }
            .themedBackground()
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
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
                "Delete \"\(editing?.name ?? "")\"?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let cat = editing { modelContext.delete(cat) }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func save() {
        let amount = Double(monthlyLimit.replacingOccurrences(of: ",", with: "")) ?? 0
        if let cat = editing {
            cat.name         = name
            cat.monthlyLimit = amount
        } else {
            modelContext.insert(BudgetCategory(name: name, monthlyLimit: amount))
        }
        dismiss()
    }
}

private func fmtBudget(_ v: Double) -> String {
    v == 0 ? "" : String(format: "%g", v)
}
