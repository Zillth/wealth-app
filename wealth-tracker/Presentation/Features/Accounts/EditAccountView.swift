import SwiftUI
import SwiftData

struct EditAccountView: View {
    @Bindable var account: AccountModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var bankName: String

    // Credit card
    @State private var creditLimit: String
    @State private var creditUsed: String
    @State private var paymentDueDayOfMonth: Int

    // Debit card
    @State private var balance: String

    // Loan
    @State private var isOwedToMe: Bool
    @State private var principal: String
    @State private var remainingBalance: String

    // Smart Cash
    @State private var smartCashAmount: String
    @State private var smartCashRate: String   // displayed as percentage, e.g. "15"

    init(account: AccountModel) {
        self.account = account
        _name                 = State(initialValue: account.name)
        _bankName             = State(initialValue: account.bankName)
        _creditLimit          = State(initialValue: fmt(account.creditLimit))
        _creditUsed           = State(initialValue: fmt(account.creditUsed))
        _paymentDueDayOfMonth = State(initialValue: account.paymentDueDayOfMonth)
        _balance              = State(initialValue: fmt(account.balance))
        _isOwedToMe           = State(initialValue: account.isOwedToMe)
        _principal            = State(initialValue: fmt(account.principal))
        _remainingBalance     = State(initialValue: fmt(account.remainingBalance))
        _smartCashAmount      = State(initialValue: fmt(account.balance))
        // interestRate stored as decimal (0.15); show as "15"
        let pct = account.interestRate * 100
        _smartCashRate        = State(initialValue: pct == 0 ? "" : String(format: "%g", pct))
    }

    private var isValid: Bool { !name.isEmpty && !bankName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                generalSection
                switch account.accountType {
                case .creditCard:   creditCardSection
                case .debitCard:    debitCardSection
                case .loan:         loanSection
                case .investment:   investmentSection
                case .smartCash:    smartCashSection
                }
            }
            .themedBackground()
            .navigationTitle("Edit Account")
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
            Label("Manage positions from the account detail view.", systemImage: "info.circle")
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

    private func save() {
        account.name     = name
        account.bankName = bankName
        switch account.accountType {
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
        dismiss()
    }

    private func parse(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: "")) ?? 0
    }
}

private func fmt(_ value: Double) -> String {
    value == 0 ? "" : String(format: "%g", value)
}
