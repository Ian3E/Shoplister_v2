import SwiftUI

enum ShoppingListSpacingScaleKey: EnvironmentKey {
    /// Medium text size (`AppTextSize.medium.listSpacingScale`).
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var shoppingListSpacingScale: CGFloat {
        get { self[ShoppingListSpacingScaleKey.self] }
        set { self[ShoppingListSpacingScaleKey.self] = newValue }
    }
}

extension Color {
    /// Matches `.listStyle(.insetGrouped)` scroll chrome — use behind empty lists and tab roots so search-empty states do not drift to another system grey.
    static var catalogGroupedChromeBackground: Color {
        Color(uiColor: .systemGroupedBackground)
    }

    /// Plain Store list and row backgrounds (light: white, dark: system background).
    static var shoppingListBackground: Color {
        Color(uiColor: .systemBackground)
    }
}

/// Store list vertical spacing. Pass `scale` from `AppTextSize.listSpacingScale` (medium = 1.0).
enum ShoppingListMetrics {
    private static let baseItemRowVerticalInset: CGFloat = 8
    private static let baseGroupHeaderTopInset: CGFloat = 0
    private static let baseGroupHeaderBottomInset: CGFloat = 6
    /// Space above the group divider line (top of separator block on the lower group’s header).
    private static let baseGapAfterLastItem: CGFloat = 12
    /// Space below the divider line, before the group title (same header row).
    private static let baseGapBeforeNextTitle: CGFloat = 16
    /// Store list (headers hidden): space below the inter-group hairline before the first item row.
    private static let baseInterGroupDividerGapBelow: CGFloat = 4
    /// Plain `List` adds this between `Section`s; keep at 0 so group gaps come from metrics only.
    private static let baseInterSectionSpacing: CGFloat = 0
    static let horizontalRowInset: CGFloat = 16
    /// Checkbox column inset from the screen edge (LTR leading / RTL trailing).
    static let checkmarkEdgeInset: CGFloat = 16

    /// Scales the UIKit/SwiftUI list row floor (default 44pt); primary control for item row height.
    static func minimumListRowHeight(scale: CGFloat) -> CGFloat {
        (CatalogListRowDensity.systemListRowMinimumHeight * scale).rounded()
    }

    /// Header rows size to content; avoids the first group stretching to `minimumListRowHeight`.
    static let groupHeaderMinimumListRowHeight: CGFloat = 1

    static func itemRowVerticalInset(scale: CGFloat) -> CGFloat { baseItemRowVerticalInset * scale }
    static func groupHeaderTopInset(scale: CGFloat) -> CGFloat { baseGroupHeaderTopInset * scale }
    static func groupHeaderBottomInset(scale: CGFloat) -> CGFloat { baseGroupHeaderBottomInset * scale }
    static func gapAfterLastItem(scale: CGFloat) -> CGFloat { baseGapAfterLastItem * scale }
    static func gapBeforeNextTitle(scale: CGFloat) -> CGFloat { baseGapBeforeNextTitle * scale }
    static func interGroupDividerGapBelow(scale: CGFloat) -> CGFloat { baseInterGroupDividerGapBelow * scale }
    static var interSectionSpacing: CGFloat { baseInterSectionSpacing }

    static func itemRowInsets(scale: CGFloat, hebrew: Bool = false, extraTop: CGFloat = 0) -> EdgeInsets {
        EdgeInsets(
            top: itemRowVerticalInset(scale: scale) + extraTop,
            leading: hebrew ? horizontalRowInset : checkmarkEdgeInset,
            bottom: itemRowVerticalInset(scale: scale),
            trailing: hebrew ? checkmarkEdgeInset : horizontalRowInset
        )
    }

    /// Vertical padding applied inside the row so `listRowInsets` can stay horizontal-only (full-cell taps).
    static func itemRowVerticalContentPadding(scale: CGFloat, extraTop: CGFloat = 0) -> EdgeInsets {
        EdgeInsets(
            top: itemRowVerticalInset(scale: scale) + extraTop,
            leading: 0,
            bottom: itemRowVerticalInset(scale: scale),
            trailing: 0
        )
    }

    /// `listRowInsets` for item rows: horizontal gutter only; vertical spacing is internal padding.
    static func itemRowHorizontalListInsets(scale: CGFloat, hebrew: Bool = false) -> EdgeInsets {
        EdgeInsets(
            top: 0,
            leading: hebrew ? horizontalRowInset : checkmarkEdgeInset,
            bottom: 0,
            trailing: hebrew ? checkmarkEdgeInset : horizontalRowInset
        )
    }

    /// Extra horizontal inset for Home item rows (on top of `horizontalRowInset`, which matches group headers).
    static let homeCatalogItemRowExtraHorizontalInset: CGFloat = 12

    static func homeCatalogItemRowHorizontalInset(scale: CGFloat) -> CGFloat {
        horizontalRowInset + homeCatalogItemRowExtraHorizontalInset
    }

    static func homeCatalogItemRowInsets(scale: CGFloat) -> EdgeInsets {
        let horizontal = homeCatalogItemRowHorizontalInset(scale: scale)
        return EdgeInsets(
            top: itemRowVerticalInset(scale: scale),
            leading: horizontal,
            bottom: itemRowVerticalInset(scale: scale),
            trailing: horizontal
        )
    }

    static func homeCatalogItemRowVerticalContentPadding(scale: CGFloat) -> EdgeInsets {
        EdgeInsets(
            top: itemRowVerticalInset(scale: scale),
            leading: 0,
            bottom: itemRowVerticalInset(scale: scale),
            trailing: 0
        )
    }

    static func homeCatalogItemRowHorizontalListInsets(scale: CGFloat) -> EdgeInsets {
        let horizontal = homeCatalogItemRowHorizontalInset(scale: scale)
        return EdgeInsets(top: 0, leading: horizontal, bottom: 0, trailing: horizontal)
    }

    static func groupHeaderRowInsets(scale: CGFloat) -> EdgeInsets {
        EdgeInsets(
            top: groupHeaderTopInset(scale: scale),
            leading: horizontalRowInset,
            bottom: groupHeaderBottomInset(scale: scale),
            trailing: horizontalRowInset
        )
    }

}

/// Spacing above a group title: gap, divider (visible or clear), gap — same structure for every section.
struct CatalogGroupHeaderSeparatorPrefix: View {
    @Environment(\.shoppingListSpacingScale) private var environmentSpacingScale
    var showsVisibleDivider: Bool
    /// When set, overrides `shoppingListSpacingScale` (e.g. Settings text-size preview).
    var spacingScale: CGFloat?

    private var resolvedSpacingScale: CGFloat {
        spacingScale ?? environmentSpacingScale
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: ShoppingListMetrics.gapAfterLastItem(scale: resolvedSpacingScale))
            Rectangle()
                .fill(showsVisibleDivider ? Color(uiColor: .separator) : .clear)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
            Color.clear
                .frame(height: ShoppingListMetrics.gapBeforeNextTitle(scale: resolvedSpacingScale))
        }
    }
}

/// Shared group header typography (Home + Store).
enum CatalogGroupHeaderChrome {
    static let titleFont: Font = .title3.weight(.heavy)

    static var titleColor: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? .secondaryLabel
                : UIColor(white: 0.28, alpha: 1)
        })
    }
}

/// Trailing chrome width on Store rows/headers so quantities line up with the group chevron.
enum ShoppingListChrome {
    static let chevronColumnWidth: CGFloat = 22
    static let countChevronSpacing: CGFloat = 4
    static let trailingQuantityFont: Font = .body.weight(.bold)

}

/// Home quantity-pill padding tweaks for compact Dynamic Type sizes.
enum CatalogListRowDensity {
    /// Standard list row minimum before `listSpacingScale` is applied.
    static let systemListRowMinimumHeight: CGFloat = 44

    static let quantityPillHorizontalPadding: CGFloat = 6

    /// Extra insets for material/plain live pills (+2×2 vertical, +2×4 horizontal on base padding).
    static let quantityPillExpandedVerticalPadding: CGFloat = 4
    static let quantityPillExpandedHorizontalPadding: CGFloat = 8
    static let quantityPillLiveEdgeInsetExtra: CGFloat = 2

    static var quantityPillLiveHorizontalPadding: CGFloat {
        quantityPillHorizontalPadding + quantityPillExpandedHorizontalPadding + quantityPillLiveEdgeInsetExtra
    }

    static func quantityPillVerticalPadding(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        return 1
    }

    static func quantityPillLiveVerticalPadding(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        quantityPillVerticalPadding(for: dynamicTypeSize)
            + quantityPillExpandedVerticalPadding
            + quantityPillLiveEdgeInsetExtra
    }

    static func quantityPillMinHeight(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small: return 16
        default: return 18
        }
    }

    /// Minimum pill / reserved column width (single-digit quantities).
    static let quantityPillSlotMinWidth: CGFloat = 44
    /// Extra width reserved toward the row edge for catalog pill positioning.
    static let quantityPillHorizontalNudge: CGFloat = 5

    /// Approximate subheadline monospaced digit width for gutter sizing.
    private static let quantityPillDigitWidth: CGFloat = 11

    /// Title gutter and pill column width from digit count (matches pill `minWidth` + padding).
    static func quantityPillReservedWidth(forQuantity quantity: Int) -> CGFloat {
        let digits = max(1, String(quantity).count)
        let labelWidth = quantityPillDigitWidth * CGFloat(digits)
        return max(quantityPillSlotMinWidth, labelWidth + quantityPillHorizontalPadding * 2)
    }

    static func quantityPillLiveReservedWidth(forQuantity quantity: Int) -> CGFloat {
        let digits = max(1, String(quantity).count)
        let labelWidth = quantityPillDigitWidth * CGFloat(digits)
        return max(quantityPillSlotMinWidth, labelWidth + quantityPillLiveHorizontalPadding * 2)
    }

    /// Intrinsic pill height (label + padding).
    static func quantityPillSlotHeight(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        quantityPillMinHeight(for: dynamicTypeSize)
            + quantityPillVerticalPadding(for: dynamicTypeSize) * 2
    }

    /// Content band inside a Store-style row with vertical `listRowInsets`.
    static func catalogPlainListItemContentHeight(scale: CGFloat) -> CGFloat {
        ShoppingListMetrics.minimumListRowHeight(scale: scale)
            - ShoppingListMetrics.itemRowVerticalInset(scale: scale) * 2
    }
}

/// Toolbar control tap targets — icon circles and text capsules.
enum CatalogToolbarTapChrome {
    static let iconTapDiameter: CGFloat = 36
    static let textHorizontalPadding: CGFloat = 10
    static let textVerticalPadding: CGFloat = 8
}

// MARK: - Row style modifiers (read `shoppingListSpacingScale` from environment)

private struct ShoppingListDensityModifier: ViewModifier {
    @Environment(\.shoppingListSpacingScale) private var spacingScale

    func body(content: Content) -> some View {
        content.environment(
            \.defaultMinListRowHeight,
            ShoppingListMetrics.minimumListRowHeight(scale: spacingScale)
        )
    }
}

private struct ShoppingListItemRowStyleModifier: ViewModifier {
    @Environment(\.shoppingListSpacingScale) private var spacingScale
    let hebrew: Bool
    var extraTopInset: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(
                ShoppingListMetrics.itemRowVerticalContentPadding(
                    scale: spacingScale,
                    extraTop: extraTopInset
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .listRowInsets(
                ShoppingListMetrics.itemRowHorizontalListInsets(
                    scale: spacingScale,
                    hebrew: hebrew
                )
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.shoppingListBackground)
    }
}

private struct CatalogGroupHeaderRowStyleModifier: ViewModifier {
    @Environment(\.shoppingListSpacingScale) private var spacingScale

    func body(content: Content) -> some View {
        content
            .listRowInsets(ShoppingListMetrics.groupHeaderRowInsets(scale: spacingScale))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.shoppingListBackground)
            .environment(\.defaultMinListRowHeight, ShoppingListMetrics.groupHeaderMinimumListRowHeight)
    }
}

private struct HomeCatalogListItemRowStyleModifier: ViewModifier {
    @Environment(\.shoppingListSpacingScale) private var spacingScale

    func body(content: Content) -> some View {
        content
            .padding(ShoppingListMetrics.homeCatalogItemRowVerticalContentPadding(scale: spacingScale))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .listRowInsets(ShoppingListMetrics.homeCatalogItemRowHorizontalListInsets(scale: spacingScale))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

extension View {
    /// Full-bleed fill for catalog tab roots and empty search (inset-grouped list parity).
    func catalogGroupedChromeBackdrop() -> some View {
        background {
            Color.catalogGroupedChromeBackground
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    /// Plain Store / Home `List`: applies row-height floor from `shoppingListSpacingScale`.
    func shoppingListDensity() -> some View {
        modifier(ShoppingListDensityModifier())
    }

    func shoppingListItemRowStyle(hebrew: Bool = false, extraTopInset: CGFloat = 0) -> some View {
        modifier(ShoppingListItemRowStyleModifier(hebrew: hebrew, extraTopInset: extraTopInset))
    }

    func shoppingListGroupHeaderRowStyle() -> some View {
        modifier(CatalogGroupHeaderRowStyleModifier())
    }

    func catalogGroupHeaderRowStyle() -> some View {
        shoppingListGroupHeaderRowStyle()
    }

    /// List rows often shrink-wrap to label height; expand content alignment to the full list cell.
    func listRowFullBleedHitArea(alignment: Alignment = .center) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }

    /// List rows often shrink-wrap SwiftUI content; overlay tap target matches the full cell width/height.
    func groupHeaderRowToggleOverlay(action: @escaping () -> Void) -> some View {
        overlay {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture(perform: action)
        }
    }

    func catalogListItemRowStyle(hebrew: Bool = false) -> some View {
        shoppingListItemRowStyle(hebrew: hebrew)
    }

    func homeCatalogListItemRowStyle() -> some View {
        modifier(HomeCatalogListItemRowStyleModifier())
    }

    func catalogToolbarCircularTapTarget() -> some View {
        frame(
            width: CatalogToolbarTapChrome.iconTapDiameter,
            height: CatalogToolbarTapChrome.iconTapDiameter
        )
        .contentShape(Circle())
    }

    func catalogToolbarCapsuleTapTarget() -> some View {
        padding(.horizontal, CatalogToolbarTapChrome.textHorizontalPadding)
            .padding(.vertical, CatalogToolbarTapChrome.textVerticalPadding)
            .contentShape(Capsule())
    }

}

extension View {
    /// By default SwiftUI aligns list row separators with the first `Text`. When a row starts with
    /// controls (e.g. quantity pill) and Hebrew layout, separators can shrink to the name width.
    /// Pin separator edges to the row’s leading/trailing bounds instead.
    @ViewBuilder
    func catalogListRowSeparatorFullWidth(_ active: Bool) -> some View {
        if active {
            self
                .alignmentGuide(.listRowSeparatorLeading) { dimensions in dimensions[.leading] }
                .alignmentGuide(.listRowSeparatorTrailing) { dimensions in dimensions[.trailing] }
        } else {
            self
        }
    }

    /// iOS 26+: **soft** scroll-edge treatment for the **top** only. Bottom edge is left at system default.
    @ViewBuilder
    func scrollEdgeSoftTopIfAvailable(when enabled: Bool = true) -> some View {
        if enabled, #available(iOS 26.0, *) {
            self.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self
        }
    }
}
