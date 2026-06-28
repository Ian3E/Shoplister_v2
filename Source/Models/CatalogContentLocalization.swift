import Foundation

/// Item and tag `String`s in `GroceryStore` are always stored in the **active catalog language** (two independent catalogs).
/// Display and editing use those strings as-is; no cross-language string table.
enum CatalogContentLocalization {
    static func displayTagTitle(storedTitle: String, language: AppContentLanguage) -> String {
        storedTitle
    }

    static func displayItemName(storedName: String, language: AppContentLanguage) -> String {
        storedName
    }

    static func storedItemName(fromDisplay display: String, language: AppContentLanguage) -> String {
        display.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func storedTagTitle(fromDisplay display: String, language: AppContentLanguage) -> String {
        display.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Tag {
    func displayTitle(appContentLanguage language: AppContentLanguage) -> String {
        title
    }
}

extension GroceryItem {
    func displayName(appContentLanguage language: AppContentLanguage) -> String {
        name
    }
}
