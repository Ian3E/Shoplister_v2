import SwiftUI
import UIKit

struct ShoppingRowView: View {
    private static let rowContentSpacing: CGFloat = 12
    private static let quantityEdgeInset: CGFloat = ShoppingRowQuantityMetrics.quantityEdgeInset
    private static let uncheckedSymbolName = "app"
    private static let checkedSymbolName = "checkmark.app.fill"

    @Environment(\.appContentLanguage) private var catalogLanguage
    @Environment(\.appTheme) private var appTheme
    @Environment(\.layoutDirection) private var layoutDirection

    let entry: ShoppingEntry
    let item: GroceryItem

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

    private var quantityStaticShift: CGFloat {
        ShoppingRowQuantityMetrics.layoutHorizontalOffset(
            ShoppingRowQuantityMetrics.listQuantityStaticShift(
                revealsFromLeading: revealsQuantityFromLeading,
                layoutDirection: layoutDirection
            ),
            layoutDirection: layoutDirection
        )
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
        if showsQuantity {
            quantityLabel(entry.quantity)
                .padding(quantityEdgePadding, Self.quantityEdgeInset)
        }
    }

    @ViewBuilder
    private var trailingQuantitySlot: some View {
        if showsQuantity {
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
            .frame(minWidth: ShoppingRowQuantityMetrics.slotMinWidth)
            .offset(x: quantityStaticShift)
    }
}
