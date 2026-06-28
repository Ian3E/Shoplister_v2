import SwiftUI

/// Presents dimmed full-window overlays from the app root (`ContentView`) so scrims cover the
/// status bar, home indicator, and `TabView` safe-area insets — not only the inner `NavigationStack`.
@MainActor
final class FullWindowOverlayCoordinator: ObservableObject {
    enum Kind: Equatable {
        case shoppingPhotoPreview(itemID: UUID)
        case welcomeExplainer
        case firstShoppingItemExplainer
    }

    /// Published so `InventoryView` can open the editor / delete alert after the overlay dismisses.
    /// Do not capture `@State` mutators in stored closures — they often no-op when invoked from here.
    enum InventoryQuickActionResult: Equatable {
        case editItem(id: UUID)
        case deleteItem(id: UUID)
    }

    @Published private(set) var kind: Kind?
    @Published private(set) var inventoryQuickActionResult: InventoryQuickActionResult?

    private static let presentationAnimation = Animation.easeOut(duration: 0.25)

    func presentShoppingPhotoPreview(itemID: UUID) {
        withAnimation(Self.presentationAnimation) {
            kind = .shoppingPhotoPreview(itemID: itemID)
        }
    }

    func presentWelcomeExplainer() {
        kind = .welcomeExplainer
    }

    func presentFirstShoppingItemExplainer() {
        kind = .firstShoppingItemExplainer
    }

    func dismiss(animated: Bool = true) {
        if animated {
            withAnimation(Self.presentationAnimation) {
                kind = nil
            }
        } else {
            kind = nil
        }
    }

    func consumeInventoryQuickActionResult() {
        inventoryQuickActionResult = nil
    }

    /// Uses `itemID` from the overlay (not `kind`) so a catalog refresh can’t invalidate the enum payload before the tap runs.
    func inventoryEditTapped(forItemID itemID: UUID) {
        dismiss()
        Task { @MainActor in
            await Task.yield()
            inventoryQuickActionResult = .editItem(id: itemID)
        }
    }

    func inventoryDeleteTapped(forItemID itemID: UUID) {
        dismiss()
        Task { @MainActor in
            await Task.yield()
            inventoryQuickActionResult = .deleteItem(id: itemID)
        }
    }
}
