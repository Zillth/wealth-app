import SwiftUI
import SwiftData

struct AddAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var bankName = ""
    @State private var selectedType: AccountTypeEnum = .creditCard

    // Credit card
    @State private var creditLimit = ""
    @State private var creditUsed = ""
    @State private var paymentDueDayOfMonth = 1

    // Debit card
    @State private var balance = ""

    // Loan / Borrow
    @State private var isOwedToMe = false
    @State private var principal = ""
    @State private var remainingBalance = ""

    // Smart Cash
    @State private var smartCashAmount = ""
    @State private var smartCashRate = ""    // entered as percentage, e.g. "15"

    private var isValid: Bool { !name.isEmpty && !bankName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                generalSection
                switch selectedType {
                case .creditCard:   creditCardSection
                case .debitCard:    debitCardSection
                case .loan:         loanSection
                case .investment:   investmentSection
                case .smartCash:    smartCashSection
                }
            }
            .themedBackground()
            .navigationTitle("Add Account")
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
        }
    }

    private var generalSection: some View {
        Section {
            TextField("Account name", text: $name)
                .foregroundStyle(Color.appPrimary)
                .themedRow()
            TextField("Bank / Institution", text: $bankName)
                .foregroundStyle(Color.appPrimary)
                .themedRow()
            Picker("Account type", selection: $selectedType) {
                ForEach(AccountTypeEnum.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon).tag(type)
                }
            }
            .foregroundStyle(Color.appPrimary)
            .themedRow()
        } header: {
            ThemedSectionHeader(title: "Account Info")
        }
    }

    private var creditCardSection: some View {
        Section {
            CurrencyTextField(label: "Credit limit", text: $creditLimit)
                .themedRow()
            CurrencyTextField(label: "Current balance used", text: $creditUsed)
                .themedRow()
            Stepper(
                "Payment due: day \(paymentDueDayOfMonth)",
                value: $paymentDueDayOfMonth, in: 1...31
            )
            .foregroundStyle(Color.appPrimary)
            .themedRow()
        } header: {
            ThemedSectionHeader(title: "Credit Card Details")
        } footer: {
            Text("After saving, open the account to add interest-free installment plans (MSI).")
                .foregroundStyle(Color.appMuted)
        }
    }

    private var debitCardSection: some View {
        Section {
            CurrencyTextField(label: "Current balance", text: $balance)
                .themedRow()
        } header: {
            ThemedSectionHeader(title: "Debit Card Details")
        }
    }

    private var loanSection: some View {
        Section {
            Toggle("Someone owes me (I lent money)", isOn: $isOwedToMe)
                .foregroundStyle(Color.appPrimary)
                .themedRow()
            CurrencyTextField(label: "Original amount", text: $principal)
                .themedRow()
            CurrencyTextField(label: "Remaining balance", text: $remainingBalance)
                .themedRow()
        } header: {
            ThemedSectionHeader(title: "Loan / Borrow Details")
        }
    }

    private var investmentSection: some View {
        Section {
            Label("Add stock positions after saving the account.", systemImage: "info.circle")
                .font(.subheadline)
                .foregroundStyle(Color.appMuted)
                .themedRow()
        } header: {
            ThemedSectionHeader(title: "Investment")
        }
    }

    private var smartCashSection: some View {
        Section {
            CurrencyTextField(label: "Current amount", text: $smartCashAmount)
                .themedRow()
            HStack {
                Text("Yearly gain rate")
                    .foregroundStyle(Color.appPrimary)
                Spacer()
                TextField("e.g. 15", text: $smartCashRate)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 70)
                Text("%")
                    .foregroundStyle(Color.appMuted)
            }
            .themedRow()
        } header: {
            ThemedSectionHeader(title: "Smart Cash Details")
        } footer: {
            Text("Enter the annual interest rate as a number, e.g. 15 for 15%.")
                .foregroundStyle(Color.appMuted)
        }
    }

    private func parse(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private func save() {
        let account = AccountModel(name: name, bankName: bankName, accountTypeRaw: selectedType.rawValue)
        switch selectedType {
        case .creditCard:
            account.creditLimit          = parse(creditLimit)
            account.creditUsed           = parse(creditUsed)
            account.paymentDueDayOfMonth = paymentDueDayOfMonth
        case .debitCard:
            account.balance = parse(balance)
        case .loan:
            account.isOwedToMe       = isOwedToMe
            account.principal        = parse(principal)
            account.remainingBalance = parse(remainingBalance)
        case .investment:
            break
        case .smartCash:
            account.balance      = parse(smartCashAmount)
            account.interestRate = (Double(smartCashRate) ?? 0) / 100
        }
        modelContext.insert(account)
        dismiss()
    }
}
