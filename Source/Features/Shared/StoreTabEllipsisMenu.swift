import SwiftUI

private enum StoreToolbarGlyph {
    static let font = Font.system(size: 15, weight: .semibold)
}

/// Store tab leading toolbar control — opens Settings.
struct StoreSettingsToolbarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(LocalizedCopy.settings, systemImage: "gear")
                .labelStyle(.iconOnly)
                .font(StoreToolbarGlyph.font)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .catalogToolbarCircularTapTarget()
        .accessibilityLabel(LocalizedCopy.settings)
    }
}

/// Store tab trailing ⋯ menu (manage sections, clear checked, clear list, share, save as recipe).
struct StoreTabEllipsisMenu: View {
    @EnvironmentObject private var store: GroceryStore

    let canShareShoppingList: Bool
    let hasCheckedLines: Bool
    let hasVisibleLines: Bool
    let hasUncheckedLines: Bool
    @Binding var isPresentingClearAllConfirm: Bool
    let onManageStoreSections: () -> Void
    let onShare: () -> Void
    let onSaveAsRecipe: () -> Void

    private var canClearChecked: Bool {
        hasVisibleLines && hasCheckedLines
    }

    var body: some View {
        Menu {
            Section {
                Button(action: onManageStoreSections) {
                    Label(LocalizedCopy.manageSections, systemImage: "arrow.up.arrow.down")
                }
            }

            Section {
                if store.canUndoClearChecked {
                    Button {
                        withAnimation(.snappy) {
                            store.undoClearChecked()
                        }
                    } label: {
                        Label(LocalizedCopy.undoClearChecked, systemImage: "arrow.uturn.backward")
                    }
                } else {
                    Button {
                        withAnimation(.snappy) {
                            store.clearChecked()
                        }
                    } label: {
                        Label(LocalizedCopy.clearChecked, systemImage: "xmark.app")
                    }
                    .disabled(!canClearChecked)
                }

                if store.canUndoClearShoppingList {
                    Button {
                        withAnimation(.snappy) {
                            store.undoClearShoppingList()
                        }
                    } label: {
                        Label(LocalizedCopy.undoClearList, systemImage: "arrow.uturn.backward")
                    }
                } else {
                    Button(role: .destructive) {
                        isPresentingClearAllConfirm = true
                    } label: {
                        Label(LocalizedCopy.clearList, systemImage: "trash")
                    }
                    .disabled(!hasVisibleLines)
                }

                Button(action: onShare) {
                    Label(LocalizedCopy.shareList, systemImage: "square.and.arrow.up")
                }
                .disabled(!canShareShoppingList)

                Button(action: onSaveAsRecipe) {
                    Label(LocalizedCopy.saveList, systemImage: "square.and.arrow.down")
                }
                .disabled(!hasUncheckedLines)
            }
        } label: {
            Label(LocalizedCopy.menu, systemImage: "ellipsis")
                .labelStyle(.iconOnly)
                .font(StoreToolbarGlyph.font)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .catalogToolbarCircularTapTarget()
        .accessibilityLabel(LocalizedCopy.menu)
    }
}
