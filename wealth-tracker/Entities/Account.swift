import Foundation

enum AccountType {
    case creditCard(CreditCardDetails)
    case debitCard(DebitCardDetails)
    case loan(LoanDetails)
    case investment(InvestmentDetails)
}

struct Account {
    let id: UUID
    var name: String
    var bankName: String
    var type: AccountType
    var createdAt: Date
}

struct CreditCardDetails {
    var creditLimit: Decimal
    var creditUsed: Decimal
    var paymentDueDate: Date        // Day of month the payment is due
    var installmentPlans: [InstallmentPlan]

    var availableCredit: Decimal { creditLimit - creditUsed }
    var minimumPaymentToAvoidInterest: Decimal {
        installmentPlans.reduce(Decimal.zero) { $0 + $1.monthlyAmount }
    }
}

struct InstallmentPlan {
    let id: UUID
    var merchantName: String
    var totalAmount: Decimal
    var monthlyAmount: Decimal
    var totalMonths: Int
    var remainingMonths: Int
    var nextPaymentDate: Date
}

struct DebitCardDetails {
    var balance: Decimal
}

struct LoanDetails {
    var principal: Decimal
    var remainingBalance: Decimal
    var interestRate: Decimal       // Annual percentage
    var monthlyPayment: Decimal
    var nextPaymentDate: Date
    var isOwedToMe: Bool            // true = someone owes you (borrow), false = you owe (loan)
}

struct InvestmentDetails {
    var ticker: String
    var shares: Decimal
    var purchasePrice: Decimal      // Price per share at purchase
    var currentPrice: Decimal       // Updated externally
    
    var totalValue: Decimal { shares * currentPrice }
    var gainLoss: Decimal { (currentPrice - purchasePrice) * shares }
}
