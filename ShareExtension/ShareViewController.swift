import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Share extension: match shared plain text to the catalog snapshot in the app group, then show review UI in-extension.
final class ShareViewController: UIViewController {
    private static let textTypeIdentifiers = [
        UTType.plainText.identifier,
        UTType.text.identifier,
        UTType.utf8PlainText.identifier,
    ]

    private var shareFlowFinished = false
    private var didBeginShareTextLoad = false
    private var reviewHostingController: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        shareFlowFinished = false
        // Overlap snapshot decode + `loadItem` with the system share-sheet animation (cannot run before the extension is launched).
        ShareImportFlow.beginPrefetchCatalogSnapshot()
        forwardSharedTextThenPresentReview()
    }

    private func forwardSharedTextThenPresentReview() {
        guard !didBeginShareTextLoad else { return }
        didBeginShareTextLoad = true

        guard let context = extensionContext else {
            complete()
            return
        }

        let items = context.inputItems.compactMap { $0 as? NSExtensionItem }
        var collected: [String] = []
        let group = DispatchGroup()

        for item in items {
            for provider in item.attachments ?? [] {
                guard let typeIdentifier = Self.textTypeIdentifiers.first(where: {
                    provider.hasItemConformingToTypeIdentifier($0)
                }) else { continue }
                group.enter()
                provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { value, _ in
                    defer { group.leave() }
                    if let string = value as? String {
                        collected.append(string)
                    } else if let data = value as? Data, let string = String(data: data, encoding: .utf8) {
                        collected.append(string)
                    } else if let url = value as? URL, let string = try? String(contentsOf: url, encoding: .utf8) {
                        collected.append(string)
                    }
                }
            }
        }

        group.notify(queue: .main) {
            let combined = collected.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !combined.isEmpty else {
                self.complete()
                return
            }

            ShareImportFlow.presentReview(from: self, sharedText: combined) {
                self.complete()
            }
        }
    }

    private func complete() {
        guard !shareFlowFinished else { return }
        shareFlowFinished = true
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    /// Embeds the review SwiftUI UI as a full-screen child so we do not stack a second sheet on top of the system share extension surface.
    func attachReviewHosting(_ host: UIHostingController<AnyView>) {
        reviewHostingController?.willMove(toParent: nil)
        reviewHostingController?.view.removeFromSuperview()
        reviewHostingController?.removeFromParent()

        reviewHostingController = host
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
    }

    func detachReviewHostingThenRun(_ completion: @escaping () -> Void) {
        guard let host = reviewHostingController else {
            completion()
            return
        }
        host.willMove(toParent: nil)
        host.view.removeFromSuperview()
        host.removeFromParent()
        reviewHostingController = nil
        completion()
    }
}
