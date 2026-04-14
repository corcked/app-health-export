import Foundation
import os

final class FileStorageService {
    private let logger = Logger(subsystem: "com.wellington", category: "FileStorage")

    func writeToTemporaryFile(data: Data, filename: String) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
        try data.write(to: tempURL)
        logger.info("Wrote \(data.count) bytes to \(tempURL.lastPathComponent)")
        return tempURL
    }

    func copyToiCloud(fileURL: URL) async throws {
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
