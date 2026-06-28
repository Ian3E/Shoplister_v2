import AppIntents

/// Shortcuts automation (no Siri phrases): import newline-separated text into the shopping list.
struct ImportTextToShoppingListIntent: AppIntent {
    static var title: LocalizedStringResource = "Import Text to Shopping List"
    static var description = IntentDescription(
        "Adds library items to the shopping list when each line exactly matches an item name."
    )

    @Parameter(title: "Text")
    var text: String

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let added = await MainActor.run {
            ShareTextLineImport.enqueueMatchingLines(text)
        }
        if added > 0 {
            return .result(dialog: IntentDialog(stringLiteral: LocalizedCopy.addedItems(added)))
        }
        return .result(dialog: IntentDialog(stringLiteral: LocalizedCopy.noMatchingItemsFound))
    }
}
