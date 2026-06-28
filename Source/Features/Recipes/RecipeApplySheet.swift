import SwiftUI

private struct RecipeApplyLine: Identifiable {
    let id: UUID
    let lineID: UUID
    let itemID: UUID
    let title: String
    let quantity: Int
    let isAvailable: Bool
}

struct RecipeApplySheet: View {
    @EnvironmentObject private var store: GroceryStore
    @Environment(\.appContentLanguage) private var catalogLanguage
    @Environment(\.appTheme) private var appTheme
    @Environment(\.layoutDirection) private var layoutDirection
    @AppStorage(AppTextSize.storageKey) private var textSizeRaw: String = AppTextSize.defaultSize.rawValue

    let recipe: Recipe
    let onApplied: () -> Void
    let onCancel: () -> Void

    @State private var lines: [RecipeApplyLine] = []
    @State private var selectedLineIDs: Set<UUID> = []

    private var catalogTextDynamicTypeSize: DynamicTypeSize {
        AppTextSize.resolved(from: textSizeRaw).dynamicTypeSize
    }

    private var usesManualMirror: Bool {
        CatalogLayoutMirroring.catalogListUsesManualMirror(for: catalogLanguage)
    }

    private var availableLines: [RecipeApplyLine] {
        lines.filter(\.isAvailable)
    }

    private var unavailableLines: [RecipeApplyLine] {
        lines.filter { !$0.isAvailable }
    }

    private var groupedLines: [(Tag, [RecipeApplyLine])] {
        let lineByItemID = Dictionary(grouping: availableLines, by: \.itemID)
        var bucket: [UUID: [GroceryItem]] = [:]
        for line in availableLines {
            guard let item = store.item(for: line.itemID) else { continue }
            bucket[item.inventoryTagID, default: []].append(item)
        }
        return store.inventoryTags.compactMap { tag in
            guard tag.kind == .inventory else { return nil }
            guard var sectionItems = bucket[tag.id], !sectionItems.isEmpty else { return nil }
            sectionItems.sort { a, b in
                if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            let sectionLines = sectionItems.flatMap { lineByItemID[$0.id] ?? [] }
            return (tag, sectionLines)
        }
    }

    private var canAdd: Bool {
        lines.contains { selectedLineIDs.contains($0.lineID) && $0.isAvailable }
    }

    var body: some View {
        List {
            ForEach(Array(groupedLines.enumerated()), id: \.element.0.id) { index, pair in
                recipeApplySection(
                    title: pair.0.displayTitle(appContentLanguage: catalogLanguage),
                    showsVisibleGroupDivider: index > 0,
                    sectionLines: pair.1
                )
            }
            if !unavailableLines.isEmpty {
                recipeApplySection(
                    title: LocalizedCopy.itemNotInLibrary,
                    showsVisibleGroupDivider: !groupedLines.isEmpty,
                    sectionLines: unavailableLines
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .dynamicTypeSize(catalogTextDynamicTypeSize)
        .shoppingListDensity()
        .animation(AppTextSize.layoutCommitAnimation, value: textSizeRaw)
        .listSectionSpacing(ShoppingListMetrics.interSectionSpacing)
        .catalogListLayoutDirection()
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(LocalizedCopy.cancel, action: onCancel)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(LocalizedCopy.add) {
                    store.addRecipeToShopping(recipeID: recipe.id, lineIDs: selectedLineIDs)
                    onApplied()
                }
                .font(.body.weight(.semibold))
                .buttonStyle(.glassProminent)
                .appThemeTint()
                .appThemeIdentity()
                .disabled(!canAdd)
            }
        }
        .onAppear {
            loadLinesFromRecipe()
        }
    }

    @ViewBuilder
    private func recipeApplySection(
        title: String,
        showsVisibleGroupDivider: Bool,
        sectionLines: [RecipeApplyLine]
    ) -> some View {
        Section {
            recipeApplySectionHeader(title: title, showsVisibleGroupDivider: showsVisibleGroupDivider)
            ForEach(sectionLines) { line in
                RecipeApplyIngredientRow(
                    line: line,
                    catalogLanguage: catalogLanguage,
                    isSelected: selectedLineIDs.contains(line.lineID),
                    usesManualMirror: usesManualMirror,
                    layoutDirection: layoutDirection,
                    onToggle: { toggleSelection(for: line) }
                )
            }
        }
        .listSectionMargins(.horizontal, 0)
    }

    @ViewBuilder
    private func recipeApplySectionHeader(title: String, showsVisibleGroupDivider: Bool) -> some View {
        VStack(spacing: 0) {
            CatalogGroupHeaderSeparatorPrefix(showsVisibleDivider: showsVisibleGroupDivider)
            recipeApplySectionHeaderTitle(title: title)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .catalogGroupHeaderRowStyle()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func recipeApplySectionHeaderTitle(title: String) -> some View {
        if usesManualMirror {
            Text(title)
                .font(CatalogGroupHeaderChrome.titleFont)
                .foregroundStyle(CatalogGroupHeaderChrome.titleColor)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            Text(title)
                .font(CatalogGroupHeaderChrome.titleFont)
                .foregroundStyle(CatalogGroupHeaderChrome.titleColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func loadLinesFromRecipe() {
        var nextLines: [RecipeApplyLine] = []
        var initialSelection: Set<UUID> = []
        for line in recipe.lines {
            let item = store.item(for: line.itemID)
            let isAvailable = item != nil
            nextLines.append(
                RecipeApplyLine(
                    id: line.id,
                    lineID: line.id,
                    itemID: line.itemID,
                    title: item?.displayName(appContentLanguage: catalogLanguage) ?? LocalizedCopy.itemNotInLibrary,
                    quantity: line.quantity,
                    isAvailable: isAvailable
                )
            )
            if isAvailable {
                initialSelection.insert(line.id)
            }
        }
        lines = nextLines
        selectedLineIDs = initialSelection
    }

    private func toggleSelection(for line: RecipeApplyLine) {
        guard line.isAvailable else { return }
        if selectedLineIDs.contains(line.lineID) {
            selectedLineIDs.remove(line.lineID)
        } else {
            selectedLineIDs.insert(line.lineID)
        }
    }
}

private struct RecipeApplyIngredientRow: View {
    @Environment(\.appTheme) private var appTheme

    let line: RecipeApplyLine
    let catalogLanguage: AppContentLanguage
    let isSelected: Bool
    let usesManualMirror: Bool
    let layoutDirection: LayoutDirection
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                if usesManualMirror {
                    hebrewRowContent
                } else {
                    englishRowContent
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!line.isAvailable)
        .homeCatalogListItemRowStyle()
        .listRowFullBleedHitArea(
            alignment: CatalogLayoutMirroring.rowContentAlignment(
                catalogLanguage: catalogLanguage,
                layoutDirection: layoutDirection
            )
        )
        .catalogListRowSeparatorFullWidth(false)
        .accessibilityLabel(
            line.isAvailable
                ? line.title
                : "\(line.title), \(LocalizedCopy.itemNotInLibrary)"
        )
    }

    private var englishRowContent: some View {
        HStack(spacing: 12) {
            selectionMark
            Text(line.title)
                .font(.body)
                .foregroundStyle(line.isAvailable ? .primary : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            quantityLabel
        }
    }

    private var hebrewRowContent: some View {
        HStack(spacing: 12) {
            quantityLabel
            Text(line.title)
                .font(.body)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(line.isAvailable ? .primary : .secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            selectionMark
        }
    }

    private var selectionMark: some View {
        Image(systemName: isSelected && line.isAvailable ? "checkmark.circle.fill" : "circle")
            .font(.title2)
            .foregroundStyle(selectionMarkColor)
            .symbolRenderingMode(.monochrome)
    }

    private var quantityLabel: some View {
        Group {
            if line.quantity > 1 {
                Text("\(line.quantity)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(line.isAvailable ? appTheme.color : .secondary)
            }
        }
        .frame(minWidth: line.quantity > 1 ? nil : 0)
    }

    private var selectionMarkColor: Color {
        guard line.isAvailable else { return .secondary }
        return isSelected ? appTheme.color : .secondary
    }
}
