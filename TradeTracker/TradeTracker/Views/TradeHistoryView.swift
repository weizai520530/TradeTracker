import SwiftUI
import SwiftData

struct TradeHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TradeHistory.sellDate, order: .reverse) private var history: [TradeHistory]

    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    ContentUnavailableView(
                        "No trade history",
                        systemImage: "clock",
                        description: Text("Closed trades will appear here.")
                    )
                } else {
                    List {
                        ForEach(history) { entry in
                            HistoryRowView(entry: entry)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct HistoryRowView: View {
    let entry: TradeHistory

    private var isProfit: Bool { entry.profitLoss >= 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.ticker)
                    .font(.headline)
                Text(entry.isFullExit ? "Closed" : "Partial")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(entry.isFullExit ? Color.gray.opacity(0.2) : Color.orange.opacity(0.2))
                    .clipShape(Capsule())
                Spacer()
                Text(entry.profitLoss, format: .currency(code: "USD"))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(isProfit ? .green : .red)
            }
            HStack {
                Text("Sold \(entry.quantity, format: .number) @ \(entry.exitPrice, format: .currency(code: "USD"))")
                Spacer()
                Text(entry.profitLossPercent / 100, format: .percent.precision(.fractionLength(2)))
                    .monospacedDigit()
                    .foregroundStyle(isProfit ? .green : .red)
            }
            .font(.caption)
            HStack {
                Text("Avg buy \(entry.averageBuyPrice, format: .currency(code: "USD"))")
                Spacer()
                Text(entry.sellDate, format: .dateTime.day().month().year())
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
