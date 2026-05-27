import Foundation
import SwiftData

enum AccountTypeEnum: String, CaseIterable, Codable {
    case creditCard  = "creditCard"
    case debitCard   = "debitCard"
    case loan        = "loan"
    case investment  = "investment"
    case smartCash   = "smartCash"

    var displayName: String {
        switch self {
        case .creditCard:  return "Credit Card"
        case .debitCard:   return "Debit Card"
        case .loan:        return "Loan / Borrow"
        case .investment:  return "Investment"
        case .smartCash:   return "Smart Cash"
        }
    }

    var icon: String {
        switch self {
        case .creditCard:  return "creditcard"
        case .debitCard:   return "banknote"
        case .loan:        return "arrow.left.arrow.right"
        case .investment:  return "chart.line.uptrend.xyaxis"
        case .smartCash:   return "sparkles"
        }
    }

    var color: String {
        switch self {
        case .creditCard:  return "blue"
        case .debitCard:   return "green"
        case .loan:        return "orange"
        case .investment:  return "purple"
        case .smartCash:   return "teal"
        }
    }
}

@Model
final class AccountModel {
    var id: UUID
    var name: String
    var bankName: String
    var accountTypeRaw: String
    var createdAt: Date

    // Credit card
    var creditLimit: Double
    var creditUsed: Double
    var paymentDueDayOfMonth: Int

    // Debit / Smart Cash
    var balance: Double

    // Loan / Borrow
    var principal: Double
    var remainingBalance: Double
    var interestRate: Double       // also reused as yearly gain rate for Smart Cash
    var monthlyPayment: Double
    var nextPaymentDate: Date?
    var isOwedToMe: Bool

    // Legacy single-position investment fields (unused — positions array used instead)
    var ticker: String
    var shares: Double
    var purchasePrice: Double
    var currentPrice: Double

    @Relationship(deleteRule: .cascade) var installmentPlans: [InstallmentPlanModel]
    @Relationship(deleteRule: .cascade) var subscriptions: [SubscriptionModel]
    @Relationship(deleteRule: .cascade) var positions: [StockPosition]

    init(name: String, bankName: String, accountTypeRaw: String) {
        self.id                  = UUID()
        self.name                = name
        self.bankName            = bankName
        self.accountTypeRaw      = accountTypeRaw
        self.createdAt           = Date()
        self.creditLimit         = 0
        self.creditUsed          = 0
        self.paymentDueDayOfMonth = 1
        self.balance             = 0
        self.principal           = 0
        self.remainingBalance    = 0
        self.interestRate        = 0
        self.monthlyPayment      = 0
        self.isOwedToMe          = false
        self.ticker              = ""
        self.shares              = 0
        self.purchasePrice       = 0
        self.currentPrice        = 0
        self.installmentPlans    = []
        self.subscriptions       = []
        self.positions           = []
    }

    // MARK: - Computed

    var accountType: AccountTypeEnum {
        AccountTypeEnum(rawValue: accountTypeRaw) ?? .debitCard
    }

    var availableCredit: Double { creditLimit - creditUsed }

    var minimumPaymentToAvoidInterest: Double {
        installmentPlans.reduce(0) { $0 + $1.monthlyAmount } +
        subscriptions.reduce(0)    { $0 + $1.monthlyAmount }
    }

    // Investment
    var investmentTotalValue: Double { positions.reduce(0) { $0 + $1.totalValue } }
    var investmentGainLoss: Double   { positions.reduce(0) { $0 + $1.gainLoss   } }
    var investmentCostBasis: Double  { positions.reduce(0) { $0 + $1.shares * $1.avgCost } }
    var investmentROI: Double {
        guard investmentCostBasis > 0 else { return 0 }
        return investmentGainLoss / investmentCostBasis
    }

    // Smart Cash (reuses `balance` + `interestRate`)
    var smartCashYearlyGains: Double  { balance * interestRate }
    var smartCashMonthlyGains: Double { smartCashYearlyGains / 12 }

    // MARK: - Spend mutations

    /// Applies a spend to this account (deducts from balance or increases credit used).
    func applySpend(_ amount: Double) {
        switch accountType {
        case .creditCard:              creditUsed += amount
        case .debitCard, .smartCash:   balance    -= amount
        case .loan, .investment:       break
        }
    }

    /// Reverses a previously applied spend (used on edit or delete).
    func reverseSpend(_ amount: Double) {
        switch accountType {
        case .creditCard:              creditUsed -= amount
        case .debitCard, .smartCash:   balance    += amount
        case .loan, .investment:       break
        }
    }
}
