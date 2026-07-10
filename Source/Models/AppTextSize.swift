import Foundation
import SwiftUI

/// User-chosen text scaling, persisted in `UserDefaults` via `@AppStorage`.
enum AppTextSize: String, CaseIterable, Identifiable {
    case extraSmall
    case small
    case medium
    case large
    case extraLarge

    static let storageKey = "app.textSize"
    /// Legacy stored value before fixed-size-only options.
    static let legacySystemRawValue = "system"
    /// Former fifth step raw value (`Largest`).
    static let legacyXXLargeRawValue = "xxLarge"
    static let defaultSize: AppTextSize = .medium
    /// Store/Home list type and spacing when text size is committed after Settings closes.
    static let layoutCommitAnimation: Animation = .smooth(duration: 0.35)

    var id: String { rawValue }

    var title: String {
        switch self {
        case .extraSmall: return LocalizedCopy.textSizeExtraSmall
        case .small: return LocalizedCopy.textSizeSmall
        case .medium: return LocalizedCopy.textSizeMedium
        case .large: return LocalizedCopy.textSizeLarge
        case .extraLarge: return LocalizedCopy.textSizeExtraLarge
        }
    }

    var sliderIndex: Int {
        Self.allCases.firstIndex(of: self) ?? Self.defaultSize.sliderIndex
    }

    init?(sliderIndex: Int) {
        guard Self.allCases.indices.contains(sliderIndex) else { return nil }
        self = Self.allCases[sliderIndex]
    }

    static func resolved(from raw: String?) -> AppTextSize {
        guard let raw else { return defaultSize }
        if raw == legacySystemRawValue { return defaultSize }
        if raw == legacyXXLargeRawValue { return .extraLarge }
        return AppTextSize(rawValue: raw) ?? defaultSize
    }

    /// Rewrites invalid or legacy stored values (e.g. former **System** / **xxLarge** choices).
    static func migrateStoredRawValueIfNeeded(_ raw: inout String) {
        if raw == legacySystemRawValue {
            raw = defaultSize.rawValue
            return
        }
        if raw == legacyXXLargeRawValue {
            raw = AppTextSize.extraLarge.rawValue
            return
        }
        if AppTextSize(rawValue: raw) == nil {
            raw = defaultSize.rawValue
        }
    }

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .extraSmall: return .xSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .extraLarge: return .xLarge
        }
    }

    /// Scales Home/Store list row height and vertical gaps (`ShoppingListMetrics`); medium = 1.0 → 44pt row floor.
    var listSpacingScale: CGFloat {
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        }
    }

    /// Vertical padding inside the glass quantity pill capsule (discrete per text-size step).
    var quantityPillCapsuleVerticalPadding: CGFloat {
        switch self {
        case .extraSmall: return 0
        case .small: return 1
        case .medium: return 3
        case .large: return 4
        case .extraLarge: return 5
        }
    }

    /// Nearest text-size step for a `listSpacingScale` value (e.g. Settings debug preview).
    static func resolved(fromListSpacingScale scale: CGFloat) -> AppTextSize {
        allCases.min {
            abs($0.listSpacingScale - scale) < abs($1.listSpacingScale - scale)
        } ?? defaultSize
    }
}
