import Foundation

/// Defines the contract for all spend-entry persistence operations.
protocol SpendRepositoryProtocol {
    func fetchAll() -> [SpendEntry]
    func add(_ entry: SpendEntry)
    func delete(_ entry: SpendEntry)
}
