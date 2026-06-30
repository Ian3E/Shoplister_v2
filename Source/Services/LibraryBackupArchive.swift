import Foundation
import ZIPFoundation

/// ZIP wrapper around `LibraryBackupCodec` plus item JPEGs in `images/`.
enum LibraryBackupArchive {
    static let imagesDirectoryName = "images"

    enum ArchiveError: LocalizedError {
        case invalidZip
        case missingLibraryFile
        case unreadableLibraryFile
        case invalidImageFileName(String)

        var errorDescription: String? {
            switch self {
            case .invalidZip:
                return LocalizedCopy.backupInvalidZipArchive
            case .missingLibraryFile:
                return LocalizedCopy.backupMissingLibraryFile
            case .unreadableLibraryFile:
                return LocalizedCopy.utf8ReadError
            case .invalidImageFileName(let name):
                return LocalizedCopy.backupInvalidImageFileName(name)
            }
        }
    }

    struct ImportPayload {
        let parsed: LibraryBackupCodec.ParsedLibraryBackup
        let imagesDirectoryURL: URL?
    }

    // MARK: - Export

    static func exportZip(
        language: AppContentLanguage,
        catalog: [GroceryItem],
        inventoryTags: [Tag],
        shoppingTags: [Tag],
        recipes: [Recipe]
    ) throws -> URL {
        let staging = FileManager.default.temporaryDirectory
            .appendingPathComponent("shoplister-export-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)

        let libraryText = LibraryBackupCodec.exportDocument(
            language: language,
            catalog: catalog,
            inventoryTags: inventoryTags,
            shoppingTags: shoppingTags,
            recipes: recipes
        )
        let libraryURL = staging.appendingPathComponent(LibraryBackupCodec.libraryFileName)
        try libraryText.write(to: libraryURL, atomically: true, encoding: .utf8)

        let imagesDir = staging.appendingPathComponent(imagesDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        for item in catalog where item.hasImage && ItemImageStore.fileExists(forItemID: item.id) {
            let source = ItemImageStore.fileURL(forItemID: item.id)
            let dest = imagesDir.appendingPathComponent("\(item.id.uuidString).jpg")
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: source, to: dest)
        }

        let suffix = language == .hebrew ? "he" : "en"
        let zipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("shoplister-library-backup-\(suffix).zip")
        if FileManager.default.fileExists(atPath: zipURL.path) {
            try FileManager.default.removeItem(at: zipURL)
        }
        try FileManager.default.zipItem(at: staging, to: zipURL, shouldKeepParent: false)
        try? FileManager.default.removeItem(at: staging)
        return zipURL
    }

    // MARK: - Import

    static func loadImportPayload(from zipURL: URL, expectedLanguage: AppContentLanguage) throws -> ImportPayload {
        let extractRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("shoplister-import-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: extractRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: extractRoot) }

        do {
            try FileManager.default.unzipItem(at: zipURL, to: extractRoot)
        } catch {
            throw ArchiveError.invalidZip
        }

        let libraryURL = extractRoot.appendingPathComponent(LibraryBackupCodec.libraryFileName)
        guard FileManager.default.fileExists(atPath: libraryURL.path) else {
            throw ArchiveError.missingLibraryFile
        }
        let data = try Data(contentsOf: libraryURL)
        guard let text = String(data: data, encoding: .utf8) else {
            throw ArchiveError.unreadableLibraryFile
        }
        let parsed = try LibraryBackupCodec.parseDocument(text, expectedLanguage: expectedLanguage)

        let imagesDir = extractRoot.appendingPathComponent(imagesDirectoryName, isDirectory: true)
        let imagesDirectoryURL: URL?
        if FileManager.default.fileExists(atPath: imagesDir.path) {
            let persistedImages = FileManager.default.temporaryDirectory
                .appendingPathComponent("shoplister-import-images-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: persistedImages, withIntermediateDirectories: true)
            if let names = try? FileManager.default.contentsOfDirectory(atPath: imagesDir.path) {
                for name in names where name.lowercased().hasSuffix(".jpg") {
                    let source = imagesDir.appendingPathComponent(name)
                    let dest = persistedImages.appendingPathComponent(name)
                    if FileManager.default.fileExists(atPath: dest.path) {
                        try FileManager.default.removeItem(at: dest)
                    }
                    try FileManager.default.copyItem(at: source, to: dest)
                }
            }
            imagesDirectoryURL = persistedImages
        } else {
            imagesDirectoryURL = nil
        }

        return ImportPayload(parsed: parsed, imagesDirectoryURL: imagesDirectoryURL)
    }

    static func imageURLsByItemID(in imagesDirectoryURL: URL) throws -> [UUID: URL] {
        var result: [UUID: URL] = [:]
        let names = try FileManager.default.contentsOfDirectory(atPath: imagesDirectoryURL.path)
        for name in names {
            guard name.lowercased().hasSuffix(".jpg") else { continue }
            let stem = (name as NSString).deletingPathExtension
            guard let id = UUID(uuidString: stem) else {
                throw ArchiveError.invalidImageFileName(name)
            }
            result[id] = imagesDirectoryURL.appendingPathComponent(name)
        }
        return result
    }
}
