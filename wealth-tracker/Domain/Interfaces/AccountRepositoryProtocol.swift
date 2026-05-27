import Foundation

/// Defines the contract for all account persistence operations.
/// Concrete implementations live in Data/Repositories/.
protocol AccountRepositoryProtocol {
    func fetchAll() -> [AccountModel]
    func add(_ account: AccountModel)
    func delete(_ account: AccountModel)
}
