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

    // Debit card
    var balance: Double

    // Loan / Borrow
    var principal: Double
    var remainingBalance: Double
    var interestRate: Double
    var monthlyPayment: Double
    var nextPaymentDate: Date?
    var isOwedToMe: Bool

    // Investment
    var ticker: String
    var shares: Double
    var purchasePrice: Double
    var currentPrice: Double

    @Relationship(deleteRule: .cascade)
    var installmentPlans: [InstallmentPlanModel]

    @Relationship(deleteRule: .cascade)
    var subscriptions: [SubscriptionModel]

    @Relationship(deleteRule: .cascade)
    var positions: [StockPosition]

    init(name: String, bankName: String, accountTypeRaw: String) {
        self.id = UUID()
        self.name = name
        self.bankName = bankName
        self.accountTypeRaw = accountTypeRaw
        self.createdAt = Date()
        self.creditLimit = 0
        self.creditUsed = 0
        self.paymentDueDayOfMonth = 1
        self.balance = 0
        self.principal = 0
        self.remainingBalance = 0
        self.interestRate = 0
        self.monthlyPayment = 0
        self.isOwedToMe = false
        self.ticker = ""
        self.shares = 0
        self.purchasePrice = 0
        self.currentPrice = 0
        self.installmentPlans = []
        self.subscriptions = []
        self.positions = []
    }

    var accountType: AccountTypeEnum {
        AccountTypeEnum(rawValue: accountTypeRaw) ?? .debitCard
    }

    var availableCredit: Double { creditLimit - creditUsed }

    var minimumPaymentToAvoidInterest: Double {
        installmentPlans.reduce(0) { $0 + $1.monthlyAmount } +
        subscriptions.reduce(0)    { $0 + $1.monthlyAmount }
    }

    var investmentTotalValue: Double { positions.reduce(0) { $0 + $1.totalValue } }
    var investmentGainLoss: Double { positions.reduce(0) { $0 + $1.gainLoss } }
    var investmentCostBasis: Double { positions.reduce(0) { $0 + $1.shares * $1.avgCost } }
    var investmentROI: Double {
        guard investmentCostBasis > 0 else { return 0 }
        return investmentGainLoss / investmentCostBasis
    }

    // Smart Cash — reuses `balance` (amount) and `interestRate` (yearly rate as decimal, e.g. 0.15 = 15%)
    var smartCashYearlyGains: Double  { balance * interestRate }
    var smartCashMonthlyGains: Double { smartCashYearlyGains / 12 }
}

@Model
final class SubscriptionModel {
    var id: UUID
    var serviceName: String
    var monthlyAmount: Double

    init(serviceName: String, monthlyAmount: Double) {
        self.id = UUID()
        self.serviceName = serviceName
        self.monthlyAmount = monthlyAmount
    }
}

@Model
final class InstallmentPlanModel {
    var id: UUID
    var merchantName: String
    var totalAmount: Double
    var monthlyAmount: Double
    var totalMonths: Int
    var remainingMonths: Int
    var nextPaymentDate: Date

    init(
        merchantName: String,
        totalAmount: Double,
        monthlyAmount: Double,
        totalMonths: Int,
        remainingMonths: Int,
        nextPaymentDate: Date
    ) {
        self.id = UUID()
        self.merchantName = merchantName
        self.totalAmount = totalAmount
        self.monthlyAmount = monthlyAmount
        self.totalMonths = totalMonths
        self.remainingMonths = remainingMonths
        self.nextPaymentDate = nextPaymentDate
    }
}
