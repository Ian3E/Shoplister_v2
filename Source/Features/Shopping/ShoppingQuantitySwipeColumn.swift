import SwiftUI
import UIKit

private struct AnimatableHorizontalOffset: AnimatableModifier {
    var x: CGFloat

    var animatableData: CGFloat {
        get { x }
        set { x = newValue }
    }

    func body(content: Content) -> some View {
        content.offset(x: x)
    }
}

enum ShoppingQuantitySwipeMetrics {
    static let threshold: CGFloat = 30
    static let horizontalDominanceRatio: CGFloat = 2.0
    static let slotMinWidth: CGFloat = 28
    /// Inset between the quantity column and the row content edge (matches `ShoppingRowView`).
    static let quantityEdgeInset: CGFloat = 6
    static let quantityStaticShift: CGFloat = 10

    static var gestureCaptureWidth: CGFloat {
        slotMinWidth + quantityEdgeInset
    }

    /// Context-menu overlay quantity-edge strip width (list inset + capture zone).
    static var contextMenuQuantityEdgePassThroughWidth: CGFloat {
        gestureCaptureWidth + ShoppingListMetrics.horizontalRowInset + quantityEdgeInset
    }

    static func rawDragAmount(
        translation: CGPoint,
        revealsFromLeading: Bool
    ) -> CGFloat {
        revealsFromLeading ? max(0, translation.x) : max(0, -translation.x)
    }

    static func draggedQuantityDigitOffset(
        rawDragAmount: CGFloat,
        revealsFromLeading: Bool,
        layoutDirection: LayoutDirection
    ) -> CGFloat {
        let visualDrag = visualDragAmount(for: rawDragAmount)
        let travel = revealsFromLeading ? visualDrag : -visualDrag
        let shift = listQuantityStaticShift(
            revealsFromLeading: revealsFromLeading,
            layoutDirection: layoutDirection
        )
        return layoutHorizontalOffset(travel + shift, layoutDirection: layoutDirection)
    }

    /// SwiftUI `offset(x:)` follows layout direction; convert physical-axis motion for RTL lists.
    static func layoutHorizontalOffset(
        _ physicalOffset: CGFloat,
        layoutDirection: LayoutDirection
    ) -> CGFloat {
        layoutDirection == .rightToLeft ? -physicalOffset : physicalOffset
    }
    /// Row quantity nudge: left in LTR, right in RTL.
    static let quantityListHorizontalNudge: CGFloat = 2
    /// RTL lists: nudge resting quantity toward the item name (physical right).
    static let rtlQuantityTowardNameNudge: CGFloat = 4

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
    /// Finger travel beyond `threshold` maps to visual travel at this rate (1 = same speed).
    static let postThresholdResistance: CGFloat = 0.3

    static func progress(rawDrag: CGFloat) -> CGFloat {
        min(1, max(0, rawDrag / threshold))
    }

    static func hasReachedThreshold(rawDrag: CGFloat) -> Bool {
        rawDrag >= threshold
    }

    /// 1:1 with finger up to threshold; slowed beyond.
    static func visualDragAmount(for rawDrag: CGFloat) -> CGFloat {
        let raw = max(0, rawDrag)
        guard raw > threshold else { return raw }
        let excess = raw - threshold
        return threshold + excess * postThresholdResistance
    }
}

/// Per-row swipe chrome state shared between `ShoppingRowView` and the UIKit context-menu overlay.
@MainActor
final class ShoppingRowQuantitySwipeState: ObservableObject {
    @Published var dragAmount: CGFloat = 0
    @Published var thresholdHapticFired = false
    @Published var digitReleaseOffset: CGFloat?
    @Published var digitFadingIn = false

    func reset() {
        dragAmount = 0
        thresholdHapticFired = false
        digitReleaseOffset = nil
        digitFadingIn = false
    }

    func handleDragChanged(_ amount: CGFloat, isActive: Bool) {
        guard isActive else { return }

        dragAmount = amount

        let reachedThreshold = ShoppingQuantitySwipeMetrics.hasReachedThreshold(rawDrag: amount)
        if reachedThreshold, !thresholdHapticFired {
            thresholdHapticFired = true
            AppHaptics.impact(.medium)
        } else if !reachedThreshold {
            thresholdHapticFired = false
        }
    }

    func handleDragEnded(
        reachedThreshold: Bool,
        isActive: Bool,
        entryQuantity: Int,
        revealsFromLeading: Bool,
        layoutDirection: LayoutDirection,
        onIncrement: () -> Void
    ) {
        guard isActive else { return }

        thresholdHapticFired = false

        if reachedThreshold {
            let staticShift = ShoppingQuantitySwipeMetrics.layoutHorizontalOffset(
                ShoppingQuantitySwipeMetrics.listQuantityStaticShift(
                    revealsFromLeading: revealsFromLeading,
                    layoutDirection: layoutDirection
                ),
                layoutDirection: layoutDirection
            )
            if entryQuantity == 1 {
                onIncrement()
                digitFadingIn = true
                digitReleaseOffset = staticShift
                withAnimation(.snappy) {
                    dragAmount = 0
                } completion: {
                    self.digitReleaseOffset = nil
                    self.digitFadingIn = false
                }
            } else {
                digitReleaseOffset = ShoppingQuantitySwipeMetrics.draggedQuantityDigitOffset(
                    rawDragAmount: dragAmount,
                    revealsFromLeading: revealsFromLeading,
                    layoutDirection: layoutDirection
                )
                onIncrement()
                withAnimation(.snappy) {
                    dragAmount = 0
                    digitReleaseOffset = staticShift
                } completion: {
                    self.digitReleaseOffset = nil
                }
            }
        } else {
            withAnimation(.snappy) {
                dragAmount = 0
            }
        }
    }
}

/// Quantity-edge chrome: digit slides with drag; `arrow.down.app.fill` (rotated) fades/scales in the fixed slot.
struct ShoppingQuantitySwipeColumn: View {
    let quantity: Int
    let showsQuantityDigit: Bool
    /// When true, quantity sits on the leading edge (Hebrew) and swipe is toward the right.
    let revealsFromLeading: Bool
    /// Uncapped finger drag toward the reveal edge.
    let rawDragAmount: CGFloat
    /// When set, digit uses this offset instead of drag-derived offset (post-release slide-back).
    let releaseDigitOffset: CGFloat?
    /// Qty 1→2: crossfade digit in as swipe chrome fades out on release.
    let fadingInQuantityDigit: Bool

    @Environment(\.appTheme) private var appTheme
    @Environment(\.layoutDirection) private var layoutDirection

    private var revealProgress: CGFloat {
        ShoppingQuantitySwipeMetrics.progress(rawDrag: rawDragAmount)
    }

    private var visualDragAmount: CGFloat {
        ShoppingQuantitySwipeMetrics.visualDragAmount(for: rawDragAmount)
    }

    private var quantityStaticShift: CGFloat {
        ShoppingQuantitySwipeMetrics.layoutHorizontalOffset(
            ShoppingQuantitySwipeMetrics.listQuantityStaticShift(
                revealsFromLeading: revealsFromLeading,
                layoutDirection: layoutDirection
            ),
            layoutDirection: layoutDirection
        )
    }

    private var digitOffset: CGFloat {
        if let releaseDigitOffset {
            return releaseDigitOffset
        }
        let travel = revealsFromLeading ? visualDragAmount : -visualDragAmount
        let physicalOffset = travel + ShoppingQuantitySwipeMetrics.listQuantityStaticShift(
            revealsFromLeading: revealsFromLeading,
            layoutDirection: layoutDirection
        )
        return ShoppingQuantitySwipeMetrics.layoutHorizontalOffset(
            physicalOffset,
            layoutDirection: layoutDirection
        )
    }

    var body: some View {
        ZStack {
            Image(systemName: "arrow.down.app.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(appTheme.color)
                .opacity(revealProgress)
                .scaleEffect(0.5 + 0.5 * revealProgress)
                .rotationEffect(.degrees(180))
                .offset(x: quantityStaticShift)
                .animation(.snappy, value: rawDragAmount)
                .allowsHitTesting(false)

            if showsQuantityDigit {
                Text("\(quantity)")
                    .font(ShoppingListChrome.trailingQuantityFont.monospacedDigit())
                    .foregroundStyle(appTheme.color)
                    .contentTransition(.identity)
                    .opacity(fadingInQuantityDigit ? 1 - revealProgress : 1)
                    .modifier(AnimatableHorizontalOffset(x: digitOffset))
                    .animation(.snappy, value: rawDragAmount)
            }
        }
        .frame(minWidth: ShoppingQuantitySwipeMetrics.slotMinWidth)
    }
}
