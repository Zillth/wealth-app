import SwiftUI
import SwiftData

struct AccountDetailView: View {
    @Bindable var account: AccountModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddInstallmentPlan = false
    @State private var showingAddSubscription = false
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAddPosition = false
    @State private var editingPosition: StockPosition?
    @State private var editingSubscription: SubscriptionModel?
    @State private var editingInstallmentPlan: InstallmentPlanModel?

    private var currency: String {
        Locale.current.currency?.identifier ?? "MXN"
    }

    var body: some View {
        List {
            headerSection
            switch account.accountType {
            case .creditCard:   creditCardSections
            case .debitCard:    debitCardSection
            case .loan:         loanSection
            case .investment:   investmentSections
            case .smartCash:    smartCashSection
            }
        }
        .listStyle(.insetGrouped)
        .themedBackground()
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showingEditSheet = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddInstallmentPlan) {
            AddInstallmentPlanView(account: account)
        }
        .sheet(item: $editingInstallmentPlan) { plan in
            AddInstallmentPlanView(account: account, editingPlan: plan)
        }
        .sheet(isPresented: $showingAddSubscription) {
            AddSubscriptionView(account: account)
        }
        .sheet(item: $editingSubscription) { sub in
            AddSubscriptionView(account: account, editingSubscription: sub)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditAccountView(account: account)
        }
        .sheet(isPresented: $showingAddPosition) {
            AddStockPositionView(account: account)
        }
        .sheet(item: $editingPosition) { position in
            AddStockPositionView(account: account, editingPosition: position)
        }
        .confirmationDialog(
            "Delete \"\(account.name)\"?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(account)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            LabeledContent("Bank / Institution", value: account.bankName)
                .foregroundStyle(Color.appPrimary)
                .themedRow()
            LabeledContent("Account type", value: account.accountType.displayName)
                .foregroundStyle(Color.appPrimary)
                .themedRow()
        }
    }

    // MARK: - Credit Card

    @ViewBuilder
    private var creditCardSections: some View {
        Section {
            LabeledContent("Credit limit") {
                Text(account.creditLimit, format: .currency(code: currency))
                    .foregroundStyle(Color.appPrimary)
            }
            .themedRow()
            LabeledContent("Balance used") {
                Text(account.creditUsed, format: .currency(code: currency))
                    .foregroundStyle(Color.appNegative)
            }
            .themedRow()
            LabeledContent("Available credit") {
                Text(account.availableCredit, format: .currency(code: currency))
                    .foregroundStyle(Color.appPositive)
            }
            .themedRow()
            LabeledContent("Payment due day") {
                Text("Day \(account.paymentDueDayOfMonth)")
                    .foregroundStyle(Color.appPrimary)
            }
            .themedRow()
        } header: {
            ThemedSectionHeader(title: "Limits & Balance")
        }

        Section {
            HStack {
                Text("Pay to avoid interest")
                    .foregroundStyle(Color.appPrimary)
                Spacer()
                Text(account.minimumPaymentToAvoidInterest, format: .currency(code: currency))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(account.minimumPaymentToAvoidInterest > 0 ? Color(hex: "B06020") : Color.appMuted)
            }
            .themedRow()
        } header: {
            ThemedSectionHeader(title: "This Payment Cycle")
        } footer: {
            Text("Total of all monthly MSI installments and subscriptions due this cycle.")
                .foregroundStyle(Color.appMuted)
        }

        Section {
            ForEach(account.installmentPlans) { plan in
                Button { editingInstallmentPlan = plan } label: {
                    InstallmentPlanRow(plan: plan)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        modelContext.delete(plan)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .themedRow()
            Button {
                showingAddInstallmentPlan = true
            } label: {
                Label("Add Installment Plan", systemImage: "plus")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appAccent)
            }
            .themedRow()
        } header: {
            ThemedSectionHeader(title: "Interest-Free Installment Plans (MSI)")
        } footer: {
            Text("Each plan's monthly amount is counted toward the total above.")
                .foregroundStyle(Color.appMuted)
        }

        Section {
            ForEach(account.subscriptions) { sub in
                Button { editingSubscription = sub } label: {
                    SubscriptionRow(subscription: sub, currency: currency)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        modelContext.delete(sub)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .themedRow()
            Button {
                showingAddSubscription = true
            } label: {
                Label("Add Subscription", systemImage: "plus")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appAccent)
            }
            .themedRow()
        } header: {
            ThemedSectionHeader(title: "Subscriptions")
        } footer: {
            Text("Monthly recurring charges counted toward the total above.")
                .foregroundStyle(Color.appMuted)
        }
    }

    // MARK: - Debit Card

    private var debitCardSection: some View {
        Section {
            LabeledContent("Current balance") {
                Text(account.balance, format: .currency(code: currency))
                    .foregroundStyle(Color.appPositive)
            }
            .themedRow()
        } header: {
            ThemedSectionHeader(title: "Balance")
        }
    }

    // MARK: - Loan

    private var loanSection: some View {
        Section {
            LabeledContent("Direction") {
                Text(account.isOwedToMe ? "They owe you" : "You owe")
                    .foregroundStyle(account.isOwedToMe ? Color.appPositive : Color.appNegative)
            }
            .themedRow()
            LabeledContent("Original amount") {
                Text(account.principal, format: .currency(code: currency))
                    .foregroundStyle(Color.appPrimary)
            }
            .themedRow()
            LabeledContent("Remaining balance") {
                Text(account.remainingBalance, format: .currency(code: currency))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(account.isOwedToMe ? Color.appPositive : Color.appNegative)
            }
            .themedRow()
        } header: {
            ThemedSectionHeader(title: "Loan Details")
        }
    }

    // MARK: - Smart Cash

    private var smartCashSection: some View {
        Section {
            LabeledContent("Current amount") {
                Text(account.balance, format: .currency(code: currency))
                    .foregroundStyle(Color.appPositive)
            }
            .themedRow()
            LabeledContent("Yearly gain rate") {
                Text(account.interestRate, format: .percent.precision(.fractionLength(2)))
                    .foregroundStyle(Color.appPrimary)
            }
            .themedRow()
            LabeledContent("Yearly gains") {
                Text(account.smartCashYearlyGains, format: .currency(code: currency))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appPositive)
            }
            .themedRow()
            LabeledContent("Monthly gains") {
                Text(account.smartCashMonthlyGains, format: .currency(code: currency))
                    .foregroundStyle(Color.appPositive)
            }
            .themedRow()
        } header: {
            ThemedSectionHeader(title: "Smart Cash Details")
        } footer: {
            Text("Yearly gains = amount × yearly rate. Credited monthly in most smart-cash products.")
                .foregroundStyle(Color.appMuted)
        }
    }

    // MARK: - Investment

    @ViewBuilder
    private var investmentSections: some View {
        if !account.positions.isEmpty {
            Section {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total value")
                            .font(.caption)
                            .foregroundStyle(Color.appMuted)
                        Text(account.investmentTotalValue, format: .currency(code: currency))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.appPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Gain / loss")
                            .font(.caption)
                            .foregroundStyle(Color.appMuted)
                        Text(account.investmentGainLoss, format: .currency(code: currency))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(account.investmentGainLoss >= 0 ? Color.appPositive : Color.appNegative)
                        Text(account.investmentROI, format: .percent.precision(.fractionLength(2)))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(account.investmentROI >= 0 ? Color.appPositive : Color.appNegative)
                    }
                }
                .padding(.vertical, 6)
                .themedRow()
            } header: {
                ThemedSectionHeader(title: "Portfolio Summary")
            }
        }

        Section {
            ForEach(account.positions) { position in
                Button {
                    editingPosition = position
                } label: {
                    PositionRowView(position: position, currency: currency)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        modelContext.delete(position)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .themedRow()
            }
            Button {
                showingAddPosition = true
            } label: {
                Label("Add Position", systemImage: "plus")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appAccent)
            }
            .themedRow()
        } header: {
            ThemedSectionHeader(title: "Positions")
        }
    }
}

// MARK: - Position Row

struct PositionRowView: View {
    @Bindable var position: StockPosition
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            tickerIcon
            Text(position.ticker)
                .font(.headline)
                .foregroundStyle(Color.appPrimary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(position.totalValue, format: .currency(code: currency))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                Text(position.roi, format: .percent.precision(.fractionLength(2)))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(position.roi >= 0 ? Color.appPositive : Color.appNegative)
            }
        }
        .padding(.vertical, 4)
        .task {
            await fetchData()
        }
        .onChange(of: position.ticker) { _, _ in
            position.logoURL = ""
            Task { await fetchData() }
        }
    }

    private var tickerIcon: some View {
        Group {
            if position.logoURL.isEmpty {
                Circle()
                    .fill(color(for: position.ticker).gradient)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(String(position.ticker.prefix(1)))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
            } else {
                AsyncImage(url: URL(string: position.logoURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    default:
                        Circle()
                            .fill(color(for: position.ticker).gradient)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Text(String(position.ticker.prefix(1)))
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                    }
                }
            }
        }
    }

    private func color(for ticker: String) -> Color {
        let palette: [Color] = [.blue, .purple, .orange, .indigo, .teal, .pink, .cyan, .mint, .red, .green]
        let hash = ticker.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[hash % palette.count]
    }

    @MainActor
    private func fetchData() async {
        guard !position.ticker.isEmpty else { return }
        let ticker = position.ticker
        async let priceResult = StockPriceService.fetchCurrentPrice(for: ticker)
        async let logoResult  = StockPriceService.fetchLogoURL(for: ticker)
        if let p = try? await priceResult               { position.currentPrice = p }
        if let l = try? await logoResult, !l.isEmpty    { position.logoURL = l }
    }
}

// MARK: - Subscription Row

struct SubscriptionRow: View {
    let subscription: SubscriptionModel
    let currency: String

    var body: some View {
        HStack {
            Text(subscription.serviceName)
                .font(.headline)
                .foregroundStyle(Color.appPrimary)
            Spacer()
            Text(subscription.monthlyAmount, format: .currency(code: currency))
                .font(.headline)
                .foregroundStyle(Color(hex: "B06020"))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Installment Plan Row

struct InstallmentPlanRow: View {
    let plan: InstallmentPlanModel

    private var currency: String {
        Locale.current.currency?.identifier ?? "MXN"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(plan.merchantName)
                    .font(.headline)
                    .foregroundStyle(Color.appPrimary)
                Spacer()
                Text(plan.monthlyAmount, format: .currency(code: currency))
                    .font(.headline)
                    .foregroundStyle(Color(hex: "B06020"))
            }
            HStack {
                Text("\(plan.remainingMonths) of \(plan.totalMonths) payments left")
                    .font(.caption)
                    .foregroundStyle(Color.appMuted)
                Spacer()
                Text("Next: \(plan.nextPaymentDate, format: .dateTime.day().month())")
                    .font(.caption)
                    .foregroundStyle(Color.appMuted)
            }
        }
        .padding(.vertical, 2)
    }
}
