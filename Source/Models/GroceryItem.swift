import Foundation

struct GroceryItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var inventoryTagID: UUID
    var shoppingTagID: UUID
    /// User-defined order within the item’s **inventory group** (lower comes first).
    /// This is persisted and round-tripped through backup export/import.
    var sortOrder: Int
    /// When true, a JPEG is stored on disk for this item id (see `ItemImageStore`).
    var hasImage: Bool

    init(
        id: UUID = UUID(),
        name: String,
        inventoryTagID: UUID,
        shoppingTagID: UUID,
        sortOrder: Int = 0,
        hasImage: Bool = false
    ) {
        self.id = id
        self.name = name
        self.inventoryTagID = inventoryTagID
        self.shoppingTagID = shoppingTagID
        self.sortOrder = sortOrder
        self.hasImage = hasImage
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case inventoryTagID
        case shoppingTagID
        case sortOrder
        case hasImage
        /// Legacy UserDefaults / JSON; decoded and discarded (items are always active in the catalog).
        case isArchived
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        inventoryTagID = try c.decode(UUID.self, forKey: .inventoryTagID)
        shoppingTagID = try c.decode(UUID.self, forKey: .shoppingTagID)
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        _ = try c.decodeIfPresent(Bool.self, forKey: .isArchived)
        hasImage = try c.decodeIfPresent(Bool.self, forKey: .hasImage) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(inventoryTagID, forKey: .inventoryTagID)
        try c.encode(shoppingTagID, forKey: .shoppingTagID)
        try c.encode(sortOrder, forKey: .sortOrder)
        try c.encode(hasImage, forKey: .hasImage)
    }
}

/// Legacy v1 persisted shape (enum-based sections). Decode-only — used when migrating old disk keys.
struct GroceryItemV1: Identifiable, Decodable, Equatable, Hashable {
    var id: UUID
    var name: String
    var inventorySection: InventorySection
    var shoppingSection: ShoppingSection

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case inventorySection
        case shoppingSection
        case isArchived
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        inventorySection = try c.decode(InventorySection.self, forKey: .inventorySection)
        shoppingSection = try c.decode(ShoppingSection.self, forKey: .shoppingSection)
        _ = try c.decodeIfPresent(Bool.self, forKey: .isArchived)
    }
}

extension GroceryItem {
    /// True when a photo exists on disk for this catalog row (used for long-press preview).
    var hasDisplayablePhoto: Bool {
        hasImage && ItemImageStore.fileExists(forItemID: id)
    }
}
