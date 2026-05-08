import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trade.buyDate, order: .reverse) private var trades: [Trade]

    @State private var showingNewTrade = false
    @State private var showingHistory = false

    var body: some View {
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
                                TradeRowView(trade: trade)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Trades")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingHistory = true
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
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
        }
    }
}

private struct TradeRowView: View {
    let trade: Trade

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(trade.ticker)
                    .font(.headline)
                Spacer()
                Text(trade.type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Avg \(trade.averageBuyPrice, format: .currency(code: "USD"))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Qty \(trade.totalQuantity, format: .number)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Trade.self, Purchase.self, TradeHistory.self], inMemory: true)
}
