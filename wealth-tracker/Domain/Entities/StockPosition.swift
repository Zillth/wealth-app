import Foundation
import SwiftData

@Model
final class StockPosition {
    var id: UUID
    var ticker: String
    var shares: Double
    var avgCost: Double
    var currentPrice: Double
    var logoURL: String

    init(ticker: String, shares: Double, avgCost: Double) {
        self.id = UUID()
        self.ticker = ticker
        self.shares = shares
        self.avgCost = avgCost
        self.currentPrice = 0
        self.logoURL = ""
    }

    var totalValue: Double { shares * currentPrice }
    var gainLoss: Double { (currentPrice - avgCost) * shares }
    var roi: Double {
        guard avgCost > 0 else { return 0 }
        return (currentPrice - avgCost) / avgCost
    }
}
