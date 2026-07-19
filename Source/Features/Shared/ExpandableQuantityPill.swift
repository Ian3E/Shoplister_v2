import SwiftUI
import UIKit

/// Shared expand/collapse timing for quantity pills and matching row gutters.
enum QuantityPillChromeTiming {
    static let collapseDelaySeconds: TimeInterval = 2
    static let expandCollapse = Animation.spring(response: 0.28, dampingFraction: 0.82)
    static let tapPulsePeakScale: CGFloat = 1.1
    static let tapPulseExpand = Animation.spring(response: 0.22, dampingFraction: 0.62)
    static let tapPulseSettle = Animation.spring(response: 0.28, dampingFraction: 0.82)

    @MainActor
    static func expandAfterAdd(
        itemID: UUID,
        guardInShopping: @MainActor () -> Bool,
        setExpandedItemID: @MainActor (UUID) -> Void
    ) {
        guard AppLibraryAutoExpandQuantityPicker.isEnabled else { return }
        guard guardInShopping() else { return }
        withAnimation(expandCollapse) {
            setExpandedItemID(itemID)
        }
    }
}

private enum ExpandableQuantityPillTiming {
    static var collapseDelaySeconds: TimeInterval { QuantityPillChromeTiming.collapseDelaySeconds }
    static var animation: Animation { QuantityPillChromeTiming.expandCollapse }
}

enum ExpandableQuantityPillStyle {
    case glass
    case material
}

private struct ExpandedQuantityPillItemIDKey: EnvironmentKey {
    static let defaultValue: UUID? = nil
}

extension EnvironmentValues {
    var expandedQuantityPillItemID: UUID? {
        get { self[ExpandedQuantityPillItemIDKey.self] }
        set { self[ExpandedQuantityPillItemIDKey.self] = newValue }
    }
}

/// Home / pull-to-add quantity pill: tap to expand inward from the screen edge, then adjust with +/−.
struct ExpandableQuantityPill: View {
    let quantity: Int
    let style: ExpandableQuantityPillStyle
    let usesLivePadding: Bool
    let edgeAlignment: HorizontalAlignment
    @Binding var isExpanded: Bool
    var layoutMetrics: QuantityPillLayoutMetrics? = nil
    var schedulesAutoCollapse: Bool = true
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onRemove: () -> Void

    @Environment(\.appTheme) private var appTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.shoppingListSpacingScale) private var spacingScale
    @State private var collapseTask: Task<Void, Never>?
    @State private var tapPulseScale: CGFloat = 1

    private var usesGlassChrome: Bool {
        style == .glass
    }

    private var activeMetrics: QuantityPillLayoutMetrics {
        layoutMetrics ?? .production
    }

    private var collapsedMinWidth: CGFloat {
        if usesLivePadding {
            return CatalogListRowDensity.quantityPillLiveReservedWidth(
                forQuantity: quantity,
                scale: spacingScale
            )
        }
        return activeMetrics.collapsedRenderedWidth(forQuantity: quantity, scale: spacingScale)
    }

    private var expandedMinWidth: CGFloat {
        if usesLivePadding {
            return CatalogListRowDensity.quantityPillLiveExpandedReservedWidth(
                forQuantity: quantity,
                scale: spacingScale
            )
        }
        return activeMetrics.expandedReservedWidth(forQuantity: quantity, scale: spacingScale)
    }

    private var pillMinWidth: CGFloat {
        isExpanded ? expandedMinWidth : collapsedMinWidth
    }

    var body: some View {
        pillContent
            .environment(\.layoutDirection, .leftToRight)
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: pillMinWidth, alignment: .center)
            .modifier(QuantityPillUnifiedChrome(style: style, usesLivePadding: usesLivePadding))
            .scaleEffect(tapPulseScale)
            .overlay {
                if !isExpanded {
                    Capsule(style: .continuous)
                        .fill(.clear)
                        .contentShape(Capsule(style: .continuous))
                        .onTapGesture(perform: expandPill)
                }
            }
            .accessibilityElement(children: isExpanded ? .contain : .ignore)
            .accessibilityLabel(isExpanded ? "" : LocalizedCopy.quantityAccessibility(quantity))
            .accessibilityHint(isExpanded ? "" : LocalizedCopy.expandQuantityStepperHint)
            .accessibilityAddTraits(isExpanded ? [] : .isButton)
            .animation(ExpandableQuantityPillTiming.animation, value: isExpanded)
            .animation(ExpandableQuantityPillTiming.animation, value: quantity)
            .onChange(of: isExpanded) { _, expanded in
                if expanded, schedulesAutoCollapse {
                    scheduleCollapse()
                } else {
                    cancelCollapseTask()
                }
            }
            .onDisappear {
                cancelCollapseTask()
            }
    }

    private var pillContent: some View {
        HStack(spacing: 0) {
            minusStepperButton

            quantityLabel

            stepperButton(
                systemName: "plus.circle.fill",
                isVisible: isExpanded,
                foregroundColor: appTheme.color,
                label: LocalizedCopy.increaseQuantity
            ) {
                playTapPulse()
                onIncrement()
                if schedulesAutoCollapse {
                    scheduleCollapse()
                }
            }
        }
        .modifier(QuantityPillRowInsets(
            isExpanded: isExpanded,
            usesLivePadding: usesLivePadding,
            scale: spacingScale,
            metrics: activeMetrics
        ))
    }

    private var minusStepperButton: some View {
        let removesFromList = quantity == 1
        return stepperButton(
            systemName: "minus.circle.fill",
            isVisible: isExpanded,
            foregroundColor: appTheme.color,
            label: removesFromList ? LocalizedCopy.removeFromShoppingList : LocalizedCopy.decreaseQuantity
        ) {
            if removesFromList {
                cancelCollapseTask()
                withAnimation(ExpandableQuantityPillTiming.animation) {
                    isExpanded = false
                }
                onRemove()
            } else {
                playTapPulse()
                onDecrement()
                if schedulesAutoCollapse {
                    scheduleCollapse()
                }
            }
        }
    }

    @ViewBuilder
    private var quantityLabel: some View {
        let label = Text("\(quantity)")
            .font(activeMetrics.quantityPillCollapsedNumberFont.font(monospacedDigit: true))
            .scaleEffect(isExpanded ? activeMetrics.expandedNumberScaleFactor() : 1, anchor: .center)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityHidden(isExpanded)

        if usesLivePadding {
            label
        } else {
            label
                .padding(
                    .horizontal,
                    activeMetrics.numberHorizontalPadding(isExpanded: isExpanded, scale: spacingScale)
                )
        }
    }

    private func stepperButton(
        systemName: String,
        isVisible: Bool,
        foregroundColor: Color,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        let symbolWidth = activeMetrics.stepperSymbolWidth(isExpanded: isVisible)
        return Button(action: action) {
            Image(systemName: systemName)
                .font(
                    isVisible
                        ? activeMetrics.quantityPillExpandedStepperFont.font()
                        : activeMetrics.quantityPillCollapsedStepperFont.font()
                )
                .foregroundStyle(foregroundColor)
                .scaleEffect(isVisible ? 1 : activeMetrics.stepperCollapsedScale)
                .frame(width: symbolWidth, height: symbolWidth)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isVisible ? 1 : 0)
        .frame(width: isVisible ? symbolWidth : 0)
        .clipped()
        .allowsHitTesting(isVisible)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }

    private func expandPill() {
        AppHaptics.impact(.light, intensity: 0.85)
        withAnimation(ExpandableQuantityPillTiming.animation) {
            isExpanded = true
        }
    }

    private func scheduleCollapse() {
        guard schedulesAutoCollapse else { return }
        cancelCollapseTask()
        collapseTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(ExpandableQuantityPillTiming.collapseDelaySeconds))
            guard !Task.isCancelled else { return }
            withAnimation(ExpandableQuantityPillTiming.animation) {
                isExpanded = false
            }
        }
    }

    private func cancelCollapseTask() {
        collapseTask?.cancel()
        collapseTask = nil
    }

    private func playTapPulse() {
        withAnimation(QuantityPillChromeTiming.tapPulseExpand) {
            tapPulseScale = QuantityPillChromeTiming.tapPulsePeakScale
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(QuantityPillChromeTiming.tapPulseSettle) {
                tapPulseScale = 1
            }
        }
    }
}

// MARK: - Layout

private struct QuantityPillRowInsets: ViewModifier {
    let isExpanded: Bool
    let usesLivePadding: Bool
    let scale: CGFloat
    let metrics: QuantityPillLayoutMetrics

    func body(content: Content) -> some View {
        if usesLivePadding {
            content
                .padding(
                    .vertical,
                    isExpanded ? metrics.quantityPillCapsuleExpandedVerticalPaddingExtra * scale : 0
                )
        } else {
            content
                .padding(
                    .horizontal,
                    isExpanded ? metrics.stepperOuterPadding(scale: scale) : 0
                )
                .padding(
                    .vertical,
                    metrics.capsuleVerticalPadding(isExpanded: isExpanded, scale: scale)
                )
        }
    }
}

// MARK: - Chrome

private struct QuantityPillUnifiedChrome: ViewModifier {
    let style: ExpandableQuantityPillStyle
    let usesLivePadding: Bool

    @Environment(\.appTheme) private var appTheme
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        switch style {
        case .glass:
            content
                .foregroundStyle(appTheme.color)
                .background {
                    Capsule(style: .continuous)
                        .fill(.clear)
                        .glassEffect(.regular, in: Capsule(style: .continuous))
                }
                .appThemeTint()
        case .material:
            if usesLivePadding {
                content
                    .modifier(QuantityPillMaterialStyle())
            } else {
                content
                    .foregroundStyle(appTheme.color)
                    .background { materialCapsule }
                    .clipShape(Capsule(style: .continuous))
            }
        }
    }

    private var materialCapsule: some View {
        Capsule(style: .continuous)
            .fill(colorScheme == .dark ? Color(white: 0.1) : .white)
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.95),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.1),
                radius: 2.5,
                y: 1.5
            )
    }
}
