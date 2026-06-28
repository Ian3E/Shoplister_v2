import Foundation

struct Recipe: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var sortOrder: Int
    var lines: [RecipeLine]
}

struct RecipeLine: Identifiable, Codable, Equatable {
    var id: UUID
    var itemID: UUID
    var quantity: Int
}
