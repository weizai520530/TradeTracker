import SwiftUI
import SwiftData

struct TradeDetailView: View {
    let tradeID: PersistentIdentifier
    @Environment(\.dismiss) private var dismiss
    @Query private var trades: [Trade]
    @State private var priceService = PriceService.shared

    @State private var showingQuit = false
    @State private var showingAdd = false

    private var trade: Trade? {
        trades.first { $0.persistentModelID == tradeID }
    }

    var body: some View {
        Group {
            if let trade {
                content(for: trade)
                    .task(id: trade.ticker) {
                        await priceService.refresh(tickers: [trade.ticker])
                    }
                    .refreshable {
                        await priceService.refresh(tickers: [trade.ticker], force: true)
                    }
            } else {
                Color.clear
                    .task { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func content(for trade: Trade) -> some View {
        let quote = priceService.quote(for: trade.ticker)

        List {
            Section("Price") {
                PriceSummaryView(trade: trade, quote: quote)
            }

            Section("Rules to follow") {
                ForEach(TradeRules.rules(for: trade.type, goal: trade.goal)) { rule in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(rule.text)
                    }
                }
            }

            Section("Purchases") {
                ForEach(trade.purchases.sorted(by: { $0.date < $1.date })) { purchase in
                    HStack {
                        Text(purchase.date, format: .dateTime.day().month().year())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(purchase.price, format: .currency(code: "USD"))
                        Text("× \(purchase.quantity, format: .number)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }

            Section("Position") {
                LabeledContent("Ticker", value: trade.ticker)
                LabeledContent("Type", value: trade.type.rawValue)
                LabeledContent("Sector", value: trade.sector.rawValue)
                LabeledContent("Goal", value: trade.goal.rawValue)
                LabeledContent("Avg Buy") {
                    Text(trade.averageBuyPrice, format: .currency(code: "USD"))
                }
                LabeledContent("Quantity") {
                    Text(trade.totalQuantity, format: .number)
                }
                LabeledContent("Price Target") {
                    Text(trade.priceTarget, format: .currency(code: "USD"))
                }
                LabeledContent("Stop Price") {
                    Text(trade.stopPrice, format: .currency(code: "USD"))
                        .foregroundStyle(.red)
                }
                LabeledContent("Buy Date") {
                    Text(trade.buyDate, format: .dateTime.day().month().year())
                }
            }
        }
        .navigationTitle(trade.ticker)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(role: .destructive) {
                    showingQuit = true
                } label: {
                    Label("Quit Trade", systemImage: "xmark.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingQuit) {
            QuitTradeView(trade: trade)
        }
        .sheet(isPresented: $showingAdd) {
            AddPositionView(trade: trade)
        }
    }
}

private struct PriceSummaryView: View {
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
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let quote {
                        Text(quote.price, format: .currency(code: "USD"))
                            .font(.title.monospacedDigit().bold())
                        Text("\(quote.change >= 0 ? "▲" : "▼") \(abs(quote.change), format: .currency(code: "USD")) (\(abs(quote.changePercent), format: .number.precision(.fractionLength(2)))%)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(quote.change >= 0 ? .green : .red)
                    } else {
                        Text("—")
                            .font(.title.bold())
                            .foregroundStyle(.tertiary)
                        Text("Price unavailable")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Unrealized P/L")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let pl = unrealizedPL, let pct = unrealizedPLPercent {
                        Text(pl, format: .currency(code: "USD"))
                            .font(.title2.monospacedDigit().bold())
                            .foregroundStyle(pl >= 0 ? .green : .red)
                        Text(pct / 100, format: .percent.precision(.fractionLength(2)))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(pl >= 0 ? .green : .red)
                    } else {
                        Text("—")
                            .font(.title2.bold())
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
