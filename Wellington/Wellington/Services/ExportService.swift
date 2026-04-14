import Foundation
import Observation
import os

@Observable
final class ExportService {
    let healthKitService: HealthKitService
    let fileStorageService: FileStorageService

    private let logger = Logger(subsystem: "com.wellington", category: "Export")

    var isExporting = false
    var exportProgress: Double = 0.0
    var currentCategoryIndex: Int = 0
    var totalCategories: Int = 0

    init(healthKitService: HealthKitService, fileStorageService: FileStorageService) {
        self.healthKitService = healthKitService
        self.fileStorageService = fileStorageService
    }

    func export(
        categories: [HealthDataCategory],
        format: ExportFormat,
        dateRange: DateRange
    ) async throws -> ExportResult {
        guard !categories.isEmpty else {
            throw WellingtonError.noCategoriesSelected
        }

        isExporting = true
        exportProgress = 0.0
        currentCategoryIndex = 0
        totalCategories = categories.count
        defer { isExporting = false }

        // 1. Fetch records from HealthKit
        var allRecords: [HealthDataCategory: [HealthRecord]] = [:]

        for (index, category) in categories.enumerated() {
            currentCategoryIndex = index + 1
            exportProgress = Double(index) / Double(categories.count)

            do {
                let records = try await healthKitService.fetchRecords(
                    for: category,
                    from: dateRange.startDate,
                    to: dateRange.endDate
                )
                allRecords[category] = records
                logger.info("Fetched \(records.count) records for \(category.rawValue)")
            } catch {
                logger.error("Failed to fetch \(category.rawValue): \(error.localizedDescription)")
                // Continue with other categories instead of failing entirely
            }
        }

        exportProgress = 0.8

        // 2. Flatten and sort records
        let flatRecords = allRecords.values
            .flatMap { $0 }
            .sorted { $0.startDate < $1.startDate }

        guard !flatRecords.isEmpty else {
            throw WellingtonError.noDataForSelectedCategories
        }

        // 3. Format using the appropriate formatter
        let formatter = makeFormatter(for: format)
        let data = formatter.format(records: flatRecords, categories: categories)

        exportProgress = 0.9

        // 4. Write to file
        let filename = fileStorageService.generateFilename(format: format, dateRange: dateRange)
        let fileURL: URL
        do {
            fileURL = try fileStorageService.writeToTemporaryFile(data: data, filename: filename)
        } catch {
            throw WellingtonError.fileWriteFailed(underlying: error)
        }

        // 5. Optionally copy to iCloud
        if UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.autoSaveToiCloud) {
            do {
                try fileStorageService.copyToiCloud(fileURL: fileURL)
            } catch {
                logger.warning("iCloud copy failed: \(error.localizedDescription)")
                // Don't fail the whole export if iCloud copy fails
            }
        }

        exportProgress = 1.0

        let result = ExportResult(
            fileURL: fileURL,
            format: format,
            recordCount: flatRecords.count,
            categories: categories,
            dateRange: dateRange
        )

        logger.info("Export completed: \(flatRecords.count) records in \(format.rawValue)")
        return result
    }

    private func makeFormatter(for format: ExportFormat) -> FormatService {
        switch format {
        case .csv: CSVFormatService()
        case .json: JSONFormatService()
        case .markdown: MarkdownFormatService()
        }
    }
}
