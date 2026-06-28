import SwiftUI

struct WelcomeExplainerOverlay: View {
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
            VStack(alignment: .center, spacing: 20) {
                Text(LocalizedCopy.welcomeExplainerTitle)
                    .font(.system(size: 18, weight: .bold))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)

                Group {
                    welcomeExplainerBodyText(LocalizedCopy.welcomeExplainerItemSections)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(LocalizedCopy.welcomeExplainerShoppingListGrouping)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(LocalizedCopy.welcomeExplainerHomeLibraryGrouping)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .foregroundStyle(Color(uiColor: .label))
            .padding(.horizontal, cardHorizontalInset)
            .padding(.top, cardTextVerticalInset)
            .padding(.bottom, cardTextVerticalInset)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(LocalizedCopy.welcomeExplainerAccessibilityLabel)
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

    private func welcomeExplainerBodyText(_ localized: String) -> Text {
        guard var attributed = try? AttributedString(
            markdown: localized,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) else {
            return Text(localized)
        }

        for run in attributed.runs {
            if run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
                attributed[run.range].font = .body.weight(.semibold)
            } else {
                attributed[run.range].font = .body
            }
        }

        return Text(attributed)
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
