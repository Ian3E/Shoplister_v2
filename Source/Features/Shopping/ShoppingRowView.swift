import SwiftUI
import UIKit

struct ShoppingRowView: View {
    private static let rowContentSpacing: CGFloat = 12
    private static let quantityEdgeInset: CGFloat = ShoppingQuantitySwipeMetrics.quantityEdgeInset
    private static let uncheckedSymbolName = "app"
    private static let checkedSymbolName = "checkmark.app.fill"

    @Environment(\.appContentLanguage) private var catalogLanguage
    @Environment(\.appTheme) private var appTheme
    @Environment(\.layoutDirection) private var layoutDirection
    @EnvironmentObject private var quantitySwipeState: ShoppingRowQuantitySwipeState

    let entry: ShoppingEntry
    let item: GroceryItem
    var quantitySwipeEnabled: Bool = false
    var onIncrementQuantity: (() -> Void)?

    private var checkmarkFont: Font {
        let pointSize = UIFont.preferredFont(forTextStyle: .body).pointSize * 1.25
        return .system(size: pointSize)
    }

    private var showsQuantity: Bool {
        entry.quantity > 1 && !entry.isChecked
    }

    private var usesManualMirror: Bool {
        CatalogLayoutMirroring.catalogListUsesManualMirror(for: catalogLanguage)
    }

    private var revealsQuantityFromLeading: Bool {
        CatalogLayoutMirroring.quantityPillOnPhysicalLeadingEdge(for: catalogLanguage)
    }

    private var quantityEdgePadding: Edge.Set {
        revealsQuantityFromLeading ? .leading : .trailing
    }

    private var isQuantitySwipeActive: Bool {
        quantitySwipeEnabled && !entry.isChecked && onIncrementQuantity != nil
    }

    private var quantityStaticShift: CGFloat {
        ShoppingQuantitySwipeMetrics.layoutHorizontalOffset(
            ShoppingQuantitySwipeMetrics.listQuantityStaticShift(
                revealsFromLeading: revealsQuantityFromLeading,
                layoutDirection: layoutDirection
            ),
            layoutDirection: layoutDirection
        )
    }

    private var showsQuantitySwipeDigit: Bool {
        showsQuantity || quantitySwipeState.digitReleaseOffset != nil
    }

    var body: some View {
        Group {
            if usesManualMirror {
                hebrewRow
            } else {
                englishRow
            }
        }
        .listRowFullBleedHitArea()
        .contentShape(Rectangle())
        .onChange(of: entry.id) { _, _ in
            quantitySwipeState.reset()
        }
        .onChange(of: entry.isChecked) { _, isChecked in
            if isChecked {
                quantitySwipeState.reset()
            }
        }
    }

    /// Mirror of `englishRow`: quantity on the far left, checkmark on the far right.
    private var hebrewRow: some View {
        HStack(alignment: .center, spacing: Self.rowContentSpacing) {
            leadingQuantitySlot

            Spacer(minLength: 0)

            Text(item.displayName(appContentLanguage: catalogLanguage))
                .font(.body)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .strikethrough(entry.isChecked, color: .secondary)
                .foregroundStyle(entry.isChecked ? .secondary : .primary)

            checkmarkImage
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var englishRow: some View {
        HStack(alignment: .center, spacing: Self.rowContentSpacing) {
            checkmarkImage

            Text(item.displayName(appContentLanguage: catalogLanguage))
                .font(.body)
                .lineLimit(1)
                .strikethrough(entry.isChecked, color: .secondary)
                .foregroundStyle(entry.isChecked ? .secondary : .primary)

            Spacer(minLength: 0)

            trailingQuantitySlot
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var leadingQuantitySlot: some View {
        if isQuantitySwipeActive {
            quantitySwipeColumn(
                revealsFromLeading: revealsQuantityFromLeading,
                edgePadding: quantityEdgePadding
            )
        } else if showsQuantity {
            quantityLabel(entry.quantity)
                .padding(quantityEdgePadding, Self.quantityEdgeInset)
        }
    }

    @ViewBuilder
    private var trailingQuantitySlot: some View {
        if isQuantitySwipeActive {
            quantitySwipeColumn(
                revealsFromLeading: revealsQuantityFromLeading,
                edgePadding: quantityEdgePadding
            )
        } else if showsQuantity {
            quantityLabel(entry.quantity)
                .padding(quantityEdgePadding, Self.quantityEdgeInset)
        }
    }

    private var checkmarkImage: some View {
        Image(systemName: entry.isChecked ? Self.checkedSymbolName : Self.uncheckedSymbolName)
            .font(checkmarkFont)
            .foregroundStyle(appTheme.color)
    }

    private func quantityLabel(_ quantity: Int) -> some View {
        Text("\(quantity)")
            .font(ShoppingListChrome.trailingQuantityFont.monospacedDigit())
            .foregroundStyle(appTheme.color)
            .frame(minWidth: ShoppingQuantitySwipeMetrics.slotMinWidth)
            .offset(x: quantityStaticShift)
    }

    private func quantitySwipeColumn(
        revealsFromLeading: Bool,
        edgePadding: Edge.Set
    ) -> some View {
        ShoppingQuantitySwipeColumn(
            quantity: entry.quantity,
            showsQuantityDigit: showsQuantitySwipeDigit,
            revealsFromLeading: revealsFromLeading,
            rawDragAmount: quantitySwipeState.dragAmount,
            releaseDigitOffset: quantitySwipeState.digitReleaseOffset,
            fadingInQuantityDigit: quantitySwipeState.digitFadingIn
        )
        .padding(edgePadding, Self.quantityEdgeInset)
    }
}
