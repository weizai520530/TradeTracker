import Foundation

struct TradeRule: Identifiable, Hashable {
    let id: String
    let text: String
    init(_ text: String) {
        self.id = text
        self.text = text
    }
}

enum TradeRules {

    static func stopLossPercent(for type: TickerType) -> Double {
        switch type {
        case .stockAndIndexETF:  return 0.30
        case .leveragedETFLong:  return 0.20
        case .leveragedETFShort: return 0.20
        case .option:            return 0.50
        }
    }

    static func suggestedStopPrice(buyPrice: Double, type: TickerType) -> Double {
        buyPrice * (1 - stopLossPercent(for: type))
    }

    static func isAllowed(type: TickerType, goal: TradeGoal) -> Bool {
        switch (type, goal) {
        case (.leveragedETFShort, .growthLeftSide),
             (.option,            .growthLeftSide),
             (.leveragedETFShort, .growthRightSide),
             (.option,            .momentumShort):
            return false
        default:
            return true
        }
    }

    static func rules(for type: TickerType, goal: TradeGoal) -> [TradeRule] {
        switch (type, goal) {

        case (.stockAndIndexETF, .growthLeftSide),
             (.leveragedETFLong, .growthLeftSide):
            return [
                TradeRule("EMA is below 20/50/200."),
                TradeRule("BB is below the lower band."),
                TradeRule("Candle & indicators divergence appears."),
                TradeRule("Signs of a flat bottom are present."),
                TradeRule("Potential growth points/views identified."),
            ]

        case (.stockAndIndexETF, .growthRightSide),
             (.leveragedETFLong, .growthRightSide):
            return [
                TradeRule("EMA 8/20 is rising and crosses EMA 50/200 above 0 and below upper band."),
                TradeRule("BB trend is above 0 and below upper band."),
                TradeRule("Confirmed info (news, recent earnings) on growing phase."),
            ]

        case (.option, .growthRightSide):
            return [
                TradeRule("Leap-Call only (1 month & above)."),
                TradeRule("EMA 8/20 is rising and crosses EMA 50/200 above 0 and below upper band."),
                TradeRule("BB trend is above 0 and below upper band."),
                TradeRule("Confirmed info (news, recent earnings) on growing phase."),
            ]

        case (.stockAndIndexETF, .momentumShort),
             (.leveragedETFLong, .momentumShort):
            return [
                TradeRule("Clear rising EMA trend confirmed."),
                TradeRule("Near confirmed positive news."),
                TradeRule("5-day holding limit acknowledged."),
            ]

        case (.leveragedETFShort, .momentumShort):
            return [
                TradeRule("BB is above the upper band."),
                TradeRule("Clear divergence signal in candle trend with BB shrinking volume."),
                TradeRule("Elliott Wave down trend signal present (Wave 2/4, or correction wave a & c)."),
            ]

        default:
            return []
        }
    }
}
