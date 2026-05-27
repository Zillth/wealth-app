import SwiftUI
import SwiftData

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: AccountModel
    var editingSubscription: SubscriptionModel? = nil

    @State private var serviceName: String
    @State private var monthlyAmount: String
    @State private var showingDeleteConfirmation = false

    init(account: AccountModel, editingSubscription: SubscriptionModel? = nil) {
        self.account = account
        self.editingSubscription = editingSubscription
        _serviceName   = State(initialValue: editingSubscription?.serviceName ?? "")
        _monthlyAmount = State(initialValue: editingSubscription.map { fmt($0.monthlyAmount) } ?? "")
    }

    private var isEditing: Bool { editingSubscription != nil }
    private var isValid:   Bool { !serviceName.isEmpty && !monthlyAmount.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Service name", text: $serviceName)
                        .foregroundStyle(Color.appPrimary)
                        .themedRow()
                } header: {
                    ThemedSectionHeader(title: "Service")
                }

                Section {
                    CurrencyTextField(label: "Monthly amount", text: $monthlyAmount)
                        .themedRow()
                } header: {
                    ThemedSectionHeader(title: "Amount")
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Text("Delete Subscription")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .themedRow()
                    }
                }
            }
            .themedBackground()
            .navigationTitle(isEditing ? "Edit Subscription" : "Add Subscription")
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
                "Delete this subscription?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let sub = editingSubscription { modelContext.delete(sub) }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func save() {
        let amount = Double(monthlyAmount.replacingOccurrences(of: ",", with: "")) ?? 0
        if let sub = editingSubscription {
            sub.serviceName   = serviceName
            sub.monthlyAmount = amount
        } else {
            account.subscriptions.append(SubscriptionModel(serviceName: serviceName, monthlyAmount: amount))
        }
        dismiss()
    }
}

private func fmt(_ v: Double) -> String {
    v == 0 ? "" : String(format: "%g", v)
}
