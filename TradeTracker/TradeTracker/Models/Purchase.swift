import Foundation
import SwiftData

@Model
final class Purchase {
    var price: Double
    var quantity: Double
    var date: Date
    var trade: Trade?

    init(price: Double, quantity: Double, date: Date = .now) {
        self.price = price
        self.quantity = quantity
        self.date = date
    }
}
