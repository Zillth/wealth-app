import SwiftUI
import SwiftData

struct AccountListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AccountModel.createdAt, order: .reverse) private var accounts: [AccountModel]
    @State private var showingAddAccount = false

    // Computed once per query update — one O(n) pass instead of one filter per type
    private var groupedAccounts: [AccountTypeEnum: [AccountModel]] {
        Dictionary(grouping: accounts) { AccountTypeEnum(rawValue: $0.accountTypeRaw) ?? .debitCard }
    }

    var body: some View {
        NavigationStack {
            Group {
                if accounts.isEmpty {
                    emptyState
                } else {
                    accountList
                }
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddAccount = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "creditcard")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.appMuted)
                Text("No Accounts")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                Text("Tap + to add your first account.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appMuted)
            }
        }
    }

    // MARK: - Net Worth

    private var netWorth: Double {
        accounts.reduce(0.0) { sum, account in
            switch account.accountType {
            case .debitCard:    return sum + account.balance
            case .smartCash:    return sum + account.balance
            case .investment:   return sum + account.investmentTotalValue
            case .creditCard:   return sum - account.creditUsed
            case .loan:         return account.isOwedToMe
                                    ? sum + account.remainingBalance
                                    : sum - account.remainingBalance
            }
        }
    }

    private var netWorthCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NET WORTH")
                .font(.system(size: 10, weight: .regular))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.5))
            Text(netWorth, format: .currency(code: AccountRowView.currencyCode))
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 38)
        .listRowBackground(Color(hex: "433D3D"))
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }

    // MARK: - Account List

    private var accountList: some View {
        let grouped = groupedAccounts
        return List {
            Section { netWorthCard }
            ForEach(AccountTypeEnum.allCases, id: \.self) { type in
                if let group = grouped[type], !group.isEmpty {
                    Section {
                        ForEach(group) { account in
                            AccountRowView(account: account)
                                .themedRow()
                        }
                        .onDelete { offsets in
                            deleteAccounts(group, at: offsets)
                        }
                    } header: {
                        ThemedSectionHeader(title: type.displayName)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .themedBackground()
    }

    private func deleteAccounts(_ group: [AccountModel], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(group[index])
        }
    }
}

// MARK: - Account Row

struct AccountRowView: View {
    let account: AccountModel

    // Resolved once at type level — Locale doesn't change during a session
    static let currencyCode: String = Locale.current.currency?.identifier ?? "MXN"

    var body: some View {
        NavigationLink(destination: AccountDetailView(account: account)) {
            HStack(spacing: 14) {
                AccountTypeIcon(systemName: account.accountType.icon)
                accountInfo
                Spacer(minLength: 8)
                primaryValueView
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: Account info

    private var accountInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(account.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
            Text(account.bankName)
                .font(.caption)
                .foregroundStyle(Color.appMuted)
        }
    }

    // MARK: Primary value

    private var primaryValueView: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(primaryValue, format: .currency(code: Self.currencyCode))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primaryValueColor)
            switch account.accountType {
            case .investment:
                Text(account.investmentROI, format: .percent.precision(.fractionLength(2)))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(account.investmentROI >= 0 ? Color.appPositive : Color.appNegative)
            case .smartCash:
                Text(account.interestRate, format: .percent.precision(.fractionLength(2)))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.appPositive)
            default:
                Text(primaryLabel)
                    .font(.caption)
                    .foregroundStyle(Color.appMuted)
            }
        }
    }

    private var primaryValue: Double {
        switch account.accountType {
        case .creditCard:   return account.creditUsed
        case .debitCard:    return account.balance
        case .smartCash:    return account.balance
        case .loan:         return account.remainingBalance
        case .investment:   return account.investmentTotalValue
        }
    }

    private var primaryLabel: String {
        switch account.accountType {
        case .creditCard:   return "Used"
        case .debitCard:    return "Balance"
        case .smartCash:    return "Balance"
        case .loan:         return account.isOwedToMe ? "They owe you" : "You owe"
        case .investment:   return "Value"
        }
    }

    private var primaryValueColor: Color {
        switch account.accountType {
        case .creditCard:   return .appNegative
        case .debitCard:    return .appPositive
        case .smartCash:    return .appPositive
        case .loan:         return account.isOwedToMe ? .appPositive : .appNegative
        case .investment:   return account.investmentGainLoss >= 0 ? .appPositive : .appNegative
        }
    }
}
