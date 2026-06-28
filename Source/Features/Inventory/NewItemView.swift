import PhotosUI
import SwiftUI
import UIKit

struct NewItemView: View {
    @EnvironmentObject private var store: GroceryStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appContentLanguage) private var catalogLanguage

    private let prefillName: String?
    /// When true (Store pull-to-add → Home search → Return on unmatched name), item is added to the shopping list after save.
    private let addToShoppingAfterSave: Bool
    /// Called after a successful Save (not when cancelling).
    private let onSaved: (() -> Void)?

    @State private var name: String = ""
    @State private var inventoryTagID: UUID?
    @State private var shoppingTagID: UUID?
    @State private var newItemID = UUID()
    @State private var pendingImage: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isCameraPresented = false
    @State private var isInternetSearchPresented = false

    private var isValid: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasName && inventoryTagID != nil && shoppingTagID != nil
    }

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    init(prefillName: String? = nil, addToShoppingAfterSave: Bool = false, onSaved: (() -> Void)? = nil) {
        self.prefillName = prefillName
        self.addToShoppingAfterSave = addToShoppingAfterSave
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            Section {
                TextField(LocalizedCopy.nameField, text: $name)
                    .textInputAutocapitalization(.words)
                    .multilineTextAlignment(catalogLanguage == .hebrew ? .trailing : .leading)
            }

            Section(LocalizedCopy.sectionsHeader) {
                CatalogItemSectionPicker(
                    label: LocalizedCopy.homeSectionLabel,
                    kind: .inventory,
                    selection: Binding(
                        get: { inventoryTagID ?? store.defaultInventoryTagID },
                        set: { inventoryTagID = $0 }
                    )
                )

                CatalogItemSectionPicker(
                    label: LocalizedCopy.storeSectionLabel,
                    kind: .shopping,
                    selection: Binding(
                        get: { shoppingTagID ?? store.defaultShoppingTagID },
                        set: { shoppingTagID = $0 }
                    )
                )
            }

            Section(LocalizedCopy.photo) {
                if let ui = pendingImage {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .clipped()
                        .listRowInsets(EdgeInsets())
                }

                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Label(LocalizedCopy.chooseFromLibrary, systemImage: "photo.on.rectangle.angled")
                }

                if cameraAvailable {
                    Button {
                        isCameraPresented = true
                    } label: {
                        Label(LocalizedCopy.takePhoto, systemImage: "camera")
                    }
                }

                if pendingImage != nil {
                    Button(role: .destructive) {
                        pendingImage = nil
                    } label: {
                        Text(LocalizedCopy.removePhoto)
                    }
                }
            }
        }
        .navigationTitle(LocalizedCopy.newItem)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(LocalizedCopy.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedCopy.save) {
                    store.addCatalogItem(
                        name: CatalogContentLocalization.storedItemName(
                            fromDisplay: name,
                            language: catalogLanguage
                        ),
                        inventoryTagID: inventoryTagID ?? store.defaultInventoryTagID,
                        shoppingTagID: shoppingTagID ?? store.defaultShoppingTagID,
                        id: newItemID,
                        image: pendingImage
                    )
                    if addToShoppingAfterSave {
                        store.addToShopping(itemID: newItemID, quantity: 1)
                    }
                    onSaved?()
                    dismiss()
                }
                .disabled(!isValid)
            }
        }
        .onAppear {
            if inventoryTagID == nil { inventoryTagID = store.defaultInventoryTagID }
            if shoppingTagID == nil { shoppingTagID = store.defaultShoppingTagID }
            if let prefillName, name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                name = prefillName
            }
        }
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data)
                {
                    await MainActor.run {
                        pendingImage = ui
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPicker(isPresented: $isCameraPresented) { img in
                pendingImage = img
            }
            .ignoresSafeArea()
        }
    }
}
