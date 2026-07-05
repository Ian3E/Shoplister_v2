import SwiftUI

/// Live Home / pull-to-add quantity pill — light/dark capsule, subtle edge, soft shadow (no glass button halo).
struct QuantityPillMaterialStyle: ViewModifier {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.shoppingListSpacingScale) private var spacingScale

    private var pillFill: Color {
        colorScheme == .dark ? Color(white: 0.1) : .white
    }

    private var pillBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.95)
    }

    private var pillShadow: Color {
        colorScheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.1)
    }

    func body(content: Content) -> some View {
        content
            .buttonStyle(.plain)
            .foregroundStyle(appTheme.color)
            .padding(.horizontal, CatalogListRowDensity.quantityPillLiveHorizontalPadding(scale: spacingScale))
            .padding(.vertical, CatalogListRowDensity.quantityPillLiveVerticalPadding(scale: spacingScale))
            .background {
                Capsule(style: .continuous)
                    .fill(pillFill)
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(pillBorder, lineWidth: 1)
                    }
                    .shadow(color: pillShadow, radius: 2.5, y: 1.5)
            }
    }
}
