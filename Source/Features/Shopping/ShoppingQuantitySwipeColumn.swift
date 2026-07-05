import SwiftUI

enum ShoppingRowQuantityMetrics {
    static let slotMinWidth: CGFloat = 28
    /// Inset between the quantity column and the row content edge (matches `ShoppingRowView`).
    static let quantityEdgeInset: CGFloat = 6
    static let quantityStaticShift: CGFloat = 10
    /// Row quantity nudge: left in LTR, right in RTL.
    static let quantityListHorizontalNudge: CGFloat = 2
    /// RTL lists: nudge resting quantity toward the item name (physical right).
    static let rtlQuantityTowardNameNudge: CGFloat = 4

    /// SwiftUI `offset(x:)` follows layout direction; convert physical-axis motion for RTL lists.
    static func layoutHorizontalOffset(
        _ physicalOffset: CGFloat,
        layoutDirection: LayoutDirection
    ) -> CGFloat {
        layoutDirection == .rightToLeft ? -physicalOffset : physicalOffset
    }

    static func listQuantityStaticShift(
        revealsFromLeading: Bool,
        layoutDirection: LayoutDirection = .leftToRight
    ) -> CGFloat {
        var physical = revealsFromLeading
            ? -quantityStaticShift + quantityListHorizontalNudge
            : quantityStaticShift - quantityListHorizontalNudge
        if layoutDirection == .rightToLeft {
            physical += rtlQuantityTowardNameNudge
        }
        return physical
    }
}
