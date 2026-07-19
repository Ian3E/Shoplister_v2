import Foundation

/// Whether the user has dismissed the Store gestures coach overlay
/// (shown on the first visit to a non-empty List).
enum AppStoreGesturesExplainer {
    static let storageKey = "app.storeGesturesExplainerSeen"
}
