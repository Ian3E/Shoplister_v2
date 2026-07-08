import Foundation

/// Counts how often the shopping list becomes empty so the empty-state add hint can retire.
enum AppShoppingEmptyAddHint {
    static let storageKey = "app.shoppingEmptyAddHintCompletedListCount"
    /// Hide the empty-state add footer after this many list→empty transitions from a fresh install.
    static let hideAfterCompletedLists = 5

    static func shouldShow(completedListCount: Int) -> Bool {
        completedListCount < hideAfterCompletedLists
    }
}
