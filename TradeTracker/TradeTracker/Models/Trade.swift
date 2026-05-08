import Foundation
import SwiftData

@Model
final class Trade {
    var ticker: String
    var sectorRaw: String
    var typeRaw: String
    var goalRaw: String
    var priceTarget: Double
    var stopPrice: Double
    var buyDate: Date

    @Relationship(deleteRule: .cascade, inverse: \Purchase.trade)
    var purchases: [Purchase] = []

    init(
        ticker: String,
        sector: Sector,
        type: TickerType,
        goal: TradeGoal,
        priceTarget: Double,
        stopPrice: Double,
        buyDate: Date = .now
    ) {
        self.ticker = ticker.uppercased()
        self.sectorRaw = sector.rawValue
        self.typeRaw = type.rawValue
        self.goalRaw = goal.rawValue
        self.priceTarget = priceTarget
        self.stopPrice = stopPrice
        self.buyDate = buyDate
    }

    var sector: Sector { Sector(rawValue: sectorRaw) ?? .other }
    var type: TickerType { TickerType(rawValue: typeRaw) ?? .stock }
    var goal: TradeGoal { TradeGoal(rawValue: goalRaw) ?? .growthRightSide }

    var totalQuantity: Double {
        purchases.reduce(0) { $0 + $1.quantity }
    }

    var totalCost: Double {
        purchases.reduce(0) { $0 + $1.price * $1.quantity }
    }

    var averageBuyPrice: Double {
        let qty = totalQuantity
        return qty > 0 ? totalCost / qty : 0
    }
}
