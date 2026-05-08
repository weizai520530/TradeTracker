import SwiftUI
import SwiftData

struct TradeDetailView: View {
    let tradeID: PersistentIdentifier
    @Environment(\.dismiss) private var dismiss
    @Query private var trades: [Trade]

    @State private var showingQuit = false
    @State private var showingAdd = false

    private var trade: Trade? {
        trades.first { $0.persistentModelID == tradeID }
    }

    var body: some View {
        Group {
            if let trade {
                content(for: trade)
            } else {
                Color.clear
                    .task { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func content(for trade: Trade) -> some View {
        List {
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

            Section("Rules to follow") {
                ForEach(TradeRules.rules(for: trade.type, goal: trade.goal)) { rule in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(rule.text)
                    }
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
