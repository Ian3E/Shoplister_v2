import Foundation

enum AppShoppingSortChecked {
    /// When **on**, checked shopping rows are listed in a bottom **Checked** / **סומנו** section instead of staying in their tag groups.
    static let storageKey = "app.shoppingSortCheckedItems"
}

enum AppShoppingHideStoreGroupNames {
    /// When **on**, the Store list keeps tag grouping and inter-section dividers but hides section header rows (including **Checked**).
    static let storageKey = "app.shoppingHideStoreGroupNames"
}

enum AppShoppingConfirmClearWhenAllChecked {
    /// When **on**, checking the last item asks to keep or clear the list; when **off**, the list clears automatically.
    static let storageKey = "app.shoppingConfirmClearWhenAllChecked"
}
