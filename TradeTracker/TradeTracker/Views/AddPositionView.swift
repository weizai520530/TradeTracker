import SwiftUI
import SwiftData

struct AddPositionView: View {
    @Bindable var trade: Trade
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var buyPriceText = ""
    @State private var quantityText = ""
    @State private var showingStopWarning = false

    private var buyPrice: Double? { Double(buyPriceText) }
    private var quantity: Double? { Double(quantityText) }

    private var canConfirm: Bool {
        (buyPrice ?? 0) > 0 && (quantity ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Add to position") {
                    TextField("Buy Price", text: $buyPriceText)
                        .decimalKeyboard()
                    TextField("Quantity", text: $quantityText)
                        .decimalKeyboard()
                }
                Section("Reference") {
                    LabeledContent("Stop Price") {
                        Text(trade.stopPrice, format: .currency(code: "USD"))
                            .foregroundStyle(.red)
                    }
                    LabeledContent("Avg Buy") {
                        Text(trade.averageBuyPrice, format: .currency(code: "USD"))
                    }
                    LabeledContent("Current Qty") {
                        Text(trade.totalQuantity, format: .number)
                    }
                }
            }
            .navigationTitle("Add Position")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") { tryConfirm() }
                        .disabled(!canConfirm)
                }
            }
            .alert("Buy Price < Stop Price. Sell Now!", isPresented: $showingStopWarning) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your intended buy price is below the stop price for this trade. Reconsider this position.")
            }
        }
        .sheetSizing()
    }

    private func tryConfirm() {
        guard let price = buyPrice, let qty = quantity else { return }

        if price < trade.stopPrice {
            showingStopWarning = true
            return
        }

        let purchase = Purchase(price: price, quantity: qty)
        purchase.trade = trade
        modelContext.insert(purchase)
        dismiss()
    }
}
