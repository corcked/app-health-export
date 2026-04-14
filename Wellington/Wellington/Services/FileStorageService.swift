import Foundation
import os

final class FileStorageService {
    private let logger = Logger(subsystem: "com.wellington", category: "FileStorage")

    private static let bookmarkKey = "savedExportFolderBookmark"

    func writeToTemporaryFile(data: Data, filename: String) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
        try data.write(to: tempURL)
        logger.info("Wrote \(data.count) bytes to \(tempURL.lastPathComponent)")
        return tempURL
    }

    // MARK: - Save to chosen folder (security-scoped bookmark)

    func saveExportFolderBookmark(for url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw WellingtonError.iCloudUnavailable
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let bookmarkData = try url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmarkData, forKey: Self.bookmarkKey)
        logger.info("Saved export folder bookmark: \(url.lastPathComponent)")
    }

    func resolveExportFolderBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarkKey) else {
            return nil
        }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }
        if isStale {
            // Re-save bookmark if stale
            try? saveExportFolderBookmark(for: url)
        }
        return url
    }

    var savedFolderName: String? {
        resolveExportFolderBookmark()?.lastPathComponent
    }

    func clearExportFolderBookmark() {
        UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
    }

    func copyToChosenFolder(fileURL: URL) throws {
        guard let folderURL = resolveExportFolderBookmark() else {
            throw WellingtonError.iCloudUnavailable
        }

        guard folderURL.startAccessingSecurityScopedResource() else {
            throw WellingtonError.iCloudUnavailable
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let destinationURL = folderURL.appendingPathComponent(fileURL.lastPathComponent)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: fileURL, to: destinationURL)
        logger.info("Copied to folder: \(destinationURL.lastPathComponent)")
    }

    // MARK: - Legacy iCloud container fallback

    func copyToiCloud(fileURL: URL) async throws {
        // Prefer user-chosen folder
        if resolveExportFolderBookmark() != nil {
            try copyToChosenFolder(fileURL: fileURL)
            return
        }

        let containerURL: URL? = await Task.detached {
            FileManager.default.url(
                forUbiquityContainerIdentifier: AppConstants.iCloud.containerIdentifier
            )
        }.value

        guard let containerURL else {
            throw WellingtonError.iCloudUnavailable
        }

        let documentsURL = containerURL
            .appendingPathComponent("Documents")
            .appendingPathComponent(AppConstants.iCloud.exportFolderName)

        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            try FileManager.default.createDirectory(
                at: documentsURL,
                withIntermediateDirectories: true
            )
        }

        let destinationURL = documentsURL.appendingPathComponent(fileURL.lastPathComponent)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: fileURL, to: destinationURL)
        logger.info("Copied to iCloud: \(destinationURL.lastPathComponent)")
    }

    var isiCloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func generateFilename(format: ExportFormat, dateRange: DateRange) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let start = dateFormatter.string(from: dateRange.startDate)
        let end = dateFormatter.string(from: dateRange.endDate)
        return "wellington-export_\(start)_\(end).\(format.fileExtension)"
    }
}
