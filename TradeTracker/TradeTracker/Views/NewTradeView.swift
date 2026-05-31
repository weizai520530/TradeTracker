import SwiftUI
import SwiftData

struct NewTradeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var ticker = ""
    @State private var sector: Sector = .technology
    @State private var type: TickerType = .stockAndIndexETF
    @State private var goal: TradeGoal = .growthRightSide
    @State private var buyPriceText = ""
    @State private var quantityText = ""
    @State private var priceTargetText = ""
    @State private var stopPriceText = ""
    @State private var lastAutoStop = ""

    @State private var showingRules = false
    @State private var showingNotAllowed = false
    @State private var showingStopTooLow = false

    private var buyPrice: Double? { Double(buyPriceText) }
    private var quantity: Double? { Double(quantityText) }
    private var priceTarget: Double? { Double(priceTargetText) }
    private var stopPrice: Double? { Double(stopPriceText) }

    private var autoStopPrice: Double? {
        guard let bp = buyPrice, bp > 0 else { return nil }
        return TradeRules.suggestedStopPrice(buyPrice: bp, type: type)
    }

    private var stopBelowAuto: Bool {
        guard let auto = autoStopPrice, let user = stopPrice else { return false }
        return user < auto
    }

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
                        .uppercaseAutoInput()
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
                        .decimalKeyboard()
                    TextField("Quantity", text: $quantityText)
                        .decimalKeyboard()
                }
                Section("Strategy") {
                    Picker("Trade Goal", selection: $goal) {
                        ForEach(TradeGoal.allCases) { Text($0.rawValue).tag($0) }
                    }
                    TextField("Price Target", text: $priceTargetText)
                        .decimalKeyboard()
                    TextField("Stop Price", text: $stopPriceText)
                        .decimalKeyboard()
                    if let auto = autoStopPrice {
                        if stopBelowAuto {
                            Label {
                                Text("Below \(auto, format: .currency(code: "USD")) — minimum for \(type.rawValue) (\(Int(TradeRules.stopLossPercent(for: type) * 100))% max loss)")
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                            }
                            .font(.caption)
                            .foregroundStyle(.orange)
                        } else {
                            Text("Auto: \(auto, format: .currency(code: "USD")) (\(Int(TradeRules.stopLossPercent(for: type) * 100))% max loss for \(type.rawValue))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Trade")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") { handleNext() }
                        .disabled(!isValid)
                }
            }
            .onChange(of: buyPriceText) { _, _ in updateStopFromAuto() }
            .onChange(of: type) { _, _ in updateStopFromAuto() }
            .navigationDestination(isPresented: $showingRules) {
                TradeRulesView(type: type, goal: goal) {
                    confirmTrade()
                }
            }
            .alert("Trade Not Allowed", isPresented: $showingNotAllowed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("\(type.rawValue) + \(goal.rawValue) is not allowed in the current strategy.")
            }
            .alert("Stop Price is too low for current strategy", isPresented: $showingStopTooLow) {
                Button("OK", role: .cancel) {}
            } message: {
                if let auto = autoStopPrice {
                    Text("Minimum allowed stop price is \(auto, format: .currency(code: "USD")) for \(type.rawValue) (\(Int(TradeRules.stopLossPercent(for: type) * 100))% max loss).")
                }
            }
        }
        .sheetSizing()
    }

    private func updateStopFromAuto() {
        guard let auto = autoStopPrice else { return }
        let autoText = String(format: "%.2f", auto)
        if stopPriceText.isEmpty || stopPriceText == lastAutoStop {
            stopPriceText = autoText
        }
        lastAutoStop = autoText
    }

    private func handleNext() {
        guard TradeRules.isAllowed(type: type, goal: goal) else {
            showingNotAllowed = true
            return
        }
        if stopBelowAuto {
            showingStopTooLow = true
            return
        }
        showingRules = true
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
