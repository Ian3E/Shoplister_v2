import Foundation

/// Whether the user has dismissed the first-shopping-item explainer overlay.
enum AppHomeFirstVisitExplainer {
    static let storageKey = "app.homeFirstVisitExplainerSeen"
    /// One-time skip for users who already had items on the list before this explainer shipped.
    static let legacyPopulationMigrationKey = "app.homeFirstVisitExplainerLegacyPopulationMigrationDone"
}
