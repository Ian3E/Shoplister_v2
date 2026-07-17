import SwiftUI

/// Store pull-to-add: catalog search and add without leaving the shopping list.
struct StorePullToAddCatalogSearchView: View {
    private static let bottomFloatingBarClearance: CGFloat = 86
    /// Space below the no-match placeholder so it stays above the toolbar search field.
    private static let toolbarSearchFieldClearance: CGFloat = 56
    /// Reserve nav/search chrome height for the no-match placeholder band.
    private static let toolbarSearchCollapsedTopChromeClearance: CGFloat = 100
    private static let regularWidthClassListMaxWidth: CGFloat = 640

    @EnvironmentObject private var store: GroceryStore
    @Environment(\.appContentLanguage) private var catalogLanguage
    @Environment(\.shoppingListSpacingScale) private var listSpacingScale
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppTextSize.storageKey) private var textSizeRaw: String = AppTextSize.defaultSize.rawValue

    @Binding var isSearchPresented: Bool
    @Binding var searchText: String
    @Binding var pinnedSearchQuery: String
    /// Stable identity for the searchable chrome, owned by `ShoppingView` and regenerated only
    /// when a pull-to-add session begins, so adds do not churn the search field's identity.
    var searchChromeID: UUID
    var onPresentNewItem: (String) -> Void
    /// Pops pull-to-add back to Store (Cancel + return/search submit).
    var onEndSearch: () -> Void

    @State private var expandedPullToAddQuantityPillItemID: UUID?

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedPinnedSearchQuery: String {
        pinnedSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var activeFilterQuery: String? {
        if !trimmedSearchText.isEmpty { return trimmedSearchText }
        if !trimmedPinnedSearchQuery.isEmpty { return trimmedPinnedSearchQuery }
        return nil
    }

    private var toolbarSearchEmptyQueryActive: Bool {
        isSearchPresented && activeFilterQuery == nil
    }

    private var catalogItemsForList: [GroceryItem] {
        guard isSearchPresented, let query = activeFilterQuery else { return [] }
        return filteredCatalogItems(matching: query)
    }

    private func filteredCatalogItems(matching query: String) -> [GroceryItem] {
        guard !CatalogSearchNormalization.normalizedForMatching(query).isEmpty else { return [] }
        return store.catalog.filter { item in
            CatalogSearchNormalization.localizedCaseInsensitiveContains(
                searchQuery: query,
                in: item.displayName(appContentLanguage: catalogLanguage)
            )
        }
    }

    private var toolbarSearchNoMatches: Bool {
        isSearchPresented
            && activeFilterQuery != nil
            && catalogItemsForList.isEmpty
    }

    private var showsCatalogListRows: Bool {
        !toolbarSearchEmptyQueryActive && !toolbarSearchNoMatches
    }

    /// Mirrors Home search: blank when the field is empty, match count while querying, no-match copy when empty.
    private var principalSubtitleText: String {
        guard activeFilterQuery != nil else { return "" }
        if catalogItemsForList.isEmpty {
            return LocalizedCopy.noMatchingItemsFound
        }
        return LocalizedCopy.searchItemsFound(catalogItemsForList.count)
    }

    private var principalAccessibilityLabel: String {
        let subtitle = principalSubtitleText
        if subtitle.isEmpty {
            return LocalizedCopy.addItem
        }
        if catalogItemsForList.isEmpty {
            return "\(LocalizedCopy.addItem), \(subtitle)"
        }
        return "\(LocalizedCopy.addItem), \(LocalizedCopy.searchItemsFoundAccessibilityLabel(catalogItemsForList.count))"
    }

    private var catalogTextDynamicTypeSize: DynamicTypeSize {
        AppTextSize.resolved(from: textSizeRaw).dynamicTypeSize
    }

    private var sortedCatalogItemsForList: [GroceryItem] {
        catalogItemsForList.sorted { lhs, rhs in
            let nameA = lhs.displayName(appContentLanguage: catalogLanguage)
            let nameB = rhs.displayName(appContentLanguage: catalogLanguage)
            let comparison = nameA.localizedCaseInsensitiveCompare(nameB)
            if comparison != .orderedSame { return comparison == .orderedAscending }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    var body: some View {
        ZStack {
            Color.shoppingListBackground
                .ignoresSafeArea()
                .allowsHitTesting(false)

            Group {
                if showsCatalogListRows {
                    catalogResultsList
                }
            }
            .id(searchChromeID)
            .searchable(
                text: $searchText,
                isPresented: $isSearchPresented,
                placement: .toolbar,
                prompt: LocalizedCopy.searchOrCreateItem
            )
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .modifier(StorePullToAddSearchSubmitModifier(onSubmit: handleSearchSubmit))
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .frame(height: Self.bottomFloatingBarClearance)
                    .allowsHitTesting(false)
            }

            if toolbarSearchNoMatches {
                noMatchesPlaceholder
                    .transition(.identity)
            }
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? Self.regularWidthClassListMaxWidth : .infinity)
        .frame(maxWidth: .infinity)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(LocalizedCopy.addItem)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(uiColor: .label))
                    Text(principalSubtitleText)
                        .font(.footnote.weight(.regular))
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(principalAccessibilityLabel)
                .accessibilityAddTraits(.isHeader)
            }
        }
        .onChange(of: searchText) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                pinnedSearchQuery = ""
            }
        }
    }

    private var catalogResultsList: some View {
        List {
            ForEach(sortedCatalogItemsForList) { item in
                StorePullToAddCatalogItemRow(
                    item: item,
                    expandedQuantityPillItemID: $expandedPullToAddQuantityPillItemID,
                    onAddedToShopping: pinSearchAndClearField
                )
                .homeCatalogListItemRowStyle()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .dynamicTypeSize(catalogTextDynamicTypeSize)
        .shoppingListDensity()
        .animation(AppTextSize.layoutCommitAnimation, value: textSizeRaw)
        .listSectionSpacing(ShoppingListMetrics.interSectionSpacing)
        .scrollEdgeSoftTopIfAvailable(when: showsCatalogListRows)
        .catalogListLayoutDirection()
        .environment(\.expandedQuantityPillItemID, expandedPullToAddQuantityPillItemID)
    }

    private func pinSearchAndClearField() {
        if !trimmedSearchText.isEmpty {
            pinnedSearchQuery = trimmedSearchText
        }
        searchText = ""
    }

    private func catalogItemMatchingSearchTermExactly(_ trimmed: String) -> GroceryItem? {
        let query = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !CatalogSearchNormalization.normalizedForMatching(query).isEmpty else { return nil }
        return store.catalog.first { item in
            CatalogSearchNormalization.localizedCaseInsensitiveEquals(
                item.displayName(appContentLanguage: catalogLanguage).trimmingCharacters(in: .whitespacesAndNewlines),
                query
            )
        }
    }

    private func handleSearchSubmit() {
        let trimmed = trimmedSearchText
        if trimmed.isEmpty {
            dismissStorePullToAddSearch()
            return
        }
        if let match = catalogItemMatchingSearchTermExactly(trimmed) {
            let itemID = match.id
            dismissStorePullToAddSearch()
            // Add on the next turn so the navigation pop can commit first. Mutating shopping in
            // the same turn as `navigationPath.removeLast()` was leaving pull-to-add on screen.
            DispatchQueue.main.async {
                store.addToShopping(itemID: itemID, quantity: 1)
            }
            return
        }
        onPresentNewItem(trimmed)
    }

    private func dismissStorePullToAddSearch() {
        searchText = ""
        pinnedSearchQuery = ""
        isSearchPresented = false
        // Pop now (Cancel/`onChange` may also fire) and again next turn as a safety net —
        // search `onSubmit` + binding writes can drop a same-turn `NavigationPath` update.
        onEndSearch()
        DispatchQueue.main.async {
            onEndSearch()
        }
        Task { @MainActor in
            await Task.yield()
            dismissSearch()
        }
    }

    @ViewBuilder
    private var noMatchesPlaceholder: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            Button(LocalizedCopy.createItem) {
                handleSearchSubmit()
            }
            .font(.body)
            .modifier(StorePullToAddCreateItemButtonStyle())
            .padding(.horizontal, 28)

            Spacer(minLength: 0)
        }
        .padding(.top, Self.toolbarSearchCollapsedTopChromeClearance)
        .padding(.bottom, Self.toolbarSearchFieldClearance)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}

private struct StorePullToAddSearchSubmitModifier: ViewModifier {
    let onSubmit: () -> Void

    func body(content: Content) -> some View {
        content.onSubmit(of: .search) {
            onSubmit()
        }
    }
}

/// No-results **Create Item** — matches Home toolbar search (glass capsule, large control).
private struct StorePullToAddCreateItemButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .appThemeTint()
    }
}

private struct StorePullToAddCatalogItemRow: View {
    @EnvironmentObject private var store: GroceryStore
    @Environment(\.appContentLanguage) private var catalogLanguage
    @Environment(\.appTheme) private var appTheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.shoppingListSpacingScale) private var spacingScale

    let item: GroceryItem
    @Binding var expandedQuantityPillItemID: UUID?
    let onAddedToShopping: () -> Void

    @State private var isQuantityPillExpanded = false

    private var usesManualMirror: Bool {
        CatalogLayoutMirroring.catalogListUsesManualMirror(for: catalogLanguage)
    }

    private var isInShopping: Bool {
        store.shopping.contains(where: { $0.itemID == item.id })
    }

    private var qty: Int {
        store.shoppingListQuantity(for: item.id)
    }

    var body: some View {
        rowLabel
            .listRowFullBleedHitArea(
                alignment: CatalogLayoutMirroring.rowContentAlignment(
                    catalogLanguage: catalogLanguage,
                    layoutDirection: layoutDirection
                )
            )
            .overlay {
                CatalogListRowTapTouchOverlay(
                    item: item,
                    usesGlassChrome: true,
                    onTap: handleTap
                )
                .listRowFullBleedHitArea()
            }
            .onChange(of: expandedQuantityPillItemID) { _, expandedID in
                syncQuantityPillExpansion(with: expandedID)
            }
            .onChange(of: isInShopping) { _, inShopping in
                guard !inShopping else { return }
                quantityPillExpandedBinding.wrappedValue = false
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                LocalizedCopy.pullToAddCatalogRowAccessibilityLabel(
                    name: item.displayName(appContentLanguage: catalogLanguage),
                    isInShopping: isInShopping,
                    quantity: qty
                )
            )
            .accessibilityAddTraits(.isButton)
    }

    private func syncQuantityPillExpansion(with expandedID: UUID?) {
        let shouldExpand = expandedID == item.id
        guard isQuantityPillExpanded != shouldExpand else { return }
        isQuantityPillExpanded = shouldExpand
    }

    private var quantityPillExpandedBinding: Binding<Bool> {
        Binding(
            get: { isQuantityPillExpanded },
            set: { newValue in
                isQuantityPillExpanded = newValue
                if newValue {
                    expandedQuantityPillItemID = item.id
                } else if expandedQuantityPillItemID == item.id {
                    expandedQuantityPillItemID = nil
                }
            }
        )
    }

    private func handleTap() {
        if expandedQuantityPillItemID == item.id {
            return
        }
        expandedQuantityPillItemID = nil
        if isInShopping {
            store.removeFromShopping(itemID: item.id)
        } else {
            store.addToShopping(itemID: item.id, quantity: 1)
            onAddedToShopping()
            QuantityPillChromeTiming.expandAfterAdd(
                itemID: item.id,
                guardInShopping: { [store] in
                    store.shopping.contains(where: { $0.itemID == item.id })
                },
                setExpandedItemID: { expandedQuantityPillItemID = $0 }
            )
        }
    }

    @ViewBuilder
    private var rowLabel: some View {
        if usesManualMirror {
            hebrewRow
        } else {
            englishRow
        }
    }

    private var quantityPillTextGutter: CGFloat {
        if isInShopping {
            if isQuantityPillExpanded {
                return CatalogListRowDensity.quantityPillExpandedReservedWidth(
                    forQuantity: qty,
                    usesGlassChrome: true,
                    scale: spacingScale
                )
            }
            return CatalogListRowDensity.quantityPillCollapsedRenderedWidth(
                forQuantity: qty,
                usesGlassChrome: true,
                scale: spacingScale
            )
        }
        return CatalogListRowDensity.quantityPillSlotMinWidth
    }

    private var rowItemNameFont: Font {
        isInShopping && isQuantityPillExpanded ? Font.body.weight(.bold) : .body
    }

    private var hebrewRow: some View {
        Text(item.displayName(appContentLanguage: catalogLanguage))
            .font(rowItemNameFont)
            .animation(QuantityPillChromeTiming.expandCollapse, value: isQuantityPillExpanded)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(isInShopping ? appTheme.color : .primary)
            .lineLimit(1)
            .padding(.leading, quantityPillTextGutter)
            .animation(QuantityPillChromeTiming.expandCollapse, value: quantityPillTextGutter)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .overlay(alignment: .leading) {
                if isInShopping {
                    quantityPillColumn
                }
            }
    }

    private var englishRow: some View {
        Text(item.displayName(appContentLanguage: catalogLanguage))
            .font(rowItemNameFont)
            .animation(QuantityPillChromeTiming.expandCollapse, value: isQuantityPillExpanded)
            .multilineTextAlignment(.leading)
            .foregroundStyle(isInShopping ? appTheme.color : .primary)
            .lineLimit(1)
            .padding(.trailing, quantityPillTextGutter)
            .animation(QuantityPillChromeTiming.expandCollapse, value: quantityPillTextGutter)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .trailing) {
                if isInShopping {
                    quantityPillColumn
                }
            }
    }

    private var quantityPillColumn: some View {
        quantityPill(qty: qty, itemID: item.id)
            .fixedSize(horizontal: true, vertical: false)
            .frame(
                minWidth: CatalogListRowDensity.quantityPillSlotMinWidth
                    + CatalogListRowDensity.quantityPillHorizontalNudge,
                alignment: usesManualMirror ? .leading : .trailing
            )
    }

    private func quantityPill(qty: Int, itemID: UUID) -> some View {
        ExpandableQuantityPill(
            quantity: qty,
            style: .glass,
            usesLivePadding: false,
            edgeAlignment: usesManualMirror ? .leading : .trailing,
            isExpanded: quantityPillExpandedBinding,
            onIncrement: {
                store.incrementUncheckedShoppingQuantity(itemID: itemID, delta: 1)
            },
            onDecrement: {
                store.adjustUncheckedShoppingQuantity(itemID: itemID, delta: -1)
            },
            onRemove: {
                store.removeFromShopping(itemID: itemID)
            }
        )
    }
}

