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
    static func rules(for type: TickerType, goal: TradeGoal) -> [TradeRule] {
        var rules: [TradeRule] = [
            TradeRule("I have set a clear stop price and will respect it."),
            TradeRule("Position size is appropriate for my account."),
        ]

        switch goal {
        case .growthLeftSide:
            rules.append(TradeRule("Buying ahead of confirmation — accept higher rejection risk."))
            rules.append(TradeRule("Plan: scale in if thesis holds, exit fast if invalidated."))
        case .growthRightSide:
            rules.append(TradeRule("Wait for breakout confirmation before adding."))
            rules.append(TradeRule("Trail stop under most recent higher low."))
        case .momentumShort:
            rules.append(TradeRule("This is a short-term bet — define an exit window."))
            rules.append(TradeRule("Cut losses fast; momentum can reverse without warning."))
        }

        switch type {
        case .stock:
            break
        case .etf:
            rules.append(TradeRule("Considered the underlying sector / index drivers."))
        case .option:
            rules.append(TradeRule("Account for time decay — set a time-based exit."))
            rules.append(TradeRule("Avoid earnings unless explicitly part of the thesis."))
        }

        return rules
    }
}
