import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trade.buyDate, order: .reverse) private var trades: [Trade]
    @State private var priceService = PriceService.shared

    @State private var showingNewTrade = false
    @State private var showingHistory = false

    var body: some View {
        let tickers = trades.map(\.ticker)

        NavigationStack {
            Group {
                if trades.isEmpty {
                    ContentUnavailableView(
                        "No active trades",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Tap + to add your first trade.")
                    )
                } else {
                    List {
                        ForEach(trades) { trade in
                            NavigationLink {
                                TradeDetailView(tradeID: trade.persistentModelID)
                            } label: {
                                TradeRowView(
                                    trade: trade,
                                    quote: priceService.quote(for: trade.ticker)
                                )
                            }
                        }
                    }
                    .refreshable {
                        await priceService.refresh(tickers: tickers, force: true)
                    }
                }
            }
            .navigationTitle("Trades")
            .toolbar {
                ToolbarItem(placement: .leadingBar) {
                    Button {
                        showingHistory = true
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .trailingBar) {
                    Button {
                        showingNewTrade = true
                    } label: {
                        Label("New Trade", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewTrade) {
                NewTradeView()
            }
            .sheet(isPresented: $showingHistory) {
                TradeHistoryView()
            }
            .task(id: tickers.joined(separator: ",")) {
                await priceService.refresh(tickers: tickers)
            }
        }
    }
}

private struct TradeRowView: View {
    let trade: Trade
    let quote: PriceService.Quote?

    private var unrealizedPL: Double? {
        guard let quote else { return nil }
        return (quote.price - trade.averageBuyPrice) * trade.totalQuantity
    }

    private var unrealizedPLPercent: Double? {
        guard let quote, trade.averageBuyPrice > 0 else { return nil }
        return (quote.price - trade.averageBuyPrice) / trade.averageBuyPrice * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trade.ticker)
                        .font(.headline)
                    Text(trade.type.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if let quote {
                        Text(quote.price, format: .currency(code: "USD"))
                            .font(.headline.monospacedDigit())
                        Text("\(quote.changePercent >= 0 ? "▲" : "▼") \(abs(quote.changePercent), format: .number.precision(.fractionLength(2)))%")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(quote.changePercent >= 0 ? .green : .red)
                    } else {
                        Text("—")
                            .font(.headline)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            HStack(alignment: .firstTextBaseline) {
                Text("Avg \(trade.averageBuyPrice, format: .currency(code: "USD")) × \(trade.totalQuantity, format: .number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let pl = unrealizedPL, let pct = unrealizedPLPercent {
                    Text("\(pl, format: .currency(code: "USD")) (\(pct / 100, format: .percent.precision(.fractionLength(2))))")
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(pl >= 0 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Trade.self, Purchase.self, TradeHistory.self], inMemory: true)
}
