import SwiftUI

/// Store pull-to-add: catalog search and add without leaving the shopping list.
struct StorePullToAddCatalogSearchView: View {
    private static let bottomFloatingBarClearance: CGFloat = 86
    /// Space below the no-match placeholder so it stays above the toolbar search field.
    private static let toolbarSearchFieldClearance: CGFloat = 56
    /// Principal header hidden during pull-to-add search — reserve its height for vertical centering.
    private static let toolbarSearchCollapsedTopChromeClearance: CGFloat = 100

    @EnvironmentObject private var store: GroceryStore
    @Environment(\.appContentLanguage) private var catalogLanguage
    @Environment(\.shoppingListSpacingScale) private var listSpacingScale
    @Environment(\.dismissSearch) private var dismissSearch
    @AppStorage(AppTextSize.storageKey) private var textSizeRaw: String = AppTextSize.defaultSize.rawValue

    @Binding var isSearchPresented: Bool
    @Binding var searchText: String
    @Binding var pinnedSearchQuery: String
    var onPresentNewItem: (String) -> Void

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
            .searchable(
                text: $searchText,
                isPresented: $isSearchPresented,
                placement: .toolbar,
                prompt: "Search or create item"
            )
            .searchPresentationToolbarBehavior(.automatic)
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
            store.addToShopping(itemID: match.id, quantity: 1)
            dismissStorePullToAddSearch()
            return
        }
        onPresentNewItem(trimmed)
    }

    private func dismissStorePullToAddSearch() {
        searchText = ""
        pinnedSearchQuery = ""
        isSearchPresented = false
        Task { @MainActor in
            await Task.yield()
            dismissSearch()
        }
    }

    @ViewBuilder
    private var noMatchesPlaceholder: some View {
        GeometryReader { geometry in
            let topInset = geometry.safeAreaInsets.top + Self.toolbarSearchCollapsedTopChromeClearance
            let bottomInset = geometry.safeAreaInsets.bottom + Self.toolbarSearchFieldClearance
            let bandHeight = max(0, geometry.size.height - topInset - bottomInset)

            VStack(spacing: 16) {
                Text(LocalizedCopy.noMatchingItemsFound)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(uiColor: .label))
                    .multilineTextAlignment(.center)
                Button(LocalizedCopy.createItem) {
                    handleSearchSubmit()
                }
                .font(.body)
                .modifier(StorePullToAddCreateItemButtonStyle())
            }
            .padding(.horizontal, 28)
            .frame(width: geometry.size.width, height: bandHeight, alignment: .center)
            .position(x: geometry.size.width / 2, y: topInset + bandHeight / 2 - 100)
            // Suppress the implicit animation that fires when the keyboard changes geometry.size.height.
            .animation(nil, value: geometry.size.height)
        }
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

    let item: GroceryItem
    let onAddedToShopping: () -> Void

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
            .contentShape(Rectangle())
            .onTapGesture { handleTap() }
    }

    private func handleTap() {
        if isInShopping {
            store.removeFromShopping(itemID: item.id)
        } else {
            store.addToShopping(itemID: item.id, quantity: 1)
            onAddedToShopping()
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
            return CatalogListRowDensity.quantityPillLiveReservedWidth(forQuantity: qty)
        }
        return CatalogListRowDensity.quantityPillSlotMinWidth
    }

    private var hebrewRow: some View {
        Text(item.displayName(appContentLanguage: catalogLanguage))
            .font(.body)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(isInShopping ? appTheme.color : .primary)
            .lineLimit(1)
            .padding(.leading, quantityPillTextGutter)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .overlay(alignment: .leading) {
                if isInShopping {
                    quantityPillColumn
                }
            }
    }

    private var englishRow: some View {
        Text(item.displayName(appContentLanguage: catalogLanguage))
            .font(.body)
            .multilineTextAlignment(.leading)
            .foregroundStyle(isInShopping ? appTheme.color : .primary)
            .lineLimit(1)
            .padding(.trailing, quantityPillTextGutter)
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
        Button {
            store.incrementUncheckedShoppingQuantity(itemID: itemID, delta: 1)
        } label: {
            Text("\(qty)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .lineLimit(1)
        }
        .modifier(QuantityPillMaterialStyle())
        .frame(
            minWidth: CatalogListRowDensity.quantityPillLiveReservedWidth(forQuantity: qty),
            alignment: .center
        )
        .contentShape(Rectangle())
        .accessibilityLabel(LocalizedCopy.increaseQuantity)
    }
}

