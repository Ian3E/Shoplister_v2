import Foundation
import SwiftUI

/// Controls Hebrew vs English **catalog data** (item names, section titles) and
/// Home / Store list layout direction. App UI chrome follows the phone language.
enum AppContentLanguage: String, CaseIterable, Identifiable {
    case english
    case hebrew

    static let storageKey = "app.catalogContentLanguage"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english: return LocalizedCopy.libraryLanguageEnglish
        case .hebrew: return "עברית"
        }
    }
}

private enum AppContentLanguageKey: EnvironmentKey {
    static let defaultValue: AppContentLanguage = .english
}

extension EnvironmentValues {
    var appContentLanguage: AppContentLanguage {
        get { self[AppContentLanguageKey.self] }
        set { self[AppContentLanguageKey.self] = newValue }
    }
}
