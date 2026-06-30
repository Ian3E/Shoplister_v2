import Foundation
import UIKit

enum ItemImageStore {
    private static let subdirectory = "ItemImages"

    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent(subdirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }

    static func fileURL(forItemID id: UUID) -> URL {
        directoryURL.appendingPathComponent("\(id.uuidString).jpg")
    }

    static func fileExists(forItemID id: UUID) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(forItemID: id).path)
    }

    static func loadImage(forItemID id: UUID) -> UIImage? {
        let path = fileURL(forItemID: id).path
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        return UIImage(contentsOfFile: path)
    }

    static func save(_ image: UIImage, forItemID id: UUID, maxSide: CGFloat = 1200) throws {
        let resized = image.resizedToFit(maxSide: maxSide)
        guard let data = resized.jpegData(compressionQuality: 0.82) else { return }
        try data.write(to: fileURL(forItemID: id), options: .atomic)
    }

    static func delete(forItemID id: UUID) {
        let url = fileURL(forItemID: id)
        try? FileManager.default.removeItem(at: url)
    }

    static func importImage(from sourceURL: URL, forItemID id: UUID) throws {
        let dest = fileURL(forItemID: id)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: sourceURL, to: dest)
    }

    /// Removes every stored image file (used when resetting the library).
    static func deleteAllStoredImages() {
        let dir = directoryURL
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }
        for name in names {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(name))
        }
    }
}

private extension UIImage {
    func resizedToFit(maxSide: CGFloat) -> UIImage {
        let w = size.width
        let h = size.height
        guard w > 0, h > 0 else { return self }
        let scale = min(1, min(maxSide / w, maxSide / h))
        guard scale < 1 else { return self }
        let newSize = CGSize(width: floor(w * scale), height: floor(h * scale))
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
