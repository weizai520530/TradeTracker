import Foundation

enum TickerType: String, Codable, CaseIterable, Identifiable {
    case stockAndIndexETF = "Stocks & Index ETFs"
    case leveragedETFLong = "Leveraged ETFs (Long)"
    case leveragedETFShort = "Leveraged ETFs (Short)"
    case option = "Option"
    var id: String { rawValue }
}

enum TradeGoal: String, Codable, CaseIterable, Identifiable {
    case growthLeftSide = "Growth (Left-side)"
    case growthRightSide = "Growth (Right-side)"
    case momentumShort = "Momentum (short bet)"
    var id: String { rawValue }
}

enum Sector: String, Codable, CaseIterable, Identifiable {
    case technology = "Technology"
    case healthcare = "Healthcare"
    case financials = "Financials"
    case consumerDiscretionary = "Consumer Discretionary"
    case consumerStaples = "Consumer Staples"
    case energy = "Energy"
    case industrials = "Industrials"
    case materials = "Materials"
    case utilities = "Utilities"
    case realEstate = "Real Estate"
    case communicationServices = "Communication Services"
    case other = "Other"
    var id: String { rawValue }
}
