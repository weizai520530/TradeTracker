import SwiftUI
import SwiftData

struct QuitTradeView: View {
    @Bindable var trade: Trade
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var exitPriceText = ""
    @State private var quantityText = ""

    private var exitPrice: Double? { Double(exitPriceText) }
    private var quantity: Double? { Double(quantityText) }

    private var warning: (text: String, color: Color)? {
        guard let exit = exitPrice, exit > 0 else { return nil }
        if exit < trade.stopPrice {
            return ("Exit price is below STOP price.", .red)
        } else if exit < trade.averageBuyPrice {
            return ("Exit price is below average buy price.", .yellow)
        }
        return nil
    }

    private var canConfirm: Bool {
        guard let exit = exitPrice, let qty = quantity else { return false }
        return exit > 0 && qty > 0 && qty <= trade.totalQuantity
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Holding") {
                    LabeledContent("Ticker", value: trade.ticker)
                    LabeledContent("Avg Buy") {
                        Text(trade.averageBuyPrice, format: .currency(code: "USD"))
                    }
                    LabeledContent("Stop Price") {
                        Text(trade.stopPrice, format: .currency(code: "USD"))
                    }
                    LabeledContent("Quantity") {
                        Text(trade.totalQuantity, format: .number)
                    }
                }

                Section("Exit") {
                    TextField("Exit Price", text: $exitPriceText)
                        .keyboardType(.decimalPad)
                    TextField("Quantity to Sell", text: $quantityText)
                        .keyboardType(.decimalPad)
                }

                if let warning {
                    Section {
                        Label(warning.text, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(warning.color)
                    }
                }
            }
            .navigationTitle("Quit Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm Sell") { confirmSell() }
                        .disabled(!canConfirm)
                }
            }
        }
    }

    private func confirmSell() {
        guard let exit = exitPrice, let qty = quantity else { return }

        let isFullExit = qty >= trade.totalQuantity
        let soldQuantity = isFullExit ? trade.totalQuantity : qty
        let avgAtSale = trade.averageBuyPrice

        let record = TradeHistory(
            ticker: trade.ticker,
            sector: trade.sector,
            type: trade.type,
            goal: trade.goal,
            averageBuyPrice: avgAtSale,
            exitPrice: exit,
            quantity: soldQuantity,
            priceTarget: trade.priceTarget,
            stopPrice: trade.stopPrice,
            buyDate: trade.buyDate,
            sellDate: .now,
            isFullExit: isFullExit
        )
        modelContext.insert(record)

        if isFullExit {
            modelContext.delete(trade)
        } else {
            var remaining = qty
            let purchases = trade.purchases.sorted(by: { $0.date > $1.date })
            for purchase in purchases {
                if remaining <= 0 { break }
                if purchase.quantity <= remaining {
                    remaining -= purchase.quantity
                    modelContext.delete(purchase)
                } else {
                    purchase.quantity -= remaining
                    remaining = 0
                }
            }
        }

        dismiss()
    }
}
