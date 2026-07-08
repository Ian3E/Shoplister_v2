import SwiftUI

/// Centered Store empty overlay: soft “All done” with an optional first-run add hint.
struct ShoppingEmptyStateView: View {
    var showsAddHint: Bool = true

    @Environment(\.appTheme) private var appTheme

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "checkmark.app.fill")
                .font(.system(size: 48, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(appTheme.color)
                .padding(.bottom, 12)
                .accessibilityHidden(true)

            Text(LocalizedCopy.shoppingListEmptyTitleAllDone)
                .font(.title3.weight(.semibold))

            if showsAddHint {
                addHintFooter
                    .padding(.horizontal, 28)
                    .padding(.top, 14)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
    }

    private var addHintFooter: some View {
        (
            Text(LocalizedCopy.shoppingListEmptyAddHintLeading)
                + Text(" ")
                + Text(Image(systemName: "plus.circle.fill")).foregroundColor(appTheme.color)
                + Text(" ")
                + Text(LocalizedCopy.shoppingListEmptyAddHintTrailing)
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .imageScale(.medium)
    }

    private var accessibilityLabelText: String {
        if showsAddHint {
            return "\(LocalizedCopy.shoppingListEmptyTitleAllDone). \(LocalizedCopy.shoppingListEmptyAddHintAccessibility)"
        }
        return LocalizedCopy.shoppingListEmptyTitleAllDone
    }
}
