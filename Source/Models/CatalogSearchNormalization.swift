import Foundation

/// Normalizes catalog names and search queries so apostrophe-like characters are ignored (e.g. צ'יפס matches ציפס).
enum CatalogSearchNormalization {
    private static func isApostropheLike(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x0027, 0x2018, 0x2019, 0x201A, 0x201B, 0x0060, 0x00B4, 0x02BC, 0x02BB, 0x02BD, 0x02C8, 0x02B9, 0x2032, 0xFF07,
            0x05F3: // Hebrew geresh
            return true
        default:
            return false
        }
    }

    static func normalizedForMatching(_ string: String) -> String {
        String(string.unicodeScalars.filter { !isApostropheLike($0) })
    }

    static func localizedCaseInsensitiveContains(searchQuery: String, in name: String) -> Bool {
        let query = normalizedForMatching(searchQuery)
        guard !query.isEmpty else { return false }
        let haystack = normalizedForMatching(name)
        return haystack.localizedCaseInsensitiveContains(query)
    }

    static func localizedCaseInsensitiveEquals(_ lhs: String, _ rhs: String) -> Bool {
        normalizedForMatching(lhs).localizedCaseInsensitiveCompare(normalizedForMatching(rhs)) == .orderedSame
    }

    /// Lines from share sheet / Shortcuts text: one item per non-empty line.
    static func shareImportItemFragments(from text: String) -> [String] {
        text.split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
