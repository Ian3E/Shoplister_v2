import SwiftUI

/// Catalog list layout (Home / Store rows) follows **library language**.
/// App chrome follows **phone language** via the root `layoutDirection` in `GroceryListApp`.
enum CatalogLayoutMirroring {
    static func catalogLayoutDirection(for catalogLanguage: AppContentLanguage) -> LayoutDirection {
        catalogLanguage == .hebrew ? .rightToLeft : .leftToRight
    }

    /// Manual row/header mirroring when Hebrew catalog is shown inside an LTR layout subtree.
    static func usesManualCatalogMirror(
        catalogLanguage: AppContentLanguage,
        layoutDirection: LayoutDirection
    ) -> Bool {
        catalogLanguage == .hebrew && layoutDirection == .leftToRight
    }

    static func catalogListUsesManualMirror(for catalogLanguage: AppContentLanguage) -> Bool {
        usesManualCatalogMirror(
            catalogLanguage: catalogLanguage,
            layoutDirection: catalogLayoutDirection(for: catalogLanguage)
        )
    }

    static func rowContentAlignment(
        catalogLanguage: AppContentLanguage,
        layoutDirection: LayoutDirection
    ) -> Alignment {
        usesManualCatalogMirror(catalogLanguage: catalogLanguage, layoutDirection: layoutDirection)
            ? .trailing
            : .leading
    }

    /// Physical screen edge for the catalog quantity pill (UIKit coordinates).
    static func quantityPillOnPhysicalLeadingEdge(
        catalogLanguage: AppContentLanguage,
        layoutDirection: LayoutDirection
    ) -> Bool {
        layoutDirection == .rightToLeft
    }

    static func quantityPillOnPhysicalLeadingEdge(for catalogLanguage: AppContentLanguage) -> Bool {
        catalogLayoutDirection(for: catalogLanguage) == .rightToLeft
    }
}

private struct CatalogListLayoutDirectionModifier: ViewModifier {
    @Environment(\.appContentLanguage) private var catalogLanguage

    func body(content: Content) -> some View {
        let direction = CatalogLayoutMirroring.catalogLayoutDirection(for: catalogLanguage)
        content
            .environment(\.layoutDirection, direction)
            // UITableView-backed List can keep a horizontal flip after RTL→LTR until remounted
            // (force-quit clears it). Identity on direction forces a clean layout pass.
            .id(direction)
    }
}

extension View {
    /// Home / Store list content: RTL for Hebrew library, LTR for English library.
    func catalogListLayoutDirection() -> some View {
        modifier(CatalogListLayoutDirectionModifier())
    }
}
