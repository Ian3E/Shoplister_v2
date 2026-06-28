import Foundation

struct ShoppingEntry: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var itemID: UUID
    var quantity: Int
    var isChecked: Bool
    var addedAt: Date

    init(
        id: UUID = UUID(),
        itemID: UUID,
        quantity: Int,
        isChecked: Bool = false,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.itemID = itemID
        self.quantity = max(1, quantity)
        self.isChecked = isChecked
        self.addedAt = addedAt
    }
}

