import Foundation

enum AppShoppingBadgeUnchecked {
    /// When **on**, the home-screen icon badge shows the count of
    /// **unchecked** shopping lines (resolved catalog items only).
    static let storageKey = "app.shoppingBadgeUncheckedCountEnabled"
}

/// When **on** (default), the List tab shows a badge with the unchecked item count.
enum AppListTabBadge {
    static let storageKey = "app.listTabBadgeUncheckedCountEnabled"

    static var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: storageKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: storageKey)
    }
}
