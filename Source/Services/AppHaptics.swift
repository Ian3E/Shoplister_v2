import UIKit

/// Global haptic preference (`UserDefaults`). Default is on when the key has never been set.
enum AppHaptics {
    static let storageKey = "app.hapticsEnabled"

    static var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: storageKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: storageKey)
    }

    @MainActor
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred(intensity: intensity)
    }
}
