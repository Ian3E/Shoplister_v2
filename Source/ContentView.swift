import Combine
import SwiftUI
import UIKit

/// Root TabView with centered List + Library tabs.
/// Pull-to-add is a Settings-style sheet from the List tab (gesture or trailing "+").
private enum TabSelection: Hashable {
    case store
    case home
}

struct ContentView: View {
    @EnvironmentObject private var store: GroceryStore
    @EnvironmentObject private var fullWindowOverlay: FullWindowOverlayCoordinator
    @Environment(\.appContentLanguage) private var catalogLanguage
    @Environment(\.appTheme) private var appTheme
    @State private var isPresentingSettings = false
    @State private var isPresentingNewCatalogItem = false
    @State private var newItemPrefillName: String? = nil
    /// Inventory row reorder mode: enables drag handles and changes row taps to "edit item".
    @State private var isInventoryReorderMode: Bool = false
    /// Catalog edit/delete from the full-window quick-actions overlay — presented here (root) so sheets
    /// aren’t attached under Home’s nested `InventoryView`, which can swallow presentation.
    @State private var inventoryCatalogEditorItem: GroceryItem?
    @State private var inventoryCatalogDeleteConfirmationItem: GroceryItem?
    @State private var editGroupsSheetKind: Tag.Kind?
    /// Mirrors the Library tab search presentation so New Item can clear/collapse it after save.
    @State private var isHomeToolbarSearchPresented = false
    /// Library search field text (lifted here so New Item sheet can clear it after save).
    @State private var homeInventorySearchText = ""
    /// Store pull-to-add: catalog search hosted on its own sheet so its search field lives in a
    /// toolbar fully isolated from the shopping-dependent Store nav bar.
    @State private var isStorePullToAddSearchPresented = false
    @State private var storePullToAddSearchText = ""
    @State private var storePullToAddPinnedSearchQuery = ""
    /// Stable identity for the pull-to-add search chrome; regenerated only when a session begins,
    /// mirroring Home's `homeToolbarSearchChromeID`, so adds cannot churn the searchable field.
    @State private var storePullToAddSearchChromeID = UUID()
    /// True only when presenting **New Item** after Store pull-to-add; add saved item to shopping list.
    @State private var newItemAddToShoppingAfterSave = false
    /// Selected root tab (List / Library).
    @State private var selectedTab: TabSelection = .store
    /// Pull-to-add presented as a modal sheet (Settings-style) from the List tab.
    @State private var isPresentingPullToAddSheet = false
    @AppStorage(AppTextSize.storageKey) private var textSizeRaw: String = AppTextSize.defaultSize.rawValue
    @AppStorage(AppTheme.storageKey) private var themeRaw: String = AppTheme.blue.rawValue
    @AppStorage(AppTheme.customColorStorageKey) private var customColorHex: String = AppTheme.defaultCustomColorHex
    @AppStorage(AppHomeFirstVisitExplainer.storageKey) private var hasSeenFirstShoppingItemExplainer = false
    @AppStorage(AppWelcomeExplainer.storageKey) private var hasSeenWelcomeExplainer = false
    @AppStorage(AppStoreGesturesExplainer.storageKey) private var hasSeenStoreGesturesExplainer = false
    @AppStorage(AppHomeCatalogVisit.storageKey) private var hasVisitedHomeCatalog = false
    @AppStorage(AppShoppingSortChecked.storageKey) private var sortCheckedShoppingItems: Bool = false
    /// Text size draft while Settings is open; committed in the sheet `onDismiss` handler only.
    @State private var settingsTextSizeDraft: String = AppTextSize.defaultSize.rawValue
    /// Theme draft while Settings is open; committed in the sheet `onDismiss` handler only.
    @State private var settingsThemeDraft: String = AppTheme.blue.rawValue
    @State private var settingsThemeCustomDraft: String = AppTheme.defaultCustomColorHex
    @State private var firstShoppingItemExplainerTask: Task<Void, Never>?
    @State private var welcomeExplainerTask: Task<Void, Never>?
    @State private var storeGesturesExplainerTask: Task<Void, Never>?

    /// At least one unchecked line with a resolved catalog item (same as what share text would include).
    private var canShareShoppingList: Bool {
        ShoppingListShareText.hasUncheckedItemsToShare(store: store)
    }

    // MARK: - TabView root

    @ViewBuilder
    private var tabChrome: some View {
        ZStack(alignment: .bottomLeading) {
            TabView(selection: $selectedTab) {
                Tab(LocalizedCopy.tabList, systemImage: "checklist", value: TabSelection.store) {
                    NavigationStack {
                        ShoppingView(
                            canShareShoppingList: canShareShoppingList,
                            isStorePullToAddSearchPresented: $isStorePullToAddSearchPresented,
                            onBeginPullToAddSearch: beginStoreTabPullToAdd,
                            showsAddItemButton: !isPresentingPullToAddSheet,
                            onShare: presentShoppingListShare,
                            onSettings: { isPresentingSettings = true },
                            onManageStoreSections: { editGroupsSheetKind = .shopping },
                            onAddItem: beginStoreTabPullToAdd
                        )
                    }
                }

                Tab(LocalizedCopy.tabLibrary, systemImage: "books.vertical", value: TabSelection.home) {
                    NavigationStack {
                        homeCatalogTabScreen
                    }
                }
            }
            .catalogGroupedChromeBackdrop()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let kind = fullWindowOverlay.kind {
                fullWindowOverlayContent(kind: kind)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .zIndex(200)
            }
        }
        .sheet(isPresented: $isPresentingPullToAddSheet) {
            storeTabPullToAddSheet
        }
        .onChange(of: isPresentingPullToAddSheet) { _, presented in
            if !presented {
                isStorePullToAddSearchPresented = false
                storePullToAddSearchText = ""
                storePullToAddPinnedSearchQuery = ""
                if newItemAddToShoppingAfterSave {
                    isPresentingNewCatalogItem = false
                }
                scheduleFirstShoppingItemExplainerIfNeeded()
                scheduleStoreGesturesExplainerIfNeeded()
            }
        }
    }

    /// Home tab: same catalog UI, but rooted (no back chevron) and returning to Store via tab switch.
    /// Saved lists moves to the freed top leading slot; search collapses to a bottom trailing button.
    private var homeCatalogTabScreen: some View {
        InventoryView(
            isReorderMode: $isInventoryReorderMode,
            usesHomeToolbarSearch: true,
            isHomeToolbarSearchPresented: $isHomeToolbarSearchPresented,
            homeSearchText: $homeInventorySearchText,
            minimizesToolbarSearch: true,
            showsRecipesInTopBarLeading: true,
            bottomReservedHeight: 0,
            ignoresSafeArea: false,
            showsShoppingStatus: true,
            onPresentNewItemFromSearch: { name in
                newItemAddToShoppingAfterSave = false
                newItemPrefillName = name
                homeInventorySearchText = ""
                isHomeToolbarSearchPresented = false
                isPresentingNewCatalogItem = true
            },
            onToolbarAddItem: {
                newItemPrefillName = nil
                newItemAddToShoppingAfterSave = false
                isPresentingNewCatalogItem = true
            },
            onToolbarSelectGroupsKind: { editGroupsSheetKind = $0 },
            onBackToStore: nil,
            onReturnToStoreAfterRecipeApply: { selectedTab = .store },
            onEditItem: { item in
                inventoryCatalogEditorItem = item
            },
            onDeleteItem: { item in
                inventoryCatalogDeleteConfirmationItem = item
            }
        )
        .navigationBarBackButtonHidden(true)
        .enablesNavigationInteractivePopGesture(isEnabled: !isInventoryReorderMode)
    }

    /// EXPERIMENT: pull-to-add as a sheet with Done (same chrome pattern as Settings).
    /// New Item is nested here so it can present over the sheet.
    /// Focused glass search field (not `.searchable`) so the keyboard rises with the sheet;
    /// sticky UIKit field refuses resign on row taps so the keyboard stays up across adds.
    private var storeTabPullToAddSheet: some View {
        NavigationStack {
            StorePullToAddCatalogSearchView(
                isSearchPresented: $isStorePullToAddSearchPresented,
                searchText: $storePullToAddSearchText,
                pinnedSearchQuery: $storePullToAddPinnedSearchQuery,
                searchChromeID: storePullToAddSearchChromeID,
                onPresentNewItem: { name in
                    newItemAddToShoppingAfterSave = true
                    newItemPrefillName = name
                    isPresentingNewCatalogItem = true
                },
                onEndSearch: endStoreTabPullToAdd,
                usesFocusedSearchField: true
            )
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .environmentObject(store)
        .sheet(isPresented: Binding(
            get: { isPresentingNewCatalogItem && isPresentingPullToAddSheet },
            set: { isPresentingNewCatalogItem = $0 }
        )) {
            NavigationStack {
                NewItemView(
                    prefillName: newItemPrefillName,
                    addToShoppingAfterSave: true,
                    onSaved: restoreStoreAfterPullToAddNewItemIfNeeded,
                    onCancel: restoreStoreAfterPullToAddNewItemIfNeeded
                )
                .environmentObject(store)
            }
        }
    }

    private func presentShoppingListShare() {
        let text = ShoppingListShareText.buildPlainText(
            store: store,
            catalogLanguage: catalogLanguage,
            sortCheckedShoppingItems: sortCheckedShoppingItems
        )
        ShoppingListSharePresentation.presentPlainText(text)
    }

    /// Presents pull-to-add as a sheet (pull gesture or trailing "+" button).
    private func beginStoreTabPullToAdd() {
        guard !isPresentingPullToAddSheet else { return }
        storePullToAddSearchText = ""
        storePullToAddPinnedSearchQuery = ""
        storePullToAddSearchChromeID = UUID()
        isStorePullToAddSearchPresented = true
        isPresentingPullToAddSheet = true
    }

    /// Dismisses the pull-to-add sheet (Done, empty Return, or search Cancel).
    private func endStoreTabPullToAdd() {
        guard isPresentingPullToAddSheet else { return }
        isStorePullToAddSearchPresented = false
        storePullToAddSearchText = ""
        storePullToAddPinnedSearchQuery = ""
        isPresentingPullToAddSheet = false
    }

    var body: some View {
        tabChrome
        .onChange(of: selectedTab) { _, current in
            if current == .home {
                hasVisitedHomeCatalog = true
            }
        }
        .onAppear {
            markFirstShoppingItemExplainerSeenIfShoppingListAlreadyPopulated()
            scheduleWelcomeExplainerIfNeeded()
        }
        .onChange(of: isInventoryReorderMode) { _, active in
            if !active {
                editGroupsSheetKind = nil
            }
        }
        .onChange(of: fullWindowOverlay.inventoryQuickActionResult) { _, result in
            guard let result else { return }
            switch result {
            case .editItem(let id):
                if let item = store.item(for: id) {
                    inventoryCatalogEditorItem = item
                }
            case .deleteItem(let id):
                if let item = store.item(for: id) {
                    inventoryCatalogDeleteConfirmationItem = item
                }
            }
            Task { @MainActor in
                await Task.yield()
                fullWindowOverlay.consumeInventoryQuickActionResult()
            }
        }
        .onChange(of: store.shopping.count) { oldCount, newCount in
            guard oldCount == 0, newCount > 0 else { return }
            scheduleFirstShoppingItemExplainerIfNeeded()
        }
        .onChange(of: hasSeenFirstShoppingItemExplainer) { _, seen in
            guard !seen else { return }
            guard !store.shopping.isEmpty else { return }
            scheduleFirstShoppingItemExplainerIfNeeded()
        }
        .onChange(of: hasSeenWelcomeExplainer) { _, seen in
            guard !seen else { return }
            scheduleWelcomeExplainerIfNeeded()
        }
        .sheet(isPresented: $isPresentingSettings) {
            SettingsView(
                draftTextSizeRaw: $settingsTextSizeDraft,
                draftThemeRaw: $settingsThemeDraft,
                draftCustomColorHex: $settingsThemeCustomDraft,
                onClose: { isPresentingSettings = false }
            )
                .environmentObject(store)
        }
        .onChange(of: isPresentingSettings) { _, presented in
            if presented {
                var stored = textSizeRaw
                AppTextSize.migrateStoredRawValueIfNeeded(&stored)
                if stored != textSizeRaw {
                    textSizeRaw = stored
                }
                settingsTextSizeDraft = textSizeRaw
                settingsThemeDraft = themeRaw
                settingsThemeCustomDraft = customColorHex
            } else {
                commitSettingsTextSizeDraft()
                commitSettingsThemeDraft()
                scheduleExplainersAfterSettingsDismissed()
            }
        }
        .sheet(isPresented: Binding(
            get: { isPresentingNewCatalogItem && !isPresentingPullToAddSheet },
            set: { isPresentingNewCatalogItem = $0 }
        )) {
            NavigationStack {
                NewItemView(
                    prefillName: newItemPrefillName,
                    addToShoppingAfterSave: newItemAddToShoppingAfterSave,
                    onSaved: restoreStoreAfterPullToAddNewItemIfNeeded,
                    onCancel: newItemAddToShoppingAfterSave
                        ? restoreStoreAfterPullToAddNewItemIfNeeded
                        : nil
                )
                    .environmentObject(store)
            }
        }
        .onChange(of: isPresentingNewCatalogItem) { _, presented in
            if !presented {
                newItemAddToShoppingAfterSave = false
            }
        }
        .sheet(item: $inventoryCatalogEditorItem) { item in
            NavigationStack {
                ItemEditorView(item: item)
            }
            .environmentObject(store)
        }
        .sheet(item: $editGroupsSheetKind) { kind in
            NavigationStack {
                GroupTagEditorSheet(kind: kind)
                    .navigationTitle(kind == .inventory ? LocalizedCopy.homeSections : LocalizedCopy.storeSections)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(LocalizedCopy.done) {
                                editGroupsSheetKind = nil
                            }
                            .font(.body.weight(.semibold))
                            .foregroundStyle(appTheme.color)
                        }
                    }
            }
            .environmentObject(store)
        }
        .alert(
            LocalizedCopy.deleteThisItemAlertTitle,
            isPresented: Binding(
                get: { inventoryCatalogDeleteConfirmationItem != nil },
                set: { if !$0 { inventoryCatalogDeleteConfirmationItem = nil } }
            )
        ) {
            Button(LocalizedCopy.cancel, role: .cancel) {
                inventoryCatalogDeleteConfirmationItem = nil
            }
            Button(LocalizedCopy.delete, role: .destructive) {
                if let item = inventoryCatalogDeleteConfirmationItem {
                    withAnimation(.snappy) {
                        store.deleteCatalogItem(item.id)
                    }
                }
                inventoryCatalogDeleteConfirmationItem = nil
            }
        } message: {
            if let item = inventoryCatalogDeleteConfirmationItem {
                Text(LocalizedCopy.deleteItemMessage(itemName: item.displayName(appContentLanguage: catalogLanguage)))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .shareExtensionShoppingOpsMerged)) { note in
            let count = note.userInfo?[ShareExtensionAppGroupSupport.mergedOpCountUserInfoKey] as? Int ?? 0
            guard count > 0 else { return }
            selectedTab = .store
            isPresentingPullToAddSheet = false
            isStorePullToAddSearchPresented = false
            storePullToAddSearchText = ""
            storePullToAddPinnedSearchQuery = ""
        }
    }

    private func commitSettingsTextSizeDraft() {
        guard settingsTextSizeDraft != textSizeRaw else { return }
        withAnimation(AppTextSize.layoutCommitAnimation) {
            textSizeRaw = settingsTextSizeDraft
        }
    }

    private func commitSettingsThemeDraft() {
        guard settingsThemeDraft != themeRaw || settingsThemeCustomDraft != customColorHex else { return }
        themeRaw = settingsThemeDraft
        customColorHex = settingsThemeCustomDraft
    }

    /// Restore used after pull-to-add → Create Item → Save (and Cancel).
    private func restoreStoreAfterPullToAddNewItemIfNeeded() {
        homeInventorySearchText = ""
        storePullToAddSearchText = ""
        storePullToAddPinnedSearchQuery = ""
        isStorePullToAddSearchPresented = false
        isPresentingNewCatalogItem = false
        endStoreTabPullToAdd()
    }

    @ViewBuilder
    private func fullWindowOverlayContent(kind: FullWindowOverlayCoordinator.Kind) -> some View {
        switch kind {
        case .shoppingPhotoPreview(let itemID):
            ItemImageCompactPreviewOverlay(itemID: itemID) {
                fullWindowOverlay.dismiss()
            } onEditItem: {
                fullWindowOverlay.inventoryEditTapped(forItemID: itemID)
            }
        case .welcomeExplainer:
            WelcomeExplainerOverlay {
                hasSeenWelcomeExplainer = true
                fullWindowOverlay.dismiss(animated: false)
                scheduleFirstShoppingItemExplainerIfNeeded()
            }
        case .firstShoppingItemExplainer:
            HomeFirstVisitExplainerOverlay {
                hasSeenFirstShoppingItemExplainer = true
                fullWindowOverlay.dismiss(animated: false)
            }
        case .storeGesturesExplainer:
            StoreGesturesExplainerOverlay {
                hasSeenStoreGesturesExplainer = true
                fullWindowOverlay.dismiss(animated: false)
            }
        }
    }

    private func markFirstShoppingItemExplainerSeenIfShoppingListAlreadyPopulated() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: AppHomeFirstVisitExplainer.legacyPopulationMigrationKey) else { return }
        defaults.set(true, forKey: AppHomeFirstVisitExplainer.legacyPopulationMigrationKey)
        guard !store.shopping.isEmpty else { return }
        hasSeenFirstShoppingItemExplainer = true
    }

    private func scheduleExplainersAfterSettingsDismissed() {
        Task { @MainActor in
            await Task.yield()
            scheduleWelcomeExplainerIfNeeded()
            scheduleFirstShoppingItemExplainerIfNeeded()
            scheduleStoreGesturesExplainerIfNeeded()
        }
    }

    private func scheduleWelcomeExplainerIfNeeded() {
        guard !hasSeenWelcomeExplainer else { return }
        welcomeExplainerTask?.cancel()
        welcomeExplainerTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            guard !hasSeenWelcomeExplainer else { return }
            guard fullWindowOverlay.kind == nil else { return }
            fullWindowOverlay.presentWelcomeExplainer()
        }
    }

    private func scheduleFirstShoppingItemExplainerIfNeeded() {
        guard !hasSeenFirstShoppingItemExplainer else { return }
        if isPresentingPullToAddSheet { return }
        dismissKeyboardForFirstItemExplainer()
        firstShoppingItemExplainerTask?.cancel()
        firstShoppingItemExplainerTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            guard !hasSeenFirstShoppingItemExplainer else { return }
            guard !store.shopping.isEmpty else { return }
            if isPresentingPullToAddSheet { return }
            guard fullWindowOverlay.kind == nil else { return }
            fullWindowOverlay.presentFirstShoppingItemExplainer()
        }
    }

    private func scheduleStoreGesturesExplainerIfNeeded() {
        guard !hasSeenStoreGesturesExplainer else { return }
        guard hasVisitedHomeCatalog else { return }
        guard selectedTab == .store else { return }
        guard !isPresentingSettings else { return }
        guard !isStorePullToAddSearchPresented else { return }
        if isPresentingPullToAddSheet { return }
        storeGesturesExplainerTask?.cancel()
        storeGesturesExplainerTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            guard !hasSeenStoreGesturesExplainer else { return }
            guard hasVisitedHomeCatalog else { return }
            guard selectedTab == .store else { return }
            guard !isPresentingSettings else { return }
            guard !isStorePullToAddSearchPresented else { return }
            if isPresentingPullToAddSheet { return }
            guard fullWindowOverlay.kind == nil else { return }
            fullWindowOverlay.presentStoreGesturesExplainer()
        }
    }

    /// Resigns first responder before the first-item explainer overlay (e.g. pull-to-add search field).
    private func dismissKeyboardForFirstItemExplainer() {
        Task { @MainActor in
            await Task.yield()
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }

}

// MARK: - Swipe back with a custom toolbar back control

/// Allows the navigation edge-pop to begin while a list is dragging or decelerating.
private final class NavigationInteractivePopGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var navigationController: UINavigationController?
    var isPopEnabled: Bool = true

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isPopEnabled else { return false }
        guard let navigationController else { return false }
        return navigationController.viewControllers.count > 1
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === navigationController?.interactivePopGestureRecognizer else {
            return false
        }
        return otherGestureRecognizer.view is UIScrollView
            || Self.viewIsInsideScrollView(otherGestureRecognizer.view)
    }

    private static func viewIsInsideScrollView(_ view: UIView?) -> Bool {
        var current = view
        while let node = current {
            if node is UIScrollView { return true }
            current = node.superview
        }
        return false
    }
}

/// UIKit disables edge swipe-back when the system back button is hidden; this re-enables it and
/// coordinates scroll pans so swipe-back works during active list scroll, not only when idle.
private struct NavigationInteractivePopEnabler: UIViewControllerRepresentable {
    var isEnabled: Bool = true

    func makeUIViewController(context: Context) -> UIViewController {
        NavigationInteractivePopEnablerViewController(isPopEnabled: isEnabled)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let controller = uiViewController as? NavigationInteractivePopEnablerViewController else { return }
        controller.isPopEnabled = isEnabled
        controller.applyInteractivePopGestureState()
    }

    private final class NavigationInteractivePopEnablerViewController: UIViewController {
        private let popGestureDelegate = NavigationInteractivePopGestureDelegate()
        private var coordinatedScrollViews = NSHashTable<UIScrollView>.weakObjects()
        var isPopEnabled: Bool

        init(isPopEnabled: Bool) {
            self.isPopEnabled = isPopEnabled
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            applyInteractivePopGestureState()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            applyInteractivePopGestureState()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            if isPopEnabled {
                coordinateScrollViewsForInteractivePop()
            }
        }

        func applyInteractivePopGestureState() {
            guard let navigationController else { return }
            guard let pop = navigationController.interactivePopGestureRecognizer else { return }

            popGestureDelegate.isPopEnabled = isPopEnabled
            popGestureDelegate.navigationController = navigationController

            guard isPopEnabled, navigationController.viewControllers.count > 1 else {
                pop.isEnabled = false
                return
            }

            pop.isEnabled = true
            pop.delegate = popGestureDelegate

            coordinateScrollViewsForInteractivePop()
            DispatchQueue.main.async { [weak self] in
                self?.coordinateScrollViewsForInteractivePop()
            }
        }

        private func coordinateScrollViewsForInteractivePop() {
            guard isPopEnabled else { return }
            guard let navigationController else { return }
            guard navigationController.viewControllers.count > 1 else { return }
            guard let pop = navigationController.interactivePopGestureRecognizer else { return }

            Self.enumerateScrollViews(in: navigationController.view) { scrollView in
                let pan = scrollView.panGestureRecognizer
                guard pan !== pop else { return }
                guard !coordinatedScrollViews.contains(scrollView) else { return }
                pan.require(toFail: pop)
                coordinatedScrollViews.add(scrollView)
            }
        }

        private static func enumerateScrollViews(in view: UIView, body: (UIScrollView) -> Void) {
            if let scrollView = view as? UIScrollView {
                body(scrollView)
            }
            for subview in view.subviews {
                enumerateScrollViews(in: subview, body: body)
            }
        }
    }
}

private extension View {
    func enablesNavigationInteractivePopGesture(isEnabled: Bool = true) -> some View {
        background(NavigationInteractivePopEnabler(isEnabled: isEnabled))
    }
}
