import SwiftUI

struct TradeRulesView: View {
    let type: TickerType
    let goal: TradeGoal
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var checked: Set<String> = []

    private var rules: [TradeRule] { TradeRules.rules(for: type, goal: goal) }
    private var allChecked: Bool { checked.count == rules.count }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Review the rules for **\(type.rawValue) — \(goal.rawValue)**. Check each before confirming.")
                        .font(.callout)
                }
                Section("Rules") {
                    ForEach(rules) { rule in
                        Button {
                            toggle(rule)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: checked.contains(rule.id) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(checked.contains(rule.id) ? .green : .secondary)
                                    .font(.title3)
                                Text(rule.text)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm Trade", action: onConfirm)
                        .disabled(!allChecked)
                }
            }
        }
    }

    private func toggle(_ rule: TradeRule) {
        if checked.contains(rule.id) {
            checked.remove(rule.id)
        } else {
            checked.insert(rule.id)
        }
    }
}

#Preview {
    TradeRulesView(type: .stockAndIndexETF, goal: .growthRightSide) {}
}
