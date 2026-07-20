import SwiftUI

struct HomeFirstVisitExplainerOverlay: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let onDone: () -> Void

    @State private var isVisible = false
    @State private var dismissTask: Task<Void, Never>?

    private let cardHorizontalInset: CGFloat = 16
    private let cardMaxWidth: CGFloat = 340
    private let cardTextVerticalInset: CGFloat = 15
    private let cardCornerRadius: CGFloat = 34
    private static let fadeAnimation = Animation.easeInOut(duration: 0.25)
    private static let fadeOutDuration: Duration = .milliseconds(250)

    var body: some View {
        ZStack {
            Color.black.opacity(isVisible ? 0.55 : 0)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack {
                Spacer()

                cardContent
                    .opacity(isVisible ? 1 : 0)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
        .onAppear {
            withAnimation(Self.fadeAnimation) {
                isVisible = true
            }
        }
        .onDisappear {
            dismissTask?.cancel()
            dismissTask = nil
        }
    }

    private var cardContent: some View {
        VStack(spacing: 0) {
            VStack(alignment: .center, spacing: 20) {
                Text(LocalizedCopy.firstShoppingItemExplainerCongratulations)
                    .font(.system(size: 18, weight: .bold))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)

                Group {
                    Text(LocalizedCopy.firstShoppingItemExplainerFirstItemAdded)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)

                    quantityInstructionRow

                    Text(LocalizedCopy.firstShoppingItemExplainerRemoveHint)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.body)
            }
            .foregroundStyle(Color(uiColor: .label))
            .padding(.horizontal, cardHorizontalInset)
            .padding(.top, cardTextVerticalInset)
            .padding(.bottom, cardTextVerticalInset)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(LocalizedCopy.firstShoppingItemExplainerAccessibilityLabel)
            .accessibilityAddTraits(.isModal)

            Button(action: dismissAnimated) {
                Text(LocalizedCopy.done)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .appThemeTint()
            .padding(.horizontal, cardHorizontalInset)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: cardMaxWidth)
        .background {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        }
    }

    private var quantityInstructionRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(LocalizedCopy.firstShoppingItemExplainerTapQuantityPrefix)
            HomeCatalogQuantityPillPreview(quantity: 1)
            Text(LocalizedCopy.firstShoppingItemExplainerTapQuantitySuffix)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func dismissAnimated() {
        dismissTask?.cancel()
        withAnimation(Self.fadeAnimation) {
            isVisible = false
        }
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: Self.fadeOutDuration)
            guard !Task.isCancelled else { return }
            onDone()
        }
    }
}

/// Non-interactive collapsed quantity pill matching Home catalog row chrome.
struct HomeCatalogQuantityPillPreview: View {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let quantity: Int

    private static let previewSlotMinWidth: CGFloat = 40

    var body: some View {
        Text("\(quantity)")
            .font(.subheadline.monospacedDigit().weight(.semibold))
            .foregroundStyle(appTheme.color)
            .lineLimit(1)
            .padding(.horizontal, CatalogListRowDensity.quantityPillHorizontalPadding - 2)
            .padding(.vertical, CatalogListRowDensity.quantityPillVerticalPadding(for: dynamicTypeSize) + 5)
            .frame(
                minWidth: Self.previewSlotMinWidth,
                alignment: .center
            )
            .modifier(HomeCatalogQuantityPillStaticGlassStyle())
            .accessibilityHidden(true)
    }
}
