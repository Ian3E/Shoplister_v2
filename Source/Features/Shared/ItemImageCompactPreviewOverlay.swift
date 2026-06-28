import SwiftUI
import UIKit

private enum ItemImageCompactPreviewMetrics {
    /// Inner image is cropped to a square before the white mat is applied.
    static let imageSide: CGFloat = 300
    static let cornerRadius: CGFloat = 40
}

/// Dimmed backdrop + square photo; scales and fades in. Dismiss by tapping outside, tapping the photo, or tapping Done.
struct ItemImageCompactPreviewOverlay: View {
    let itemID: UUID
    var onDismiss: () -> Void
    /// When set, the primary button reads “Edit Item” and runs this instead of a plain dismiss.
    var onEditItem: (() -> Void)? = nil

    @Environment(\.appTheme) private var appTheme
    @State private var reveal = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(reveal ? 1 : 0)
                .onTapGesture { dismissAnimated() }

            VStack(spacing: 14) {
                Group {
                    if let ui = ItemImageStore.loadImage(forItemID: itemID) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(width: ItemImageCompactPreviewMetrics.imageSide, height: ItemImageCompactPreviewMetrics.imageSide)
                            .clipped()
                            .clipShape(
                                RoundedRectangle(cornerRadius: ItemImageCompactPreviewMetrics.cornerRadius, style: .continuous)
                            )
                            .shadow(color: Color.black.opacity(0.22), radius: 14, x: 0, y: 6)
                            .onTapGesture { dismissAnimated() }
                    } else {
                        ContentUnavailableView(LocalizedCopy.noImage, systemImage: "photo")
                            .frame(width: ItemImageCompactPreviewMetrics.imageSide, height: ItemImageCompactPreviewMetrics.imageSide)
                            .background(
                                RoundedRectangle(cornerRadius: ItemImageCompactPreviewMetrics.cornerRadius, style: .continuous)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: ItemImageCompactPreviewMetrics.cornerRadius, style: .continuous)
                            )
                            .onTapGesture { dismissAnimated() }
                    }
                }

                Button {
                    if let onEditItem {
                        onEditItem()
                    } else {
                        dismissAnimated()
                    }
                } label: {
                    Text(onEditItem == nil ? LocalizedCopy.done : LocalizedCopy.editItem)
                        .font(.headline)
                        .foregroundStyle(appTheme.color)
                        .frame(width: ItemImageCompactPreviewMetrics.imageSide, height: 48)
                        .background(
                            Capsule(style: .continuous)
                                .fill(.regularMaterial)
                        )
                        .shadow(color: Color.black.opacity(0.22), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
            }
            .scaleEffect(reveal ? 1 : 0.86)
            .opacity(reveal ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .ignoresSafeArea()
        .onAppear {
            AppHaptics.impact(.medium)
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                reveal = true
            }
        }
    }

    private func dismissAnimated() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
            reveal = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            onDismiss()
        }
    }
}
