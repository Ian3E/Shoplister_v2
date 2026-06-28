import SwiftUI

/// Home or Store section picker for item add/edit forms, with **New section** at the end of the list.
struct CatalogItemSectionPicker: View {
    @EnvironmentObject private var store: GroceryStore
    @Environment(\.appContentLanguage) private var catalogLanguage

    let label: String
    let kind: Tag.Kind
    @Binding var selection: UUID

    /// Sentinel tag value for the trailing **New section** row (not a real section id).
    private static let newSectionPickerToken = UUID(uuidString: "A0A0A0A0-0000-4000-8000-000000000003")!

    @State private var isNewSectionAlertPresented = false
    @State private var newSectionName = ""

    private var tags: [Tag] {
        switch kind {
        case .inventory:
            store.inventoryTags.filter { $0.kind == .inventory }
        case .shopping:
            store.shoppingTags.filter { $0.kind == .shopping }
        }
    }

    var body: some View {
        Picker(label, selection: $selection) {
            Section {
                ForEach(tags) { tag in
                    Text(tag.displayTitle(appContentLanguage: catalogLanguage))
                        .tag(tag.id)
                }
            }
            Section {
                Label(LocalizedCopy.newSection, systemImage: "plus")
                    .tag(Self.newSectionPickerToken)
            }
        }
        .onChange(of: selection) { previous, updated in
            guard updated == Self.newSectionPickerToken else { return }
            selection = previous
            newSectionName = ""
            isNewSectionAlertPresented = true
        }
        .alert(LocalizedCopy.newSection, isPresented: $isNewSectionAlertPresented) {
            TextField(LocalizedCopy.sectionName, text: $newSectionName)
                .textInputAutocapitalization(.words)
            Button(LocalizedCopy.create) {
                createSection()
            }
            .keyboardShortcut(.defaultAction)
            Button(LocalizedCopy.cancel, role: .cancel) {
                newSectionName = ""
            }
        }
    }

    private func createSection() {
        let trimmed = newSectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let stored = CatalogContentLocalization.storedTagTitle(
            fromDisplay: trimmed,
            language: catalogLanguage
        )
        guard let tagID = store.addTag(kind: kind, title: stored) else { return }
        selection = tagID
        newSectionName = ""
    }
}
