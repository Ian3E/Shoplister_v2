import SwiftUI

/// Theme picker with a live Store-list preview showing themed chrome.
struct ThemeSettingsView: View {
    @Binding var draftThemeRaw: String
    @Binding var draftCustomColorHex: String

    @AppStorage(AppContentLanguage.storageKey) private var catalogLanguageRaw: String = AppContentLanguage.english.rawValue

    private var catalogLanguage: AppContentLanguage {
        AppContentLanguage(rawValue: catalogLanguageRaw) ?? .english
    }

    private var draftTheme: AppTheme {
        AppTheme(rawValue: draftThemeRaw) ?? .blue
    }

    private var draftThemeSelection: AppThemeSelection {
        AppThemeSelection(presetRaw: draftThemeRaw, customColorHex: draftCustomColorHex)
    }

    private var draftCustomColor: Binding<Color> {
        Binding(
            get: {
                Color(hex: draftCustomColorHex) ?? AppTheme.blue.builtinColor
            },
            set: { newColor in
                draftThemeRaw = AppTheme.custom.rawValue
                draftCustomColorHex = newColor.hexString
            }
        )
    }

    var body: some View {
        List {
            Section {
                themeColorPicker
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
            }

            Section {
                themeStoreListPreview
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } header: {
                Text(LocalizedCopy.preview)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .textCase(nil)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
            }
            .listSectionMargins(.horizontal, 0)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.shoppingListBackground)
        .navigationTitle(LocalizedCopy.theme)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var themeColorPicker: some View {
        HStack(spacing: 12) {
            ForEach(AppTheme.presetCases) { option in
                Button {
                    draftThemeRaw = option.rawValue
                } label: {
                    Circle()
                        .fill(option.builtinColor)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if draftTheme == option {
                                Circle()
                                    .strokeBorder(Color.primary, lineWidth: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(draftTheme == option ? .isSelected : [])
            }

            ColorPicker("", selection: draftCustomColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 28, height: 28)
                .simultaneousGesture(TapGesture().onEnded {
                    draftThemeRaw = AppTheme.custom.rawValue
                })
                .overlay {
                    if draftTheme == .custom {
                        Circle()
                            .strokeBorder(Color.primary, lineWidth: 2)
                            .frame(width: 28, height: 28)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityLabel(LocalizedCopy.customColor)
                .accessibilityAddTraits(draftTheme == .custom ? .isSelected : [])
        }
        .frame(maxWidth: .infinity)
    }

    /// Space below the last preview row for the floating + (Store bottom-bar parity).
    private static let themePreviewFloatingAddButtonClearance: CGFloat = 150

    private var themeStoreListPreview: some View {
        let listHeight = SettingsStoreListPreview.contentHeight(for: .medium, catalogLanguage: catalogLanguage)

        return ZStack(alignment: .bottomTrailing) {
            SettingsStoreListPreview(textSize: .medium)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            SettingsThemePreviewAddButton()
                .padding(.trailing, 20)
                .padding(.bottom, 16)
        }
        .frame(height: listHeight + Self.themePreviewFloatingAddButtonClearance)
        .frame(maxWidth: .infinity)
        .environment(\.appTheme, draftThemeSelection)
        .allowsHitTesting(false)
    }
}

/// Floating "+" button for the theme preview — mirrors the Store tab open-home control.
private struct SettingsThemePreviewAddButton: View {
    var body: some View {
        Button(action: {}) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .frame(width: 36, height: 36)
                .contentShape(Circle())
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .appThemeTint()
        .accessibilityLabel(LocalizedCopy.openHomeLibrary)
        .allowsHitTesting(false)
    }
}
