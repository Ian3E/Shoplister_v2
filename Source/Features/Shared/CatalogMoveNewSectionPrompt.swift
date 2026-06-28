import UIKit

/// Shared “New section” row and name prompt for move-to-section UIKit menus.
@MainActor
enum CatalogMoveNewSectionPrompt {
    static let menuDismissDelayMs: UInt64 = 220

    static func sectionMoveElements(
        tags: [Tag],
        language: AppContentLanguage,
        onSelectTag: @escaping (UUID) -> Void,
        onNewSection: @escaping () -> Void
    ) -> [UIMenuElement] {
        var children: [UIMenuElement] = tags.map { tag in
            let tagID = tag.id
            let title = tag.displayTitle(appContentLanguage: language)
            return UIAction(title: title) { _ in
                onSelectTag(tagID)
            }
        }

        let newSection = UIAction(
            title: LocalizedCopy.newSection,
            image: UIImage(systemName: "folder.badge.plus")
        ) { _ in
            onNewSection()
        }
        children.append(
            UIMenu(title: "", options: .displayInline, children: [newSection])
        )
        return children
    }

    static func presentAfterMenuDismiss(
        from view: UIView,
        onCreate: @escaping (String) -> Void
    ) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(menuDismissDelayMs))
            present(from: view, onCreate: onCreate)
        }
    }

    static func present(
        from view: UIView,
        onCreate: @escaping (String) -> Void
    ) {
        guard let presenter = view.nearestViewController() else { return }

        let alert = UIAlertController(title: LocalizedCopy.newSection, message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = LocalizedCopy.sectionName
            field.autocapitalizationType = .words
            field.autocorrectionType = .default
        }

        let createAction = UIAlertAction(title: LocalizedCopy.create, style: .default) { _ in
            let raw = alert.textFields?.first?.text ?? ""
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            onCreate(trimmed)
        }
        alert.addAction(createAction)
        alert.addAction(UIAlertAction(title: LocalizedCopy.cancel, style: .cancel))
        alert.preferredAction = createAction

        presenter.present(alert, animated: true)
    }
}

private extension UIView {
    func nearestViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }
}
