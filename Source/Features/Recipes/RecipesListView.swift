import SwiftUI

struct RecipesListView: View {
    @EnvironmentObject private var store: GroceryStore

    let onAppliedToShopping: () -> Void

    @State private var recipeToApply: Recipe?
    @State private var listEditMode: EditMode = .inactive
    @State private var showsRecipeNameFields = false
    @State private var draftRecipeNames: [UUID: String] = [:]

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
        showsRecipeNameFields = false
        draftRecipeNames = Dictionary(uniqueKeysWithValues: sortedRecipes.map { ($0.id, $0.name) })
        Task { @MainActor in
            await Task.yield()
            guard listEditMode == .inactive else { return }
            withAnimation(.snappy) {
                listEditMode = .active
            }
            try? await Task.sleep(for: .milliseconds(280))
            guard listEditMode == .active else { return }
            showsRecipeNameFields = true
        }
    }

    private func exitRecipeListEditMode() {
        showsRecipeNameFields = false
        withAnimation(.snappy) {
            listEditMode = .inactive
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
                            if isEditing, showsRecipeNameFields {
                                TextField(
                                    LocalizedCopy.recipeName,
                                    text: recipeNameBinding(for: recipe)
                                )
                                .textFieldStyle(.plain)
                                .foregroundStyle(.primary)
                            } else {
                                Text(recipe.name)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        guard !isEditing else { return }
                                        recipeToApply = recipe
                                    }
                            }
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
            ToolbarItem(placement: .topBarLeading) {
                Group {
                    if isEditing {
                        RecipesListEditDoneToolbarButton {
                            exitRecipeListEditMode()
                        }
                    } else {
                        Button(LocalizedCopy.edit) {
                            enterRecipeListEditMode()
                        }
                    }
                }
                .disabled(sortedRecipes.isEmpty)
            }
        }
        .onChange(of: listEditMode) { _, newMode in
            guard newMode == .inactive else { return }
            showsRecipeNameFields = false
            commitRecipeNameDrafts()
        }
        .onDisappear {
            if isEditing {
                commitRecipeNameDrafts()
            }
            showsRecipeNameFields = false
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
