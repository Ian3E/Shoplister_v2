import UIKit

/// When enabled, prevents the device screen from dimming / auto-locking while the app is in the foreground.
/// Persisted in `UserDefaults` via `@AppStorage`. Default is **off** (follow system auto-lock).
enum AppAutoLock {
    static let disableAutoLockStorageKey = "app.disableAutoLock"

    @MainActor
    static func applyFromUserDefaults() {
        let disable = UserDefaults.standard.bool(forKey: disableAutoLockStorageKey)
        UIApplication.shared.isIdleTimerDisabled = disable
    }
}
