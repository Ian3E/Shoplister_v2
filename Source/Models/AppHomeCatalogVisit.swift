import Foundation

/// Whether the user has opened the Home item library from Store at least once.
enum AppHomeCatalogVisit {
    static let storageKey = "app.homeCatalogHasBeenVisited"
}

/// When **on** (default), adding an item from the library expands its quantity pill.
/// When **off**, the pill expands only when the user taps it.
enum AppLibraryAutoExpandQuantityPicker {
    static let storageKey = "app.libraryAutoExpandQuantityPicker"

    static var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: storageKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: storageKey)
    }
}
