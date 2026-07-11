import Combine
import SwiftUI
import UIKit

private enum AppRoute: Hashable {
    case homeCatalog
    case storePullToAdd
}

struct ContentView: View {
    @EnvironmentObject private var store: GroceryStore
    @EnvironmentObject private var fullWindowOverlay: FullWindowOverlayCoordinator
    @Environment(\.appContentLanguage) private var catalogLanguage
    @Environment(\.appTheme) private var appTheme
    @State private var navigationPath = NavigationPath()
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
    /// Mirrors Home `NavigationStack` search presentation for pull-to-add return-to-Store handling.
    @State private var isHomeToolbarSearchPresented = false
    /// Home search field text (lifted here so New Item sheet can clear it after save).
    @State private var homeInventorySearchText = ""
    /// Store pull-to-add: catalog search presented as its own pushed destination so its search field
    /// lives in a toolbar fully isolated from the shopping-dependent Store nav bar.
    @State private var isStorePullToAddSearchPresented = false
    @State private var storePullToAddSearchText = ""
    @State private var storePullToAddPinnedSearchQuery = ""
    /// Stable identity for the pushed pull-to-add search chrome; regenerated only when a session begins,
    /// mirroring Home's `homeToolbarSearchChromeID`, so adds cannot churn the searchable field.
    @State private var storePullToAddSearchChromeID = UUID()
    /// True only when presenting **New Item** after Store pull-to-add; add saved item to shopping list.
    @State private var newItemAddToShoppingAfterSave = false
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

    private var isHomeCatalogPresented: Bool {
        !navigationPath.isEmpty
    }

    @ViewBuilder
    private var mainChromeZStack: some View {
        ZStack(alignment: .bottomLeading) {
            NavigationStack(path: $navigationPath) {
                ShoppingView(
                    canShareShoppingList: canShareShoppingList,
                    isStorePullToAddSearchPresented: $isStorePullToAddSearchPresented,
                    onBeginPullToAddSearch: beginStorePullToAddSearch,
                    showsFloatingOpenHomeButton: !isHomeCatalogPresented,
                    onShare: {
                        let text = ShoppingListShareText.buildPlainText(
                            store: store,
                            catalogLanguage: catalogLanguage,
                            sortCheckedShoppingItems: sortCheckedShoppingItems
                        )
                        ShoppingListSharePresentation.presentPlainText(text)
                    },
                    onSettings: { isPresentingSettings = true },
                    onManageStoreSections: { editGroupsSheetKind = .shopping },
                    onOpenHome: openHomeForBrowse
                )
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .homeCatalog:
                        homeCatalogScreen
                    case .storePullToAdd:
                        storePullToAddScreen
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
    }

    private var homeCatalogScreen: some View {
        InventoryView(
            isReorderMode: $isInventoryReorderMode,
            usesHomeToolbarSearch: true,
            isHomeToolbarSearchPresented: $isHomeToolbarSearchPresented,
            homeSearchText: $homeInventorySearchText,
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
            onBackToStore: dismissHomeCatalog,
            onReturnToStoreAfterRecipeApply: returnToStoreFromHome,
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

    /// Pull-to-add search as a pushed destination. Its own hosting controller/nav bar isolates the
    /// `.searchable` field from `ShoppingView`'s shopping-dependent toolbar, so adds never drop the
    /// keyboard. Presenting and dismissing are instant cuts (no push/pop slide).
    private var storePullToAddScreen: some View {
        StorePullToAddDestination(
            isSearchPresented: $isStorePullToAddSearchPresented,
            searchText: $storePullToAddSearchText,
            pinnedSearchQuery: $storePullToAddPinnedSearchQuery,
            searchChromeID: storePullToAddSearchChromeID,
            onPresentNewItem: { name in
                newItemAddToShoppingAfterSave = true
                newItemPrefillName = name
                isPresentingNewCatalogItem = true
            },
            onEndSearch: endStorePullToAddSearch
        )
        .navigationBarBackButtonHidden(true)
        .enablesNavigationInteractivePopGesture()
    }

    var body: some View {
        mainChromeZStack
        .onAppear {
            markFirstShoppingItemExplainerSeenIfShoppingListAlreadyPopulated()
            scheduleWelcomeExplainerIfNeeded()
        }
        .onChange(of: navigationPath.count) { oldCount, newCount in
            if newCount > 0, !isStorePullToAddSearchPresented {
                hasVisitedHomeCatalog = true
            }
            guard newCount == 0 else { return }
            resetHomeCatalogSessionState()
            if oldCount > 0 {
                scheduleStoreGesturesExplainerIfNeeded()
            }
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
        .sheet(isPresented: $isPresentingNewCatalogItem) {
            NavigationStack {
                NewItemView(
                    prefillName: newItemPrefillName,
                    addToShoppingAfterSave: newItemAddToShoppingAfterSave,
                    onSaved: {
                        homeInventorySearchText = ""
                        storePullToAddSearchText = ""
                        storePullToAddPinnedSearchQuery = ""
                        isStorePullToAddSearchPresented = false
                    }
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
            navigationPath = NavigationPath()
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

    /// Pull-to-add: instant presentation and return to Store (avoids the push/pop slide).
    private func withoutNavigationAnimation(_ updates: () -> Void) {
        var transaction = Transaction()
        transaction.animation = nil
        transaction.disablesAnimations = true
        withTransaction(transaction, updates)
    }

    /// Pushes pull-to-add search as its own destination with an isolated toolbar.
    /// Presents instantly (no push slide) with search already active so the keyboard animates up
    /// immediately instead of waiting for the navigation transition to settle.
    private func beginStorePullToAddSearch() {
        guard navigationPath.isEmpty else { return }
        storePullToAddSearchText = ""
        storePullToAddPinnedSearchQuery = ""
        storePullToAddSearchChromeID = UUID()
        isStorePullToAddSearchPresented = true
        withoutNavigationAnimation {
            navigationPath.append(AppRoute.storePullToAdd)
        }
    }

    /// Dismisses pull-to-add search with an instant cut (no push/pop slide), matching the present.
    /// `UIView.performWithoutAnimation` hard-disables UIKit animations so the navigation bar doesn't
    /// slide/recenter its title when the Store re-lays-out on pop.
    private func endStorePullToAddSearch() {
        guard !navigationPath.isEmpty else { return }
        UIView.performWithoutAnimation {
            withoutNavigationAnimation {
                navigationPath.removeLast()
            }
        }
    }

    private func openHomeForBrowse() {
        guard navigationPath.isEmpty else { return }
        AppHaptics.impact(.medium)
        isStorePullToAddSearchPresented = false
        storePullToAddSearchText = ""
        storePullToAddPinnedSearchQuery = ""
        isHomeToolbarSearchPresented = false
        navigationPath.append(AppRoute.homeCatalog)
    }

    private func dismissHomeCatalog() {
        guard isHomeCatalogPresented else { return }
        navigationPath.removeLast()
    }

    private func returnToStoreFromHome() {
        navigationPath = NavigationPath()
    }

    private func resetHomeCatalogSessionState() {
        isInventoryReorderMode = false
        editGroupsSheetKind = nil
        isHomeToolbarSearchPresented = false
        homeInventorySearchText = ""
        Task { @MainActor in
            await Task.yield()
            await Task.yield()
            HomeToolbarSearchCacheCleaner.clearCachedToolbarSearchField()
        }
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
        dismissKeyboardForFirstItemExplainer()
        firstShoppingItemExplainerTask?.cancel()
        firstShoppingItemExplainerTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            guard !hasSeenFirstShoppingItemExplainer else { return }
            guard !store.shopping.isEmpty else { return }
            guard fullWindowOverlay.kind == nil else { return }
            fullWindowOverlay.presentFirstShoppingItemExplainer()
        }
    }

    private func scheduleStoreGesturesExplainerIfNeeded() {
        guard !hasSeenStoreGesturesExplainer else { return }
        guard hasVisitedHomeCatalog else { return }
        guard !isHomeCatalogPresented else { return }
        guard !isPresentingSettings else { return }
        guard !isStorePullToAddSearchPresented else { return }
        storeGesturesExplainerTask?.cancel()
        storeGesturesExplainerTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            guard !hasSeenStoreGesturesExplainer else { return }
            guard hasVisitedHomeCatalog else { return }
            guard !isHomeCatalogPresented else { return }
            guard !isPresentingSettings else { return }
            guard !isStorePullToAddSearchPresented else { return }
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

// MARK: - Pull-to-add pushed destination

/// Pushed pull-to-add search screen. It owns a navigation bar with no `store.shopping`-dependent items,
/// so the `.searchable` field it hosts is never torn down when an add mutates `store.shopping` — the
/// keyboard stays up across adds, matching Home. Ending search (Cancel) or swiping back pops the screen.
private struct StorePullToAddDestination: View {
    @Binding var isSearchPresented: Bool
    @Binding var searchText: String
    @Binding var pinnedSearchQuery: String
    let searchChromeID: UUID
    let onPresentNewItem: (String) -> Void
    /// Pops the destination without the default push/pop slide, matching the instant present.
    let onEndSearch: () -> Void

    var body: some View {
        StorePullToAddCatalogSearchView(
            isSearchPresented: $isSearchPresented,
            searchText: $searchText,
            pinnedSearchQuery: $pinnedSearchQuery,
            searchChromeID: searchChromeID,
            onPresentNewItem: onPresentNewItem
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: isSearchPresented) { _, presented in
            if !presented {
                onEndSearch()
            }
        }
        .onDisappear {
            isSearchPresented = false
            searchText = ""
            pinnedSearchQuery = ""
        }
    }
}
