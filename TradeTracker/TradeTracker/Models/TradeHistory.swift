import Foundation
import SwiftData

@Model
final class TradeHistory {
    var ticker: String
    var sectorRaw: String
    var typeRaw: String
    var goalRaw: String
    var averageBuyPrice: Double
    var exitPrice: Double
    var quantity: Double
    var priceTarget: Double
    var stopPrice: Double
    var buyDate: Date
    var sellDate: Date
    var isFullExit: Bool

    init(
        ticker: String,
        sector: Sector,
        type: TickerType,
        goal: TradeGoal,
        averageBuyPrice: Double,
        exitPrice: Double,
        quantity: Double,
        priceTarget: Double,
        stopPrice: Double,
        buyDate: Date,
        sellDate: Date = .now,
        isFullExit: Bool
    ) {
        self.ticker = ticker
        self.sectorRaw = sector.rawValue
        self.typeRaw = type.rawValue
        self.goalRaw = goal.rawValue
        self.averageBuyPrice = averageBuyPrice
        self.exitPrice = exitPrice
        self.quantity = quantity
        self.priceTarget = priceTarget
        self.stopPrice = stopPrice
        self.buyDate = buyDate
        self.sellDate = sellDate
        self.isFullExit = isFullExit
    }

    var sector: Sector { Sector(rawValue: sectorRaw) ?? .other }
    var type: TickerType { TickerType(rawValue: typeRaw) ?? .stockAndIndexETF }
    var goal: TradeGoal { TradeGoal(rawValue: goalRaw) ?? .growthRightSide }

    var profitLoss: Double { (exitPrice - averageBuyPrice) * quantity }
    var profitLossPercent: Double {
        averageBuyPrice > 0 ? (exitPrice - averageBuyPrice) / averageBuyPrice * 100 : 0
    }
}
