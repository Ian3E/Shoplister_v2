import UIKit
import UserNotifications

/// Updates the home-screen icon badge from the current shopping list.
enum ShoppingIconBadge {
    /// Unchecked shopping lines with a resolved catalog item (same count as the icon badge).
    @MainActor
    static func uncheckedCount(store: GroceryStore) -> Int {
        var count = 0
        for entry in store.shopping where !entry.isChecked && store.item(for: entry.itemID) != nil {
            count += 1
        }
        return count
    }

    @MainActor
    static func sync(enabled: Bool, store: GroceryStore) {
        if !enabled {
            Task {
                await clearBadgeWithoutAuthorizationPrompt()
            }
            return
        }
        let count = uncheckedCount(store: store)
        Task {
            await applyBadgeWhenEnabled(count)
        }
    }

    /// Badge cleared / feature off: never prompt for notification permission.
    private static func clearBadgeWithoutAuthorizationPrompt() async {
        await setBadgeNumber(0)
    }

    /// Feature on: may prompt for **badge** permission the first time, then set the count.
    private static func applyBadgeWhenEnabled(_ count: Int) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.badge])
        }
        await setBadgeNumber(count)
    }

    private static func setBadgeNumber(_ count: Int) async {
        let center = UNUserNotificationCenter.current()
        do {
            try await center.setBadgeCount(count)
        } catch {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                center.setBadgeCount(count) { _ in
                    continuation.resume()
                }
            }
        }
    }
}
