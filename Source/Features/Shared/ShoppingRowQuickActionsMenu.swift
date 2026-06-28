import SwiftUI
import UIKit

private enum ShoppingRowContextMenuMetrics {
    static let previewImageSide: CGFloat = 300
    static let previewCornerRadius: CGFloat = 40
    static let symbolPointSize: CGFloat = 22
    static let quantityFontSize: CGFloat = 17
    /// Lets the UIKit context menu finish dismissing before SwiftUI animates list changes.
    static let postMenuListChangeDelayMs: UInt64 = 220
}

/// Hosts the shopping row and attaches a UIKit context menu that can refresh while open.
@MainActor
struct ShoppingListRowContextMenuHost<Row: View>: View {
    @EnvironmentObject private var store: GroceryStore
    @Environment(\.appContentLanguage) private var catalogLanguage
    @StateObject private var quantitySwipeState = ShoppingRowQuantitySwipeState()

    let entry: ShoppingEntry
    let item: GroceryItem
    let showsPhotoPreview: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    private let rowBuilder: () -> Row

    init(
        entry: ShoppingEntry,
        item: GroceryItem,
        showsPhotoPreview: Bool,
        onTap: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        @ViewBuilder row: @escaping () -> Row
    ) {
        self.entry = entry
        self.item = item
        self.showsPhotoPreview = showsPhotoPreview
        self.onTap = onTap
        self.onEdit = onEdit
        self.rowBuilder = row
    }

    private var quantitySwipeExclusionWidth: CGFloat {
        ShoppingQuantitySwipeMetrics.contextMenuQuantityEdgePassThroughWidth
    }

    private var quantitySwipeOnPhysicalLeadingEdge: Bool {
        CatalogLayoutMirroring.quantityPillOnPhysicalLeadingEdge(for: catalogLanguage)
    }

    private var revealsQuantityFromLeading: Bool {
        quantitySwipeOnPhysicalLeadingEdge
    }

    var body: some View {
        rowBuilder()
            .environmentObject(quantitySwipeState)
            .overlay {
                ShoppingRowUIKitContextMenu(
                    entry: entry,
                    item: item,
                    showsPhotoPreview: showsPhotoPreview,
                    quantitySwipeEnabled: !entry.isChecked,
                    quantitySwipeOnPhysicalLeadingEdge: quantitySwipeOnPhysicalLeadingEdge,
                    quantitySwipeExclusionWidth: quantitySwipeExclusionWidth,
                    revealsQuantityFromLeading: revealsQuantityFromLeading,
                    quantitySwipeState: quantitySwipeState,
                    onIncrementQuantity: {
                        store.incrementUncheckedShoppingQuantity(itemID: item.id, delta: 1, playHaptic: false)
                    },
                    onTap: onTap,
                    onEdit: onEdit
                )
                .listRowFullBleedHitArea()
            }
    }
}

@MainActor
private struct ShoppingRowUIKitContextMenu: UIViewRepresentable {
    @EnvironmentObject private var store: GroceryStore
    @Environment(\.appContentLanguage) private var catalogLanguage
    @Environment(\.appTheme) private var appTheme

    let entry: ShoppingEntry
    let item: GroceryItem
    let showsPhotoPreview: Bool
    let quantitySwipeEnabled: Bool
    let quantitySwipeOnPhysicalLeadingEdge: Bool
    let quantitySwipeExclusionWidth: CGFloat
    let revealsQuantityFromLeading: Bool
    let quantitySwipeState: ShoppingRowQuantitySwipeState
    let onIncrementQuantity: () -> Void
    let onTap: () -> Void
    let onEdit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> ListRowContextMenuTouchView {
        let view = ListRowContextMenuTouchView()
        applyTouchRouting(to: view, coordinator: context.coordinator)
        view.syncQuantitySwipeRecognizer()

        let interaction = UIContextMenuInteraction(delegate: context.coordinator)
        view.addInteraction(interaction)
        context.coordinator.interaction = interaction
        context.coordinator.menuQuantity = entry.quantity

        return view
    }

    func updateUIView(_ uiView: ListRowContextMenuTouchView, context: Context) {
        context.coordinator.parent = self
        applyTouchRouting(to: uiView, coordinator: context.coordinator)
        uiView.syncQuantitySwipeRecognizer()
        if !context.coordinator.isMenuVisible {
            context.coordinator.menuQuantity = entry.quantity
        }
    }

    private func applyTouchRouting(to view: ListRowContextMenuTouchView, coordinator: Coordinator) {
        view.onTap = { [weak coordinator] in
            coordinator?.parent.onTap()
        }
        view.quantitySwipeEnabled = quantitySwipeEnabled
        view.quantitySwipeOnPhysicalLeadingEdge = quantitySwipeOnPhysicalLeadingEdge
        view.quantityEdgeExclusionWidth = quantitySwipeExclusionWidth
        view.revealsQuantityFromLeading = revealsQuantityFromLeading
        view.onQuantitySwipeDragChanged = { [weak coordinator] amount in
            guard let coordinator else { return }
            coordinator.parent.quantitySwipeState.handleDragChanged(
                amount,
                isActive: coordinator.parent.quantitySwipeEnabled
            )
        }
        view.onQuantitySwipeDragEnded = { [weak coordinator] reachedThreshold in
            guard let coordinator else { return }
            coordinator.parent.quantitySwipeState.handleDragEnded(
                reachedThreshold: reachedThreshold,
                isActive: coordinator.parent.quantitySwipeEnabled,
                entryQuantity: coordinator.parent.entry.quantity,
                revealsFromLeading: coordinator.parent.revealsQuantityFromLeading,
                layoutDirection: CatalogLayoutMirroring.catalogLayoutDirection(
                    for: coordinator.parent.catalogLanguage
                ),
                onIncrement: coordinator.parent.onIncrementQuantity
            )
        }
    }

    @MainActor
    final class Coordinator: NSObject, UIContextMenuInteractionDelegate {
        var parent: ShoppingRowUIKitContextMenu
        weak var interaction: UIContextMenuInteraction?
        var menuQuantity: Int
        var isMenuVisible = false
        private weak var menuPreviewListCell: UICollectionViewListCell?

        init(parent: ShoppingRowUIKitContextMenu) {
            self.parent = parent
            menuQuantity = parent.entry.quantity
        }

        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            configurationForMenuAtLocation location: CGPoint
        ) -> UIContextMenuConfiguration? {
            if parent.quantitySwipeEnabled,
               let view = interaction.view as? ListRowContextMenuTouchView,
               view.isQuantityEdgePoint(location) {
                return nil
            }

            menuQuantity = parent.entry.quantity
            resetRowPreviewState()
            let showsPhotoPreview = Self.showsPhotoPreview(for: parent)

            return UIContextMenuConfiguration(
                identifier: nil,
                previewProvider: showsPhotoPreview ? { [weak self] in
                    guard let self,
                          let image = ItemImageStore.loadImage(forItemID: self.parent.item.id) else {
                        return UIViewController()
                    }
                    return self.makeImagePreviewController(image: image)
                } : nil,
                actionProvider: { [weak self] _ in
                    self?.buildMenu() ?? UIMenu(children: [])
                }
            )
        }

        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration
        ) -> UITargetedPreview? {
            rowTargetedPreview(for: interaction)
        }

        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration
        ) -> UITargetedPreview? {
            rowTargetedPreview(for: interaction)
        }

        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            willDisplayMenuFor configuration: UIContextMenuConfiguration,
            animator: UIContextMenuInteractionAnimating?
        ) {
            isMenuVisible = true
            menuQuantity = parent.entry.quantity
        }

        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            willEndFor configuration: UIContextMenuConfiguration,
            animator: UIContextMenuInteractionAnimating?
        ) {
            isMenuVisible = false
            menuPreviewListCell = nil
        }

        func decrementQuantity() {
            guard menuQuantity > 1 else { return }
            parent.store.adjustShoppingEntryQuantity(entryID: parent.entry.id, delta: -1)
            menuQuantity -= 1
            refreshVisibleMenu()
        }

        func incrementQuantity() {
            parent.store.adjustShoppingEntryQuantity(entryID: parent.entry.id, delta: 1)
            menuQuantity += 1
            refreshVisibleMenu()
        }

        private func refreshVisibleMenu() {
            interaction?.updateVisibleMenu { [weak self] _ in
                self?.buildMenu() ?? UIMenu(children: [])
            }
        }

        private func performAnimatedListChangeAfterMenuDismiss(_ change: @escaping @MainActor () -> Void) {
            Task { @MainActor in
                try? await Task.sleep(
                    for: .milliseconds(ShoppingRowContextMenuMetrics.postMenuListChangeDelayMs)
                )
                withAnimation(AppTextSize.layoutCommitAnimation, change)
            }
        }

        func buildMenu() -> UIMenu {
            var children: [UIMenuElement] = []

            if !parent.entry.isChecked {
                children.append(quantityInlineMenu())
            }

            children.append(
                UIAction(
                    title: LocalizedCopy.editItemMenu,
                    image: UIImage(systemName: "square.and.pencil")
                ) { [weak self] _ in
                    self?.parent.onEdit()
                }
            )

            let moveChildren = CatalogMoveNewSectionPrompt.sectionMoveElements(
                tags: parent.store.shoppingTags,
                language: parent.catalogLanguage,
                onSelectTag: { [weak self] tagID in
                    guard let self else { return }
                    performAnimatedListChangeAfterMenuDismiss {
                        guard var updated = self.parent.store.item(for: self.parent.item.id) else { return }
                        updated.shoppingTagID = tagID
                        self.parent.store.updateCatalogItem(updated)
                    }
                },
                onNewSection: { [weak self] in
                    guard let self else { return }
                    guard let view = self.interaction?.view else { return }
                    CatalogMoveNewSectionPrompt.presentAfterMenuDismiss(from: view) { [weak self] displayTitle in
                        guard let self else { return }
                        let stored = CatalogContentLocalization.storedTagTitle(
                            fromDisplay: displayTitle,
                            language: self.parent.catalogLanguage
                        )
                        guard let tagID = self.parent.store.addTag(kind: .shopping, title: stored) else { return }
                        self.performAnimatedListChangeAfterMenuDismiss {
                            guard var updated = self.parent.store.item(for: self.parent.item.id) else { return }
                            updated.shoppingTagID = tagID
                            self.parent.store.updateCatalogItem(updated)
                        }
                    }
                }
            )
            children.append(
                UIMenu(
                    title: LocalizedCopy.moveItem,
                    image: UIImage(systemName: "folder"),
                    children: moveChildren
                )
            )

            children.append(
                UIAction(
                    title: LocalizedCopy.removeItem,
                    image: UIImage(systemName: "xmark.app"),
                    attributes: .destructive
                ) { [weak self] _ in
                    guard let self else { return }
                    withAnimation(.snappy) {
                        self.parent.store.removeEntry(entryID: self.parent.entry.id)
                    }
                }
            )

            return UIMenu(children: children)
        }

        private func quantityInlineMenu() -> UIMenu {
            let themeColor = UIColor(parent.appTheme.color)
            let minusColor = menuQuantity <= 1 ? UIColor.secondaryLabel : themeColor
            var minusAttributes: UIMenuElement.Attributes = .keepsMenuPresented
            if menuQuantity <= 1 {
                minusAttributes.insert(.disabled)
            }

            let minus = UIAction(
                title: "",
                image: Self.themedSymbolImage(systemName: "minus.circle.fill", color: minusColor),
                attributes: minusAttributes
            ) { [weak self] _ in
                self?.decrementQuantity()
            }
            minus.accessibilityLabel = LocalizedCopy.decreaseQuantity

            let quantity = UIAction(
                title: "",
                image: Self.quantityImage(quantity: menuQuantity, color: themeColor),
                attributes: .disabled,
                handler: { _ in }
            )
            quantity.accessibilityLabel = LocalizedCopy.quantityAccessibility(menuQuantity)

            let plus = UIAction(
                title: "",
                image: Self.themedSymbolImage(systemName: "plus.circle.fill", color: themeColor),
                attributes: .keepsMenuPresented
            ) { [weak self] _ in
                self?.incrementQuantity()
            }
            plus.accessibilityLabel = LocalizedCopy.increaseQuantity

            let inlineMenu = UIMenu(title: "", options: .displayInline, children: [minus, quantity, plus])
            inlineMenu.preferredElementSize = .small
            return inlineMenu
        }

        private func resetRowPreviewState() {
            menuPreviewListCell = nil
        }

        private func rowTargetedPreview(for interaction: UIContextMenuInteraction) -> UITargetedPreview? {
            guard let listCell = Self.listCell(around: interaction.view) else { return nil }

            menuPreviewListCell = listCell
            return ListRowContextMenuPreviewChrome.targetedPreview(for: listCell)
        }

        private static func showsPhotoPreview(for parent: ShoppingRowUIKitContextMenu) -> Bool {
            parent.showsPhotoPreview && ItemImageStore.loadImage(forItemID: parent.item.id) != nil
        }

        private static func listCell(around view: UIView?) -> UICollectionViewListCell? {
            var current = view
            while let candidate = current {
                if let listCell = candidate as? UICollectionViewListCell {
                    return listCell
                }
                current = candidate.superview
            }
            return nil
        }

        private func makeImagePreviewController(image: UIImage) -> UIViewController {
            let side = ShoppingRowContextMenuMetrics.previewImageSide
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = ShoppingRowContextMenuMetrics.previewCornerRadius
            imageView.layer.cornerCurve = .continuous
            imageView.frame = CGRect(x: 0, y: 0, width: side, height: side)

            let controller = UIViewController()
            controller.view = imageView
            controller.preferredContentSize = imageView.frame.size
            return controller
        }

        private static func themedSymbolImage(systemName: String, color: UIColor) -> UIImage? {
            let config = UIImage.SymbolConfiguration(
                pointSize: ShoppingRowContextMenuMetrics.symbolPointSize,
                weight: .semibold
            )
            return UIImage(systemName: systemName, withConfiguration: config)?
                .withTintColor(color, renderingMode: .alwaysOriginal)
        }

        private static func quantityImage(quantity: Int, color: UIColor) -> UIImage {
            let text = "\(quantity)" as NSString
            let font = UIFont.monospacedDigitSystemFont(
                ofSize: ShoppingRowContextMenuMetrics.quantityFontSize,
                weight: .bold
            )
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
            ]
            let size = text.size(withAttributes: attributes)
            let canvas = CGSize(
                width: max(ceil(size.width), ShoppingRowContextMenuMetrics.quantityFontSize),
                height: max(ceil(size.height), ShoppingRowContextMenuMetrics.quantityFontSize)
            )
            let renderer = UIGraphicsImageRenderer(size: canvas)
            return renderer.image { _ in
                let origin = CGPoint(
                    x: (canvas.width - size.width) / 2,
                    y: (canvas.height - size.height) / 2
                )
                text.draw(at: origin, withAttributes: attributes)
            }
        }
    }
}

/// Opaque background for UIKit long-press row previews while list rows stay transparent for glass halos.
enum ListRowContextMenuPreviewChrome {
    static func targetedPreview(for listCell: UICollectionViewListCell) -> UITargetedPreview {
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .clear : .white
        }
        return UITargetedPreview(view: listCell, parameters: parameters)
    }
}

final class ListRowContextMenuTouchView: UIView {
    var onTap: (() -> Void)?
    /// Home catalog: pass quantity-pill taps through to SwiftUI beneath the overlay.
    var passesThroughLeadingQuantityEdge = false
    var passesThroughTrailingQuantityEdge = false
    var quantitySwipeEnabled = false
    var quantitySwipeOnPhysicalLeadingEdge = false
    var quantityEdgeExclusionWidth: CGFloat = 0
    var revealsQuantityFromLeading = false
    var onQuantitySwipeDragChanged: ((CGFloat) -> Void)?
    var onQuantitySwipeDragEnded: ((Bool) -> Void)?

    private let gestureDelegate = ListRowTouchGestureDelegate()
    private var quantityPanRecognizer: UIPanGestureRecognizer?
    private var horizontalQuantityDragActive = false
    private weak var lockedScrollView: UIScrollView?
    private var scrollWasEnabled = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gestureDelegate.touchView = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.delegate = gestureDelegate
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func isQuantityEdgePoint(_ point: CGPoint) -> Bool {
        guard quantitySwipeEnabled, quantityEdgeExclusionWidth > 0 else { return false }
        if quantitySwipeOnPhysicalLeadingEdge {
            return point.x <= quantityEdgeExclusionWidth
        }
        return point.x >= bounds.width - quantityEdgeExclusionWidth
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else { return nil }
        if passesThroughLeadingQuantityEdge, point.x <= quantityEdgeExclusionWidth {
            return nil
        }
        if passesThroughTrailingQuantityEdge, point.x >= bounds.width - quantityEdgeExclusionWidth {
            return nil
        }
        return super.hitTest(point, with: event)
    }

    func syncQuantitySwipeRecognizer() {
        if quantitySwipeEnabled {
            if quantityPanRecognizer == nil {
                let pan = UIPanGestureRecognizer(target: self, action: #selector(handleQuantityPan(_:)))
                pan.cancelsTouchesInView = false
                pan.delegate = gestureDelegate
                addGestureRecognizer(pan)
                quantityPanRecognizer = pan
            }
        } else if let quantityPanRecognizer {
            removeGestureRecognizer(quantityPanRecognizer)
            self.quantityPanRecognizer = nil
        }
    }

    @objc private func handleTap() {
        onTap?()
    }

    @objc private func handleQuantityPan(_ pan: UIPanGestureRecognizer) {
        guard quantitySwipeEnabled else { return }

        switch pan.state {
        case .began, .changed:
            let translation = pan.translation(in: self)
            if !horizontalQuantityDragActive {
                let absX = abs(translation.x)
                let absY = abs(translation.y)
                guard max(absX, absY) >= 5 else { return }
                guard absX > absY * ShoppingQuantitySwipeMetrics.horizontalDominanceRatio else {
                    return
                }
                horizontalQuantityDragActive = true
                lockScroll()
            }

            let rawDrag = ShoppingQuantitySwipeMetrics.rawDragAmount(
                translation: translation,
                revealsFromLeading: revealsQuantityFromLeading
            )
            onQuantitySwipeDragChanged?(rawDrag)
        case .ended, .cancelled:
            defer {
                horizontalQuantityDragActive = false
                unlockScroll()
            }
            guard horizontalQuantityDragActive else {
                onQuantitySwipeDragEnded?(false)
                return
            }
            let translation = pan.translation(in: self)
            let rawDrag = ShoppingQuantitySwipeMetrics.rawDragAmount(
                translation: translation,
                revealsFromLeading: revealsQuantityFromLeading
            )
            onQuantitySwipeDragEnded?(
                ShoppingQuantitySwipeMetrics.hasReachedThreshold(rawDrag: rawDrag)
            )
        default:
            horizontalQuantityDragActive = false
            unlockScroll()
        }
    }

    private func lockScroll() {
        guard lockedScrollView == nil,
              let scrollView = Self.findScrollView(from: self) else {
            return
        }
        scrollWasEnabled = scrollView.isScrollEnabled
        scrollView.isScrollEnabled = false
        lockedScrollView = scrollView
    }

    private func unlockScroll() {
        guard let scrollView = lockedScrollView else { return }
        scrollView.isScrollEnabled = scrollWasEnabled
        lockedScrollView = nil
    }

    fileprivate static func findScrollView(from view: UIView?) -> UIScrollView? {
        var current = view
        while let node = current {
            if let scrollView = node as? UIScrollView { return scrollView }
            current = node.superview
        }
        return nil
    }

    fileprivate static func viewIsInsideScrollView(_ view: UIView?) -> Bool {
        findScrollView(from: view) != nil
    }

    fileprivate func isQuantityPanRecognizer(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === quantityPanRecognizer
    }
}

/// Gesture delegate kept off `UIView` so iOS 26's `UIView.gestureRecognizerShouldBegin` override does not conflict with `UIGestureRecognizerDelegate`.
private final class ListRowTouchGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var touchView: ListRowContextMenuTouchView?

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let touchView else { return true }
        if touchView.isQuantityPanRecognizer(gestureRecognizer) {
            guard touchView.quantitySwipeEnabled else { return false }
            let point = gestureRecognizer.location(in: touchView)
            return touchView.isQuantityEdgePoint(point)
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard let touchView else { return true }
        let point = touch.location(in: touchView)
        if touchView.isQuantityPanRecognizer(gestureRecognizer) {
            return touchView.isQuantityEdgePoint(point)
        }
        guard gestureRecognizer is UITapGestureRecognizer, touchView.quantitySwipeEnabled else { return true }
        return !touchView.isQuantityEdgePoint(point)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard let touchView, touchView.isQuantityPanRecognizer(gestureRecognizer) else { return false }
        // Don't defer the quantity pan behind scroll or context-menu long-press.
        return false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard let touchView, touchView.isQuantityPanRecognizer(gestureRecognizer) else { return false }
        return otherGestureRecognizer.view is UIScrollView
            || ListRowContextMenuTouchView.viewIsInsideScrollView(otherGestureRecognizer.view)
    }
}
