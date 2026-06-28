import Foundation

/// Seeds the initial catalog + section lists from backup-format documents that ship with the app bundle.
///
/// Why: it keeps the seed data in a human-editable format (the same plain-text format the app exports/imports),
/// while still producing deterministic default tags + item ordering.
enum BilingualSeedCatalog {
    struct SeedItem: Equatable {
        let name: String
        let inventoryGroupTitle: String
        let shoppingGroupTitle: String
        let inventoryOrder: Int
    }

    struct SeedDocument: Equatable {
        let inventoryGroups: [String]
        let shoppingGroups: [String]
        let items: [SeedItem]
    }

    // MARK: - Public API (groups)

    /// Inventory section titles in display order (minus the “Undefined” bucket).
    static var defaultEnglishInventoryGroupTitles: [String] { englishSeed.inventoryGroups }
    static var defaultEnglishShoppingGroupTitles: [String] { englishSeed.shoppingGroups }
    static var defaultHebrewInventoryGroupTitles: [String] { hebrewSeed.inventoryGroups }
    static var defaultHebrewShoppingGroupTitles: [String] { hebrewSeed.shoppingGroups }

    // MARK: - Public API (seed items)

    static var englishSeedItems: [SeedItem] { englishSeed.items }
    static var hebrewSeedItems: [SeedItem] { hebrewSeed.items }

    // MARK: - Load + parse

    private static let englishSeed: SeedDocument = loadSeedDocument(resourceBaseName: "seed-library-backup-en")
    private static let hebrewSeed: SeedDocument = loadSeedDocument(resourceBaseName: "seed-library-backup-he")

    private static func loadSeedDocument(resourceBaseName: String) -> SeedDocument {
        guard let url = Bundle.main.url(forResource: resourceBaseName, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            #if DEBUG
            assertionFailure("Missing seed resource \(resourceBaseName).txt in app bundle")
            #endif
            return SeedDocument(inventoryGroups: [], shoppingGroups: [], items: [])
        }
        return parseSeedBackupDocument(text)
    }

    private static func parseSeedBackupDocument(_ text: String) -> SeedDocument {
        var normalized = text
        if normalized.first == "\u{FEFF}" {
            normalized.removeFirst()
        }
        let lines = normalized.split(whereSeparator: \.isNewline).map(String.init)

        enum Section {
            case inventoryGroups
            case shoppingGroups
            case library
        }

        var section: Section?
        var inventoryGroups: [String] = []
        var shoppingGroups: [String] = []
        var items: [SeedItem] = []
        var catalogHeaderSeen = false

        func clean(_ s: String) -> String {
            s.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        for rawLine in lines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") { continue }
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                let name = String(trimmed.dropFirst().dropLast())
                switch name {
                case "home_sections":
                    section = .inventoryGroups
                case "shopping_sections":
                    section = .shoppingGroups
                case "library":
                    section = .library
                    catalogHeaderSeen = false
                default:
                    section = nil
                }
                continue
            }
            guard let section else { continue }
            if clean(trimmed).isEmpty { continue }

            switch section {
            case .inventoryGroups:
                inventoryGroups.append(clean(trimmed))
            case .shoppingGroups:
                shoppingGroups.append(clean(trimmed))
            case .library:
                if !catalogHeaderSeen {
                    // First non-empty line after [library] is the header.
                    catalogHeaderSeen = true
                    continue
                }
                let cols = rawLine.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
                guard cols.count >= 4 else { continue }
                let name = clean(cols[0])
                let inv = clean(cols[1])
                let shop = clean(cols[2])
                let ord = Int(clean(cols[3])) ?? 0
                guard !name.isEmpty else { continue }
                items.append(.init(name: name, inventoryGroupTitle: inv, shoppingGroupTitle: shop, inventoryOrder: max(0, ord)))
            }
        }

        return SeedDocument(inventoryGroups: inventoryGroups, shoppingGroups: shoppingGroups, items: items)
    }
}

