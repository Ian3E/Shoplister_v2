import SwiftUI

/// User-chosen accent theme preset, persisted in `UserDefaults` via `@AppStorage`.
enum AppTheme: String, CaseIterable, Identifiable {
    case blue
    case orange
    case red
    case green
    case pink
    case purple
    case custom

    static let storageKey = "app.theme"
    static let customColorStorageKey = "app.theme.customColor"
    static let defaultCustomColorHex = "#007AFF"

    /// Display order for the theme picker swatch row (blue remains the default preset).
    static var presetCases: [AppTheme] {
        [.red, .orange, .green, .blue, .purple, .pink]
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blue: return LocalizedCopy.themeBlue
        case .orange: return LocalizedCopy.themeOrange
        case .red: return LocalizedCopy.themeRed
        case .green: return LocalizedCopy.themeGreen
        case .pink: return LocalizedCopy.themePink
        case .purple: return LocalizedCopy.themePurple
        case .custom: return LocalizedCopy.themeCustom
        }
    }

    var builtinColor: Color {
        switch self {
        case .blue: return .blue
        case .orange: return .orange
        case .red: return .red
        case .green: return .green
        case .pink: return Color(red: 1.0, green: 0.35, blue: 0.72)
        case .purple: return .purple
        case .custom: return .blue
        }
    }
}

/// Resolved theme selection combining preset identity and optional custom color hex.
struct AppThemeSelection: Equatable {
    var presetRaw: String
    var customColorHex: String

    init(presetRaw: String, customColorHex: String = AppTheme.defaultCustomColorHex) {
        self.presetRaw = presetRaw
        self.customColorHex = customColorHex
    }

    var preset: AppTheme {
        AppTheme(rawValue: presetRaw) ?? .blue
    }

    var color: Color {
        if preset == .custom {
            return Color(hex: customColorHex) ?? AppTheme.blue.builtinColor
        }
        return preset.builtinColor
    }

    var id: String {
        if preset == .custom {
            return "custom-\(customColorHex)"
        }
        return presetRaw
    }

    var title: String {
        preset.title
    }
}

// MARK: - Color hex helpers

extension Color {
    init?(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }
        guard sanitized.count == 6, let value = UInt64(sanitized, radix: 16) else { return nil }
        let red = Double((value & 0xFF0000) >> 16) / 255
        let green = Double((value & 0x00FF00) >> 8) / 255
        let blue = Double(value & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    var hexString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return AppTheme.defaultCustomColorHex
        }
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}

// MARK: - Environment

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppThemeSelection(presetRaw: AppTheme.blue.rawValue)
}

extension EnvironmentValues {
    var appTheme: AppThemeSelection {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

// MARK: - Scoped tint helpers

/// Applies the user theme tint to a specific control without affecting global accent.
struct AppThemeTintModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme

    func body(content: Content) -> some View {
        content.tint(appTheme.color)
    }
}

extension View {
    func appThemeTint() -> some View {
        modifier(AppThemeTintModifier())
    }

    /// Recreates glass/toolbar controls when the theme changes (avoids stale UIKit chrome).
    func appThemeIdentity() -> some View {
        modifier(AppThemeIdentityModifier())
    }

    /// Applies theme tint only when `enabled` (e.g. Home edit-mode list checkboxes).
    func appThemeTint(when enabled: Bool) -> some View {
        modifier(ConditionalAppThemeTintModifier(enabled: enabled))
    }
}

private struct ConditionalAppThemeTintModifier: ViewModifier {
    let enabled: Bool
    @Environment(\.appTheme) private var appTheme

    func body(content: Content) -> some View {
        if enabled {
            content.tint(appTheme.color)
        } else {
            content
        }
    }
}

private struct AppThemeIdentityModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme

    func body(content: Content) -> some View {
        content.id(appTheme.id)
    }
}
