import Foundation

@Observable
final class PriceService {
    static let shared = PriceService()

    struct Quote: Sendable, Equatable {
        let symbol: String
        let price: Double
        let previousClose: Double
        let fetchedAt: Date

        var change: Double { price - previousClose }
        var changePercent: Double {
            guard previousClose > 0 else { return 0 }
            return change / previousClose * 100
        }
    }

    @MainActor private(set) var quotes: [String: Quote] = [:]
    @MainActor private(set) var inFlight: Set<String> = []

    private let minimumRefreshInterval: TimeInterval = 30

    private init() {}

    @MainActor
    func quote(for ticker: String) -> Quote? {
        quotes[ticker.uppercased()]
    }

    @MainActor
    func refresh(tickers: [String], force: Bool = false) async {
        let unique = Set(tickers.map { $0.uppercased() })
        let now = Date()
        let toFetch = unique.filter { ticker in
            guard !inFlight.contains(ticker) else { return false }
            if force { return true }
            guard let existing = quotes[ticker] else { return true }
            return now.timeIntervalSince(existing.fetchedAt) >= minimumRefreshInterval
        }
        guard !toFetch.isEmpty else { return }

        for ticker in toFetch { inFlight.insert(ticker) }

        await withTaskGroup(of: (String, Quote?).self) { group in
            for ticker in toFetch {
                group.addTask {
                    let quote = await Self.fetchQuote(ticker)
                    return (ticker, quote)
                }
            }
            for await (ticker, quote) in group {
                if let quote { quotes[ticker] = quote }
                inFlight.remove(ticker)
            }
        }
    }

    private static func fetchQuote(_ ticker: String) async -> Quote? {
        guard let encoded = ticker.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=1d&range=1d") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(YahooChartResponse.self, from: data)
            guard decoded.chart.error == nil,
                  let meta = decoded.chart.result?.first?.meta,
                  let price = meta.regularMarketPrice else { return nil }
            let previous = meta.previousClose ?? meta.chartPreviousClose ?? price
            return Quote(symbol: ticker, price: price, previousClose: previous, fetchedAt: Date())
        } catch {
            return nil
        }
    }
}

private struct YahooChartResponse: Decodable {
    struct Chart: Decodable {
        let result: [Result]?
        let error: ErrorInfo?
    }
    struct Result: Decodable {
        let meta: Meta
    }
    struct Meta: Decodable {
        let regularMarketPrice: Double?
        let previousClose: Double?
        let chartPreviousClose: Double?
    }
    struct ErrorInfo: Decodable {
        let code: String?
        let description: String?
    }
    let chart: Chart
}
