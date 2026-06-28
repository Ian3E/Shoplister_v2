import Foundation

struct Tag: Identifiable, Codable, Equatable, Hashable {
    /// Reserved title for the catch-all bucket in English.
    static let unsortedCanonicalTitle = "Undefined"
    /// Same bucket when the Hebrew catalog is active (persisted in Hebrew data).
    static let unsortedHebrewTitle = "לא מוגדר"

    enum Kind: String, Codable, Equatable, Hashable, Identifiable {
        case inventory
        case shopping

        var id: String { rawValue }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case title
        case sortOrder
    }

    var id: UUID
    var kind: Kind
    var title: String
    /// Display order within the tag’s kind; lower appears first.
    var sortOrder: Int

    init(id: UUID = UUID(), kind: Kind, title: String, sortOrder: Int = 0) {
        self.id = id
        self.kind = kind
        self.title = title
        self.sortOrder = sortOrder
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        kind = try c.decode(Kind.self, forKey: .kind)
        title = try c.decode(String.self, forKey: .title)
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(kind, forKey: .kind)
        try c.encode(title, forKey: .title)
        try c.encode(sortOrder, forKey: .sortOrder)
    }

    /// The built-in no-section bucket; English uses `unsortedCanonicalTitle`, Hebrew data uses `unsortedHebrewTitle`.
    static func isUnsortedBucket(_ tag: Tag) -> Bool {
        isUnsortedCanonicalTitle(tag.title)
    }

    static func isUnsortedCanonicalTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.caseInsensitiveCompare(unsortedCanonicalTitle) == .orderedSame { return true }
        if trimmed == unsortedHebrewTitle { return true }
        // Legacy persisted titles before rename to "Undefined".
        if trimmed.caseInsensitiveCompare("No section") == .orderedSame { return true }
        if trimmed == "ללא מדור" { return true }
        if trimmed.caseInsensitiveCompare("No group") == .orderedSame { return true }
        if trimmed == "ללא קבוצה" { return true }
        if trimmed.caseInsensitiveCompare("Unsorted") == .orderedSame { return true }
        return false
    }
}
