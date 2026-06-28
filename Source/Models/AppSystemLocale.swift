import Foundation
import SwiftUI

/// System interface language and layout — independent of catalog (`AppContentLanguage`) data.
enum AppSystemLocale {
    /// True when iOS resolved the app bundle to Hebrew (phone language is Hebrew).
    static var systemPrefersHebrewUI: Bool {
        Bundle.main.preferredLocalizations.first?.hasPrefix("he") == true
    }

    /// Root layout direction for app chrome when the phone language is Hebrew.
    /// Home / Store lists override this with `catalogListLayoutDirection()`.
    static var interfaceLayoutDirection: LayoutDirection {
        systemPrefersHebrewUI ? .rightToLeft : .leftToRight
    }

    /// UserDefaults default for catalog language on first launch (never overrides an existing value).
    static var firstLaunchCatalogLanguageDefault: String {
        systemPrefersHebrewUI
            ? AppContentLanguage.hebrew.rawValue
            : AppContentLanguage.english.rawValue
    }
}
