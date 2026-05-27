import Foundation
import SwiftData

@Model
final class SpendEntry {
    var id: UUID
    var amount: Double
    var date: Date
    var note: String

    @Relationship var category: BudgetCategory?
    @Relationship var account: AccountModel?

    init(amount: Double, date: Date, note: String = "") {
        self.id       = UUID()
        self.amount   = amount
        self.date     = date
        self.note     = note
    }
}
