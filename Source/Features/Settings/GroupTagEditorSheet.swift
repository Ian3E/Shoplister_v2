import SwiftUI

/// Edit Home or Store section names and order (presented from the Sections toolbar menu).
struct GroupTagEditorSheet: View {
    @EnvironmentObject private var store: GroceryStore
    @Environment(\.appContentLanguage) private var catalogLanguage

    let kind: Tag.Kind

    @State private var newTitle: String = ""
    @FocusState private var isNewGroupFieldFocused: Bool
    @FocusState private var focusedTagID: UUID?
    @State private var listEditMode: EditMode = .active
    @State private var draftTitles: [UUID: String] = [:]

    private var userTags: [Tag] {
        let tags: [Tag] = switch kind {
        case .inventory: store.inventoryTags
        case .shopping: store.shoppingTags
        }
        return tags.filter { !Tag.isUnsortedBucket($0) }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    TextField(LocalizedCopy.newSection, text: $newTitle)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($isNewGroupFieldFocused)
                        .onSubmit(addTag)

                    Button(LocalizedCopy.add, action: addTag)
                        .font(.body.weight(.semibold))
                        .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if !userTags.isEmpty {
                Section {
                    ForEach(userTags) { tag in
                        groupRow(for: tag)
                    }
                    .onDelete(perform: deleteUserTags)
                    .onMove(perform: moveUserTags)
                }
            }
        }
        .listStyle(.insetGrouped)
        .catalogListLayoutDirection()
        .overlay {
            if userTags.isEmpty {
                sectionEditorEmptyState
            }
        }
        .environment(\.editMode, $listEditMode)
        .onAppear {
            listEditMode = .active
        }
        .onDisappear {
            if let focusedTagID {
                commitRename(for: focusedTagID)
            }
        }
        .onChange(of: focusedTagID) { previousFocus, _ in
            if let previousFocus {
                commitRename(for: previousFocus)
            }
        }
        .onChange(of: userTags.map(\.id)) { _, newIDs in
            let validIDs = Set(newIDs)
            draftTitles = draftTitles.filter { validIDs.contains($0.key) }
        }
    }

    private var sectionEditorEmptyState: some View {
        Text(LocalizedCopy.sectionOrganizeFooter)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .catalogListLayoutDirection()
    }

    @ViewBuilder
    private func groupRow(for tag: Tag) -> some View {
        let usesManualMirror = CatalogLayoutMirroring.catalogListUsesManualMirror(for: catalogLanguage)
        let displayTitle = tag.displayTitle(appContentLanguage: catalogLanguage)
        TextField(LocalizedCopy.sectionName, text: titleBinding(for: tag))
            .font(CatalogGroupHeaderChrome.titleFont)
            .foregroundStyle(CatalogGroupHeaderChrome.titleColor)
            .textInputAutocapitalization(.words)
            .submitLabel(.done)
            .focused($focusedTagID, equals: tag.id)
            .multilineTextAlignment(usesManualMirror ? .trailing : .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: usesManualMirror ? .trailing : .leading)
            .onSubmit {
                commitRename(for: tag.id)
                focusedTagID = nil
            }
            .accessibilityLabel(LocalizedCopy.sectionNameAccessibility(displayTitle))
            .listRowFullBleedHitArea(alignment: usesManualMirror ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .catalogListRowSeparatorFullWidth(usesManualMirror)
    }

    private func titleBinding(for tag: Tag) -> Binding<String> {
        Binding(
            get: {
                draftTitles[tag.id] ?? tag.displayTitle(appContentLanguage: catalogLanguage)
            },
            set: { newValue in
                draftTitles[tag.id] = newValue
            }
        )
    }

    private func addTag() {
        isNewGroupFieldFocused = false
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let stored = CatalogContentLocalization.storedTagTitle(fromDisplay: trimmed, language: catalogLanguage)
        store.addTag(kind: kind, title: stored)
        newTitle = ""
    }

    private func commitRename(for tagID: UUID) {
        guard let draft = draftTitles[tagID] else { return }
        draftTitles.removeValue(forKey: tagID)

        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let tag = userTags.first(where: { $0.id == tagID }) else { return }

        let stored = CatalogContentLocalization.storedTagTitle(fromDisplay: trimmed, language: catalogLanguage)
        guard stored != tag.title else { return }

        store.renameTag(kind: kind, tagID: tagID, newTitle: stored)
    }

    private func deleteUserTags(at offsets: IndexSet) {
        withAnimation(.snappy) {
            for index in offsets {
                let tag = userTags[index]
                draftTitles.removeValue(forKey: tag.id)
                if focusedTagID == tag.id {
                    focusedTagID = nil
                }
                store.deleteTag(kind: kind, tagID: tag.id)
            }
        }
    }

    private func moveUserTags(from source: IndexSet, to destination: Int) {
        switch kind {
        case .inventory:
            store.moveUserInventoryTags(fromOffsets: source, toOffset: destination)
        case .shopping:
            store.moveUserShoppingTags(fromOffsets: source, toOffset: destination)
        }
    }
}
