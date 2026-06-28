import Foundation
import SwiftUI

/// User-chosen app appearance, persisted in `UserDefaults` via `@AppStorage`.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "app.appearance"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return LocalizedCopy.appearanceSystem
        case .light: return LocalizedCopy.appearanceLight
        case .dark: return LocalizedCopy.appearanceDark
        }
    }

    /// `nil` means follow the system appearance.
    var colorSchemeOverride: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

