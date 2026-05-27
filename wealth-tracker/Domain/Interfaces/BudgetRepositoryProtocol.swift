import Foundation

/// Defines the contract for all budget-category persistence operations.
protocol BudgetRepositoryProtocol {
    func fetchAll() -> [BudgetCategory]
    func add(_ category: BudgetCategory)
    func delete(_ category: BudgetCategory)
}
