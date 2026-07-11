import SwiftUI

struct StoreGesturesExplainerOverlay: View {
    let onDone: () -> Void

    @State private var isVisible = false
    @State private var dismissTask: Task<Void, Never>?
    @State private var measuredContentHeight: CGFloat = 0

    private let cardHorizontalInset: CGFloat = 16
    private let cardMaxWidth: CGFloat = 340
    private let cardTextVerticalInset: CGFloat = 15
    private let cardCornerRadius: CGFloat = 34
    private static let fadeAnimation = Animation.easeInOut(duration: 0.25)
    private static let fadeOutDuration: Duration = .milliseconds(250)
    private static let scrollMaxHeight: CGFloat = 420

    private var gestureTips: [(systemImage: String, title: String, detail: String)] {
        [
            (
                "arrow.down.circle.fill",
                LocalizedCopy.appFeaturePullDownToAddTitle,
                LocalizedCopy.appFeaturePullDownToAddDescription
            ),
            (
                "arrow.up.circle.fill",
                LocalizedCopy.appFeaturePullUpClearCheckedTitle,
                LocalizedCopy.appFeaturePullUpClearCheckedDescription
            ),
            (
                "hand.tap.fill",
                LocalizedCopy.appFeatureLongPressTitle,
                LocalizedCopy.appFeatureLongPressDescription
            ),
            (
                "arrow.uturn.backward.circle",
                LocalizedCopy.appFeatureShakeUndoTitle,
                LocalizedCopy.appFeatureShakeUndoDescription
            ),
        ]
    }

    var body: some View {
        ZStack {
            Color.black.opacity(isVisible ? 0.55 : 0)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            cardContent
                .opacity(isVisible ? 1 : 0)
                .padding(.horizontal, 28)
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
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    Text(LocalizedCopy.storeGesturesExplainerTitle)
                        .font(.system(size: 18, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(gestureTips.enumerated()), id: \.offset) { _, tip in
                            gestureTipRow(
                                systemImage: tip.systemImage,
                                title: tip.title,
                                detail: tip.detail
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundStyle(Color(uiColor: .label))
                .padding(.horizontal, cardHorizontalInset)
                .padding(.top, cardTextVerticalInset)
                .padding(.bottom, cardTextVerticalInset)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: ContentHeightKey.self, value: proxy.size.height)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            // Cap at the max, but hug the content when it's shorter so there's no dead space above Done.
            .frame(maxHeight: measuredContentHeight == 0
                ? Self.scrollMaxHeight
                : min(measuredContentHeight, Self.scrollMaxHeight))
            .onPreferenceChange(ContentHeightKey.self) { measuredContentHeight = $0 }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(LocalizedCopy.storeGesturesExplainerAccessibilityLabel)
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

    private func gestureTipRow(systemImage: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .center)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
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

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
