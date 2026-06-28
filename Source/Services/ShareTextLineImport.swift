import Foundation

/// Text-based catalog import shared by the share extension flow and Shortcuts App Intent.
enum ShareTextLineImport {
    /// Enqueues matched items in the app group for the live `GroceryStore` to merge (same path as the share sheet).
    @MainActor
    static func enqueueMatchingLines(_ text: String) -> Int {
        ShareExtensionAppGroupSupport.enqueuePendingShoppingOps(matchingText: text)
    }
}
