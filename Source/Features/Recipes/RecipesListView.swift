import SwiftUI

struct RecipesListView: View {
    @EnvironmentObject private var store: GroceryStore
    @Environment(\.dismiss) private var dismiss

    let onAppliedToShopping: () -> Void

    @State private var recipeToApply: Recipe?
    @State private var listEditMode: EditMode = .inactive
    /// Drives Edit ↔ checkmark toolbar morph separately from list `EditMode`.
    /// In a sheet, animating both together lets list chrome win and the nav-bar item swap doesn't morph.
    @State private var showsEditToolbarChrome = false
    @State private var showsRecipeNameFields = false
    @State private var draftRecipeNames: [UUID: String] = [:]
    @State private var editModeTask: Task<Void, Never>?

    private var sortedRecipes: [Recipe] {
        store.recipes.sorted {
            if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var isEditing: Bool {
        listEditMode == .active
    }

    var body: some View {
        listContent
            .environment(\.editMode, $listEditMode)
            .navigationTitle(LocalizedCopy.savedLists)
            .navigationBarTitleDisplayMode(.inline)
    }

    private func commitRecipeNameDrafts() {
        for recipe in store.recipes {
            guard let draft = draftRecipeNames[recipe.id] else { continue }
            let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed != recipe.name else { continue }
            var updated = recipe
            updated.name = trimmed
            store.updateRecipe(updated)
        }
        draftRecipeNames = [:]
    }

    private func enterRecipeListEditMode() {
        editModeTask?.cancel()
        showsRecipeNameFields = false
        draftRecipeNames = Dictionary(uniqueKeysWithValues: sortedRecipes.map { ($0.id, $0.name) })
        editModeTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled, listEditMode == .inactive else { return }
            // Toolbar morph first (sheet nav bar won't morph if List EditMode animates in the same turn).
            withAnimation(.snappy) {
                showsEditToolbarChrome = true
            }
            await Task.yield()
            guard !Task.isCancelled else { return }
            withAnimation(.snappy) {
                listEditMode = .active
            }
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled, listEditMode == .active else { return }
            showsRecipeNameFields = true
        }
    }

    private func exitRecipeListEditMode() {
        editModeTask?.cancel()
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            showsRecipeNameFields = false
        }
        editModeTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled, listEditMode == .active || showsEditToolbarChrome else { return }
            withAnimation(.snappy) {
                showsEditToolbarChrome = false
            }
            await Task.yield()
            guard !Task.isCancelled else { return }
            withAnimation(.snappy) {
                listEditMode = .inactive
            }
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled, listEditMode == .inactive else { return }
            commitRecipeNameDrafts()
        }
    }

    private var listContent: some View {
        Group {
            if sortedRecipes.isEmpty {
                savedListsEmptyState
            } else {
                List {
                    Section {
                        ForEach(sortedRecipes) { recipe in
                            recipeRow(for: recipe)
                        }
                        .onMove(perform: store.moveRecipes)
                        .onDelete(perform: deleteRecipes)
                    }
                }
                .listStyle(.insetGrouped)
                .catalogListLayoutDirection()
            }
        }
        .toolbar {
            ToolbarItem(id: "recipesListEditDone", placement: .topBarLeading) {
                if showsEditToolbarChrome {
                    RecipesListEditDoneToolbarButton {
                        exitRecipeListEditMode()
                    }
                    .disabled(sortedRecipes.isEmpty)
                } else {
                    RecipesListEditToolbarButton {
                        enterRecipeListEditMode()
                    }
                    .disabled(sortedRecipes.isEmpty)
                }
            }
            // Hide dismiss while editing so the bar performs a multi-item transition (like Home).
            if !showsEditToolbarChrome {
                ToolbarItem(id: "recipesListDismiss", placement: .topBarTrailing) {
                    Button(LocalizedCopy.done) {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
        .onChange(of: listEditMode) { _, newMode in
            guard newMode == .inactive else { return }
            showsRecipeNameFields = false
            if showsEditToolbarChrome {
                showsEditToolbarChrome = false
            }
        }
        .onDisappear {
            editModeTask?.cancel()
            if isEditing || !draftRecipeNames.isEmpty {
                commitRecipeNameDrafts()
            }
            showsRecipeNameFields = false
            showsEditToolbarChrome = false
            listEditMode = .inactive
        }
        .sheet(item: $recipeToApply) { recipe in
            NavigationStack {
                RecipeApplySheet(
                    recipe: recipe,
                    onApplied: {
                        recipeToApply = nil
                        onAppliedToShopping()
                    },
                    onCancel: {
                        recipeToApply = nil
                    }
                )
            }
            .environmentObject(store)
        }
    }

    @ViewBuilder
    private func recipeRow(for recipe: Recipe) -> some View {
        let itemCountText = LocalizedCopy.itemCount(recipe.lines.count)
        // Keep the same `if isEditing` branch shape so List edit-mode chrome can animate.
        Group {
            if isEditing, showsRecipeNameFields {
                HStack(spacing: 12) {
                    TextField(
                        LocalizedCopy.recipeName,
                        text: recipeNameBinding(for: recipe)
                    )
                    .textFieldStyle(.plain)
                    .foregroundStyle(.primary)

                    Text(itemCountText)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(recipe.name), \(itemCountText)")
            } else {
                HStack(spacing: 12) {
                    Text(recipe.name)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(itemCountText)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isEditing else { return }
                    recipeToApply = recipe
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(recipe.name), \(itemCountText)")
                .accessibilityAddTraits(.isButton)
            }
        }
        // Edit-mode delete/reorder insets otherwise clip separators to the count label (esp. RTL).
        .catalogListRowSeparatorFullWidth(true)
    }

    private func recipeNameBinding(for recipe: Recipe) -> Binding<String> {
        Binding(
            get: { draftRecipeNames[recipe.id] ?? recipe.name },
            set: { draftRecipeNames[recipe.id] = $0 }
        )
    }

    private func deleteRecipes(at offsets: IndexSet) {
        for index in offsets {
            store.deleteRecipe(id: sortedRecipes[index].id)
        }
    }

    private var savedListsEmptyState: some View {
        Text(LocalizedCopy.recipesEmptyFooter)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.layoutDirection, AppSystemLocale.interfaceLayoutDirection)
    }
}

/// Enters recipe list edit mode — titled toolbar button (matches Home Edit).
private struct RecipesListEditToolbarButton: View {
    let action: () -> Void

    var body: some View {
        Button(LocalizedCopy.edit, action: action)
            .font(.body.weight(.semibold))
            .accessibilityLabel(LocalizedCopy.edit)
    }
}

/// Exits recipe list edit mode — checkmark glass circle so it doesn't duplicate the sheet's trailing Done.
private struct RecipesListEditDoneToolbarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Color.clear
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
            }
            .frame(width: 36, height: 36)
            .contentShape(Circle())
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .frame(width: 36, height: 36)
        .clipShape(Circle())
        .contentShape(Circle())
        .appThemeTint()
        .appThemeIdentity()
        .accessibilityLabel(LocalizedCopy.doneEditing)
    }
}
