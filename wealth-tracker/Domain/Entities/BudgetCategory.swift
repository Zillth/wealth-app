import Foundation
import SwiftData

@Model
final class BudgetCategory {
    var id: UUID
    var name: String
    var monthlyLimit: Double
    var createdAt: Date

    init(name: String, monthlyLimit: Double) {
        self.id          = UUID()
        self.name        = name
        self.monthlyLimit = monthlyLimit
        self.createdAt   = Date()
    }
}
