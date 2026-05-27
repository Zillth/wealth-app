import Foundation
import SwiftData

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
        self.id               = UUID()
        self.merchantName     = merchantName
        self.totalAmount      = totalAmount
        self.monthlyAmount    = monthlyAmount
        self.totalMonths      = totalMonths
        self.remainingMonths  = remainingMonths
        self.nextPaymentDate  = nextPaymentDate
    }
}
