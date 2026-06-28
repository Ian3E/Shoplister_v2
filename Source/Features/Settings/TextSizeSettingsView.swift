import SwiftUI

/// Text size picker with a live Store-list preview (English demo content).
struct TextSizeSettingsView: View {
    @Binding var draftTextSizeRaw: String
    @Binding var draftThemeRaw: String
    @Binding var draftCustomColorHex: String

    private var draftSize: AppTextSize {
        AppTextSize.resolved(from: draftTextSizeRaw)
    }

    private var draftThemeSelection: AppThemeSelection {
        AppThemeSelection(presetRaw: draftThemeRaw, customColorHex: draftCustomColorHex)
    }

    private var sliderIndex: Binding<Double> {
        Binding(
            get: { Double(draftSize.sliderIndex) },
            set: { newValue in
                let index = Int(newValue.rounded())
                guard let size = AppTextSize(sliderIndex: index) else { return }
                draftTextSizeRaw = size.rawValue
            }
        )
    }

    var body: some View {
        List {
            Section {
                textSizeSlider
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
            }

            Section {
                SettingsStoreListPreview(textSize: draftSize)
                    .environment(\.appTheme, draftThemeSelection)
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
        .navigationTitle(LocalizedCopy.textSize)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var textSizeSlider: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("A")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Slider(
                    value: sliderIndex,
                    in: 0 ... Double(AppTextSize.allCases.count - 1),
                    step: 1
                )
                .accessibilityLabel(LocalizedCopy.textSize)
                .accessibilityValue(draftSize.title)

                textSizeStepIndicators
            }

            Text("A")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }

    private var textSizeStepIndicators: some View {
        HStack(spacing: 0) {
            ForEach(Array(AppTextSize.allCases.enumerated()), id: \.offset) { index, _ in
                if index > 0 {
                    Spacer(minLength: 0)
                }
                let isSelected = index == draftSize.sliderIndex
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.38))
                    .frame(width: isSelected ? 7 : 5, height: isSelected ? 7 : 5)
            }
        }
        .padding(.horizontal, 6)
        .accessibilityHidden(true)
    }
}
