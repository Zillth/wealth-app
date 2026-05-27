import SwiftUI
import SwiftData

struct AddInstallmentPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: AccountModel
    var editingPlan: InstallmentPlanModel? = nil

    @State private var merchantName: String
    @State private var totalAmount: String
    @State private var monthlyAmount: String
    @State private var totalMonths: String
    @State private var remainingMonths: String
    @State private var nextPaymentDate: Date
    @State private var showingDeleteConfirmation = false

    init(account: AccountModel, editingPlan: InstallmentPlanModel? = nil) {
        self.account = account
        self.editingPlan = editingPlan
        _merchantName    = State(initialValue: editingPlan?.merchantName ?? "")
        _totalAmount     = State(initialValue: editingPlan.map { fmtPlan($0.totalAmount) } ?? "")
        _monthlyAmount   = State(initialValue: editingPlan.map { fmtPlan($0.monthlyAmount) } ?? "")
        _totalMonths     = State(initialValue: editingPlan.map { String($0.totalMonths) } ?? "")
        _remainingMonths = State(initialValue: editingPlan.map { String($0.remainingMonths) } ?? "")
        _nextPaymentDate = State(initialValue: editingPlan?.nextPaymentDate ?? Date())
    }

    private var isEditing: Bool { editingPlan != nil }

    private var isValid: Bool {
        !merchantName.isEmpty &&
        Double(totalAmount.replacingOccurrences(of: ",", with: "")) != nil &&
        Double(monthlyAmount.replacingOccurrences(of: ",", with: "")) != nil &&
        Int(totalMonths) != nil &&
        Int(remainingMonths) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Merchant / Description", text: $merchantName)
                        .foregroundStyle(Color.appPrimary)
                        .themedRow()
                } header: {
                    ThemedSectionHeader(title: "Merchant")
                }

                Section {
                    CurrencyTextField(label: "Total purchase amount", text: $totalAmount)
                        .themedRow()
                    CurrencyTextField(label: "Monthly payment amount", text: $monthlyAmount)
                        .themedRow()
                } header: {
                    ThemedSectionHeader(title: "Amounts")
                }

                Section {
                    TextField("Total months", text: $totalMonths)
                        .keyboardType(.numberPad)
                        .foregroundStyle(Color.appPrimary)
                        .themedRow()
                    TextField("Remaining months", text: $remainingMonths)
                        .keyboardType(.numberPad)
                        .foregroundStyle(Color.appPrimary)
                        .themedRow()
                    DatePicker("Next payment date", selection: $nextPaymentDate, displayedComponents: .date)
                        .foregroundStyle(Color.appPrimary)
                        .themedRow()
                } header: {
                    ThemedSectionHeader(title: "Payments")
                }

                if !isEditing {
                    Section {
                        Text("This installment plan will be counted in the minimum payment you must make each month to avoid generating interest.")
                            .font(.caption)
                            .foregroundStyle(Color.appMuted)
                            .themedRow()
                    }
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Text("Delete Installment Plan")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .themedRow()
                    }
                }
            }
            .themedBackground()
            .navigationTitle(isEditing ? "Edit Installment Plan" : "Add Installment Plan")
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
                "Delete this installment plan?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let plan = editingPlan { modelContext.delete(plan) }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func save() {
        let total     = Double(totalAmount.replacingOccurrences(of: ",", with: "")) ?? 0
        let monthly   = Double(monthlyAmount.replacingOccurrences(of: ",", with: "")) ?? 0
        let months    = Int(totalMonths) ?? 0
        let remaining = Int(remainingMonths) ?? 0

        if let plan = editingPlan {
            plan.merchantName    = merchantName
            plan.totalAmount     = total
            plan.monthlyAmount   = monthly
            plan.totalMonths     = months
            plan.remainingMonths = remaining
            plan.nextPaymentDate = nextPaymentDate
        } else {
            account.installmentPlans.append(InstallmentPlanModel(
                merchantName: merchantName,
                totalAmount: total,
                monthlyAmount: monthly,
                totalMonths: months,
                remainingMonths: remaining,
                nextPaymentDate: nextPaymentDate
            ))
        }
        dismiss()
    }
}

private func fmtPlan(_ v: Double) -> String {
    v == 0 ? "" : String(format: "%g", v)
}
