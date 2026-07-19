#if DEBUG
import SwiftUI

/// Developer-only utilities; the whole screen is compiled out of Release builds,
/// so copy here is intentionally not localized.
struct SettingsDebugView: View {
    @State private var didResetExplainers = false

    var body: some View {
        List {
            Section {
                Button("Reset explainers") {
                    resetExplainers()
                }
            } footer: {
                Text(
                    didResetExplainers
                        ? "Explainers reset. They will show again at their usual moments."
                        : "Shows the welcome, first-item, store-gestures, first-visit, and empty-list add-hint explainers again."
                )
            }
        }
        .navigationTitle("Debug")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func resetExplainers() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: AppWelcomeExplainer.storageKey)
        defaults.removeObject(forKey: AppHomeFirstVisitExplainer.storageKey)
        defaults.removeObject(forKey: AppStoreGesturesExplainer.storageKey)
        defaults.removeObject(forKey: AppHomeCatalogVisit.storageKey)
        defaults.removeObject(forKey: AppShoppingEmptyAddHint.storageKey)
        // Deliberately leaves `AppHomeFirstVisitExplainer.legacyPopulationMigrationKey` set:
        // re-running that migration on a populated list would immediately re-mark the
        // first-item explainer as seen, defeating the reset.
        didResetExplainers = true
    }
}
#endif
