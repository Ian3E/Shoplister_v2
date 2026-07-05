import SwiftUI

private enum ExpandableQuantityPillTiming {
    static let collapseDelaySeconds: TimeInterval = 2
    static let animation: Animation = .spring(response: 0.28, dampingFraction: 0.82)
    static let stepperCollapsedScale: CGFloat = 0.2
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
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    @Environment(\.appTheme) private var appTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.shoppingListSpacingScale) private var spacingScale
    @State private var collapseTask: Task<Void, Never>?

    private var usesGlassChrome: Bool {
        style == .glass
    }

    private var collapsedMinWidth: CGFloat {
        if usesLivePadding {
            return CatalogListRowDensity.quantityPillLiveReservedWidth(
                forQuantity: quantity,
                scale: spacingScale
            )
        }
        return CatalogListRowDensity.quantityPillCollapsedRenderedWidth(
            forQuantity: quantity,
            usesGlassChrome: usesGlassChrome,
            scale: spacingScale
        )
    }

    private var expandedMinWidth: CGFloat {
        if usesLivePadding {
            return CatalogListRowDensity.quantityPillLiveExpandedReservedWidth(
                forQuantity: quantity,
                scale: spacingScale
            )
        }
        return CatalogListRowDensity.quantityPillExpandedReservedWidth(
            forQuantity: quantity,
            usesGlassChrome: usesGlassChrome,
            scale: spacingScale
        )
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
                if expanded {
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
            stepperButton(
                systemName: "minus.circle.fill",
                isVisible: isExpanded,
                isEnabled: quantity > 1,
                label: LocalizedCopy.decreaseQuantity
            ) {
                onDecrement()
                scheduleCollapse()
            }

            quantityLabel

            stepperButton(
                systemName: "plus.circle.fill",
                isVisible: isExpanded,
                isEnabled: true,
                label: LocalizedCopy.increaseQuantity
            ) {
                onIncrement()
                scheduleCollapse()
            }
        }
        .modifier(QuantityPillRowInsets(
            isExpanded: isExpanded,
            usesLivePadding: usesLivePadding,
            scale: spacingScale
        ))
    }

    @ViewBuilder
    private var quantityLabel: some View {
        let label = Text("\(quantity)")
            .font(.subheadline.monospacedDigit().weight(.semibold))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityHidden(isExpanded)

        if usesLivePadding {
            label
        } else {
            label
                .padding(
                    .horizontal,
                    CatalogListRowDensity.quantityPillNumberHorizontalPadding(
                        isExpanded: isExpanded,
                        scale: spacingScale
                    )
                )
        }
    }

    private func stepperButton(
        systemName: String,
        isVisible: Bool,
        isEnabled: Bool,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            guard isEnabled else { return }
            action()
        } label: {
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(isEnabled ? appTheme.color : appTheme.subduedControlColor)
                .scaleEffect(isVisible ? 1 : ExpandableQuantityPillTiming.stepperCollapsedScale)
                .frame(
                    width: CatalogListRowDensity.quantityPillStepperSymbolWidth,
                    height: CatalogListRowDensity.quantityPillStepperSymbolWidth
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isVisible ? 1 : 0)
        .frame(width: isVisible ? CatalogListRowDensity.quantityPillStepperSymbolWidth : 0)
        .clipped()
        .allowsHitTesting(isVisible)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isEnabled ? .isButton : [])
    }

    private func expandPill() {
        withAnimation(ExpandableQuantityPillTiming.animation) {
            isExpanded = true
        }
    }

    private func scheduleCollapse() {
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
}

// MARK: - Layout

private struct QuantityPillRowInsets: ViewModifier {
    let isExpanded: Bool
    let usesLivePadding: Bool
    let scale: CGFloat

    func body(content: Content) -> some View {
        if usesLivePadding {
            content
                .padding(
                    .vertical,
                    isExpanded
                        ? CatalogListRowDensity.quantityPillCapsuleExpandedVerticalPaddingExtra * scale
                        : 0
                )
        } else {
            content
                .padding(
                    .horizontal,
                    isExpanded ? CatalogListRowDensity.quantityPillStepperOuterPadding(scale: scale) : 0
                )
                .padding(
                    .vertical,
                    CatalogListRowDensity.quantityPillCapsuleVerticalPadding(
                        isExpanded: isExpanded,
                        scale: scale
                    )
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
