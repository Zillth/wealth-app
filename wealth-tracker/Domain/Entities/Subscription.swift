import Foundation
import SwiftData

@Model
final class SubscriptionModel {
    var id: UUID
    var serviceName: String
    var monthlyAmount: Double

    init(serviceName: String, monthlyAmount: Double) {
        self.id            = UUID()
        self.serviceName   = serviceName
        self.monthlyAmount = monthlyAmount
    }
}
