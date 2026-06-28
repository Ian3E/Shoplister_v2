import SwiftUI
import UIKit

private enum HomeCatalogRowContextMenuMetrics {
    /// Lets the UIKit context menu finish dismissing before SwiftUI animates list changes.
    static let postMenuListChangeDelayMs: UInt64 = 220
}

/// Hosts a home catalog row and attaches a UIKit context menu (browse mode only).
@MainActor
struct HomeCatalogRowContextMenuHost<Row: View>: View {
    let isEnabled: Bool
    let item: GroceryItem
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let row: Row

    init(
        isEnabled: Bool,
        item: GroceryItem,
        onTap: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        @ViewBuilder row: () -> Row
    ) {
        self.isEnabled = isEnabled
        self.item = item
        self.onTap = onTap
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.row = row()
    }

    var body: some View {
        row
            .overlay {
                HomeCatalogUIKitContextMenu(
                    item: item,
                    isEnabled: isEnabled,
                    onTap: onTap,
                    onEdit: onEdit,
                    onDelete: onDelete
                )
                .listRowFullBleedHitArea()
            }
    }
}

@MainActor
private struct HomeCatalogUIKitContextMenu: UIViewRepresentable {
    @EnvironmentObject private var store: GroceryStore
    @Environment(\.appContentLanguage) private var catalogLanguage

    let item: GroceryItem
    let isEnabled: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> ListRowContextMenuTouchView {
        let view = ListRowContextMenuTouchView()
        applyTouchRouting(to: view, coordinator: context.coordinator)

        let interaction = UIContextMenuInteraction(delegate: context.coordinator)
        view.addInteraction(interaction)
        context.coordinator.interaction = interaction
        applyEnabledState(to: view, coordinator: context.coordinator)

        return view
    }

    func updateUIView(_ uiView: ListRowContextMenuTouchView, context: Context) {
        context.coordinator.parent = self
        applyTouchRouting(to: uiView, coordinator: context.coordinator)
        applyEnabledState(to: uiView, coordinator: context.coordinator)
    }

    private func applyTouchRouting(to view: ListRowContextMenuTouchView, coordinator: Coordinator) {
        view.onTap = { [weak coordinator] in
            coordinator?.parent.onTap()
        }

        let exclusionWidth = quantityPillEdgeExclusionWidth
        let pillOnPhysicalLeadingEdge = CatalogLayoutMirroring.quantityPillOnPhysicalLeadingEdge(
            for: catalogLanguage
        )
        view.passesThroughLeadingQuantityEdge = exclusionWidth > 0 && pillOnPhysicalLeadingEdge
        view.passesThroughTrailingQuantityEdge = exclusionWidth > 0 && !pillOnPhysicalLeadingEdge
        view.quantityEdgeExclusionWidth = exclusionWidth
    }

    /// Lets the SwiftUI quantity pill receive taps instead of the row toggle.
    private var quantityPillEdgeExclusionWidth: CGFloat {
        guard let entry = store.shopping.first(where: { $0.itemID == item.id }) else { return 0 }
        return CatalogListRowDensity.quantityPillLiveReservedWidth(forQuantity: entry.quantity)
            + CatalogListRowDensity.quantityPillHorizontalNudge
            + 6
    }

    private func applyEnabledState(to view: ListRowContextMenuTouchView, coordinator: Coordinator) {
        // When disabled (edit mode), pass touches through to the row's SwiftUI gestures.
        view.isUserInteractionEnabled = isEnabled
    }

    @MainActor
    final class Coordinator: NSObject, UIContextMenuInteractionDelegate {
        var parent: HomeCatalogUIKitContextMenu
        weak var interaction: UIContextMenuInteraction?
        var isMenuVisible = false
        private weak var menuPreviewListCell: UICollectionViewListCell?

        init(parent: HomeCatalogUIKitContextMenu) {
            self.parent = parent
        }

        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            configurationForMenuAtLocation location: CGPoint
        ) -> UIContextMenuConfiguration? {
            guard parent.isEnabled else { return nil }
            resetRowPreviewState()

            return UIContextMenuConfiguration(
                identifier: nil,
                previewProvider: nil,
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
        }

        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            willEndFor configuration: UIContextMenuConfiguration,
            animator: UIContextMenuInteractionAnimating?
        ) {
            isMenuVisible = false
            menuPreviewListCell = nil
        }

        private func performAnimatedListChangeAfterMenuDismiss(_ change: @escaping @MainActor () -> Void) {
            Task { @MainActor in
                try? await Task.sleep(
                    for: .milliseconds(HomeCatalogRowContextMenuMetrics.postMenuListChangeDelayMs)
                )
                withAnimation(AppTextSize.layoutCommitAnimation, change)
            }
        }

        func buildMenu() -> UIMenu {
            let edit = UIAction(
                title: LocalizedCopy.editItemMenu,
                image: UIImage(systemName: "square.and.pencil")
            ) { [weak self] _ in
                self?.parent.onEdit()
            }

            let moveChildren = CatalogMoveNewSectionPrompt.sectionMoveElements(
                tags: parent.store.inventoryTags,
                language: parent.catalogLanguage,
                onSelectTag: { [weak self] tagID in
                    guard let self else { return }
                    performAnimatedListChangeAfterMenuDismiss {
                        guard var updated = self.parent.store.item(for: self.parent.item.id) else { return }
                        updated.inventoryTagID = tagID
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
                        guard let tagID = self.parent.store.addTag(kind: .inventory, title: stored) else { return }
                        self.performAnimatedListChangeAfterMenuDismiss {
                            guard var updated = self.parent.store.item(for: self.parent.item.id) else { return }
                            updated.inventoryTagID = tagID
                            self.parent.store.updateCatalogItem(updated)
                        }
                    }
                }
            )
            let move = UIMenu(
                title: LocalizedCopy.moveItem,
                image: UIImage(systemName: "folder"),
                children: moveChildren
            )

            let delete = UIAction(
                title: LocalizedCopy.deleteItemMenu,
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.parent.onDelete()
            }

            return UIMenu(children: [edit, move, delete])
        }

        private func resetRowPreviewState() {
            menuPreviewListCell = nil
        }

        private func rowTargetedPreview(for interaction: UIContextMenuInteraction) -> UITargetedPreview? {
            guard let listCell = Self.listCell(around: interaction.view) else { return nil }

            menuPreviewListCell = listCell
            return ListRowContextMenuPreviewChrome.targetedPreview(for: listCell)
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
    }
}
