import SwiftUI
import UIKit

/// Semantic font slots for quantity-pill digit and stepper chrome.
enum QuantityPillFontSlot: String, CaseIterable, Identifiable {
    case subheadline
    case callout
    case body
    case headline
    case title3
    case title2
    case title

    var id: String { rawValue }

    var label: String {
        switch self {
        case .subheadline: return "Subheadline"
        case .callout: return "Callout"
        case .body: return "Body"
        case .headline: return "Headline"
        case .title3: return "Title 3"
        case .title2: return "Title 2"
        case .title: return "Title"
        }
    }

    func font(monospacedDigit: Bool = false, weight: Font.Weight = .semibold) -> Font {
        let base: Font = switch self {
        case .subheadline: .subheadline
        case .callout: .callout
        case .body: .body
        case .headline: .headline
        case .title3: .title3
        case .title2: .title2
        case .title: .title
        }
        let styled = base.weight(weight)
        return monospacedDigit ? styled.monospacedDigit() : styled
    }

    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .subheadline: .subheadline
        case .callout: .callout
        case .body: .body
        case .headline: .headline
        case .title3: .title3
        case .title2: .title2
        case .title: .title1
        }
    }

    func relativePointSize(to other: QuantityPillFontSlot) -> CGFloat {
        let size = UIFont.preferredFont(forTextStyle: uiTextStyle).pointSize
        let otherSize = UIFont.preferredFont(forTextStyle: other.uiTextStyle).pointSize
        guard otherSize > 0 else { return 1 }
        return size / otherSize
    }
}

/// Tunable glass quantity-pill layout (property names mirror `CatalogListRowDensity`).
struct QuantityPillLayoutMetrics: Equatable {
    var quantityPillCollapsedNumberHorizontalPadding: CGFloat
    var quantityPillExpandedNumberHorizontalPadding: CGFloat
    var quantityPillStepperOuterPadding: CGFloat
    var quantityPillCapsuleVerticalPadding: CGFloat
    var quantityPillCapsuleExpandedVerticalPaddingExtra: CGFloat
    var quantityPillStepperSymbolWidth: CGFloat
    var quantityPillExpandedStepperSymbolWidth: CGFloat
    var quantityPillDigitWidth: CGFloat
    var quantityPillExpandedDigitWidth: CGFloat
    var quantityPillCollapsedNumberFont: QuantityPillFontSlot
    var quantityPillExpandedNumberFont: QuantityPillFontSlot
    var quantityPillCollapsedStepperFont: QuantityPillFontSlot
    var quantityPillExpandedStepperFont: QuantityPillFontSlot
    var stepperCollapsedScale: CGFloat

    static var production: QuantityPillLayoutMetrics {
        QuantityPillLayoutMetrics(
            quantityPillCollapsedNumberHorizontalPadding: CatalogListRowDensity.quantityPillCollapsedNumberHorizontalPadding,
            quantityPillExpandedNumberHorizontalPadding: CatalogListRowDensity.quantityPillExpandedNumberHorizontalPadding,
            quantityPillStepperOuterPadding: CatalogListRowDensity.quantityPillStepperOuterPadding,
            quantityPillCapsuleVerticalPadding: CatalogListRowDensity.quantityPillCapsuleVerticalPadding,
            quantityPillCapsuleExpandedVerticalPaddingExtra: CatalogListRowDensity.quantityPillCapsuleExpandedVerticalPaddingExtra,
            quantityPillStepperSymbolWidth: CatalogListRowDensity.quantityPillStepperSymbolWidth,
            quantityPillExpandedStepperSymbolWidth: CatalogListRowDensity.quantityPillExpandedStepperSymbolWidth,
            quantityPillDigitWidth: 11,
            quantityPillExpandedDigitWidth: 12,
            quantityPillCollapsedNumberFont: .callout,
            quantityPillExpandedNumberFont: .title3,
            quantityPillCollapsedStepperFont: .title3,
            quantityPillExpandedStepperFont: .title2,
            stepperCollapsedScale: 0.2
        )
    }

    func numberHorizontalPadding(isExpanded: Bool, scale: CGFloat) -> CGFloat {
        isExpanded
            ? quantityPillExpandedNumberHorizontalPadding
            : quantityPillCollapsedNumberHorizontalPadding * scale
    }

    func stepperOuterPadding(scale: CGFloat) -> CGFloat {
        quantityPillStepperOuterPadding * scale
    }

    func capsuleVerticalPadding(isExpanded: Bool, scale: CGFloat) -> CGFloat {
        let vertical: CGFloat
        if abs(scale - 1.0) < 0.01 {
            vertical = quantityPillCapsuleVerticalPadding
        } else {
            vertical = CatalogListRowDensity.quantityPillCapsuleVerticalPadding(forListSpacingScale: scale)
        }
        let expandedExtra = isExpanded ? quantityPillCapsuleExpandedVerticalPaddingExtra * scale : 0
        return vertical + expandedExtra
    }

    func stepperSymbolWidth(isExpanded: Bool) -> CGFloat {
        isExpanded ? quantityPillExpandedStepperSymbolWidth : quantityPillStepperSymbolWidth
    }

    func expandedNumberScaleFactor() -> CGFloat {
        quantityPillExpandedNumberFont.relativePointSize(to: quantityPillCollapsedNumberFont)
    }

    func collapsedRenderedWidth(forQuantity quantity: Int, scale: CGFloat) -> CGFloat {
        let digits = max(1, String(quantity).count)
        let labelWidth = quantityPillDigitWidth * CGFloat(digits)
        return labelWidth + numberHorizontalPadding(isExpanded: false, scale: scale) * 2
    }

    func expandedReservedWidth(forQuantity quantity: Int, scale: CGFloat) -> CGFloat {
        let digits = max(1, String(quantity).count)
        let labelWidth = quantityPillExpandedDigitWidth * CGFloat(digits)
        let numberPadding = numberHorizontalPadding(isExpanded: true, scale: scale) * 2
        let stepperOuter = stepperOuterPadding(scale: scale) * 2
        let steppers = quantityPillExpandedStepperSymbolWidth * 2
        return labelWidth + numberPadding + stepperOuter + steppers
    }
}
