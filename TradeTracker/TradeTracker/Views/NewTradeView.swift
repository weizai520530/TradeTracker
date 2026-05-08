import SwiftUI
import SwiftData

struct NewTradeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var ticker = ""
    @State private var sector: Sector = .technology
    @State private var type: TickerType = .stock
    @State private var goal: TradeGoal = .growthRightSide
    @State private var buyPriceText = ""
    @State private var quantityText = ""
    @State private var priceTargetText = ""
    @State private var stopPriceText = ""

    @State private var showingRules = false

    private var buyPrice: Double? { Double(buyPriceText) }
    private var quantity: Double? { Double(quantityText) }
    private var priceTarget: Double? { Double(priceTargetText) }
    private var stopPrice: Double? { Double(stopPriceText) }

    private var isValid: Bool {
        !ticker.trimmingCharacters(in: .whitespaces).isEmpty
            && (buyPrice ?? 0) > 0
            && (quantity ?? 0) > 0
            && (priceTarget ?? 0) > 0
            && (stopPrice ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ticker") {
                    TextField("Symbol", text: $ticker)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Picker("Sector", selection: $sector) {
                        ForEach(Sector.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Type", selection: $type) {
                        ForEach(TickerType.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Section("Position") {
                    TextField("Buy Price", text: $buyPriceText)
                        .keyboardType(.decimalPad)
                    TextField("Quantity", text: $quantityText)
                        .keyboardType(.decimalPad)
                }
                Section("Strategy") {
                    Picker("Trade Goal", selection: $goal) {
                        ForEach(TradeGoal.allCases) { Text($0.rawValue).tag($0) }
                    }
                    TextField("Price Target", text: $priceTargetText)
                        .keyboardType(.decimalPad)
                    TextField("Stop Price", text: $stopPriceText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("New Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") { showingRules = true }
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingRules) {
                TradeRulesView(type: type, goal: goal) {
                    confirmTrade()
                }
            }
        }
    }

    private func confirmTrade() {
        guard let buy = buyPrice,
              let qty = quantity,
              let target = priceTarget,
              let stop = stopPrice else { return }

        let trade = Trade(
            ticker: ticker,
            sector: sector,
            type: type,
            goal: goal,
            priceTarget: target,
            stopPrice: stop
        )
        modelContext.insert(trade)

        let purchase = Purchase(price: buy, quantity: qty)
        purchase.trade = trade
        modelContext.insert(purchase)

        showingRules = false
        dismiss()
    }
}

#Preview {
    NewTradeView()
        .modelContainer(for: [Trade.self, Purchase.self, TradeHistory.self], inMemory: true)
}
