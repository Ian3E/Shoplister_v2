import Foundation
import UIKit

/// Plain-text export of the shopping list for the share sheet.
/// **Keep grouping / sorting aligned with** `ShoppingView.grouped` (unchecked-only here).
@MainActor
enum ShoppingListShareText {
    static func hasUncheckedItemsToShare(store: GroceryStore) -> Bool {
        store.shopping.contains { !$0.isChecked && store.item(for: $0.itemID) != nil }
    }

    static func buildPlainText(
        store: GroceryStore,
        catalogLanguage: AppContentLanguage,
        sortCheckedShoppingItems: Bool
    ) -> String {
        let entriesWithItems: [(ShoppingEntry, GroceryItem)] = store.shopping.compactMap { entry in
            guard let item = store.item(for: entry.itemID) else { return nil }
            return (entry, item)
        }
        let unchecked = entriesWithItems.filter { !$0.0.isChecked }
        guard !unchecked.isEmpty else { return "" }

        let bucket = Dictionary(grouping: unchecked, by: { $0.1.shoppingTagID })

        struct ShoppingGroupSortKey {
            let tag: Tag
            let rows: [(ShoppingEntry, GroceryItem)]
            let order: Int
            let unchecked: Int
        }

        let inventoryRank = Dictionary(
            uniqueKeysWithValues: store.inventoryTags.enumerated().map { ($0.element.id, $0.offset) }
        )
        func inventoryLikeRowSort(_ a: (ShoppingEntry, GroceryItem), _ b: (ShoppingEntry, GroceryItem)) -> Bool {
            let ra = inventoryRank[a.1.inventoryTagID] ?? Int.max
            let rb = inventoryRank[b.1.inventoryTagID] ?? Int.max
            if ra != rb { return ra < rb }
            if a.1.sortOrder != b.1.sortOrder { return a.1.sortOrder < b.1.sortOrder }
            let nameA = a.1.displayName(appContentLanguage: catalogLanguage)
            let nameB = b.1.displayName(appContentLanguage: catalogLanguage)
            let cmp = nameA.localizedCaseInsensitiveCompare(nameB)
            if cmp != .orderedSame { return cmp == .orderedAscending }
            return a.0.addedAt > b.0.addedAt
        }

        let grouped: [(Tag, [(ShoppingEntry, GroceryItem)])]
        if !sortCheckedShoppingItems {
            let keys: [ShoppingGroupSortKey] = store.shoppingTags.enumerated().compactMap { order, tag in
                guard tag.kind == .shopping else { return nil }
                let rows = (bucket[tag.id] ?? []).sorted(by: inventoryLikeRowSort)
                guard !rows.isEmpty else { return nil }
                let uncheckedCount = rows.count
                return ShoppingGroupSortKey(tag: tag, rows: rows, order: order, unchecked: uncheckedCount)
            }
            grouped = keys
                .sorted { a, b in
                    let aIsDone = (a.unchecked == 0)
                    let bIsDone = (b.unchecked == 0)
                    if aIsDone != bIsDone { return bIsDone }
                    return a.order < b.order
                }
                .map { ($0.tag, $0.rows) }
        } else {
            var sections: [(Tag, [(ShoppingEntry, GroceryItem)])] = []
            let uncheckedKeys: [ShoppingGroupSortKey] = store.shoppingTags.enumerated().compactMap { order, tag in
                guard tag.kind == .shopping else { return nil }
                let rows = (bucket[tag.id] ?? []).sorted(by: inventoryLikeRowSort)
                guard !rows.isEmpty else { return nil }
                return ShoppingGroupSortKey(tag: tag, rows: rows, order: order, unchecked: rows.count)
            }
            sections.append(contentsOf: uncheckedKeys.sorted { $0.order < $1.order }.map { ($0.tag, $0.rows) })
            grouped = sections
        }

        func line(entry: ShoppingEntry, item: GroceryItem) -> String {
            let name = item.displayName(appContentLanguage: catalogLanguage)
            if entry.quantity > 1 {
                return "• \(name) \(entry.quantity)"
            }
            return "• \(name)"
        }

        // Orphan `shoppingTagID`s (not in `shoppingTags`) yield an empty `grouped`; still export lines.
        if grouped.isEmpty {
            let flat = unchecked.sorted(by: inventoryLikeRowSort).map { line(entry: $0.0, item: $0.1) }
            return flat.joined(separator: "\n")
        }

        var blocks: [String] = []
        for (tag, rows) in grouped {
            let title = tag.displayTitle(appContentLanguage: catalogLanguage)
            var lines = [title]
            for (entry, item) in rows {
                lines.append(line(entry: entry, item: item))
            }
            blocks.append(lines.joined(separator: "\n"))
        }
        return blocks.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Presents the system share sheet directly so iOS 26 uses the compact Liquid Glass card
/// (a SwiftUI `.sheet` wrapping `UIActivityViewController` forces the legacy full-height sheet).
@MainActor
enum ShoppingListSharePresentation {
    static func presentPlainText(_ text: String) {
        guard !text.isEmpty else { return }

        let controller = UIActivityViewController(
            activityItems: [text as NSString],
            applicationActivities: nil
        )

        guard let presenter = topPresenter() else { return }
        presenter.present(controller, animated: true)
    }

    private static func topPresenter() -> UIViewController? {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        else { return nil }

        var presenter = root
        while let presented = presenter.presentedViewController,
              !presented.isBeingDismissed {
            presenter = presented
        }
        return presenter
    }
}
