import Foundation

struct ExportResult {
    let fileURL: URL
    let format: ExportFormat
    let recordCount: Int
    let exportDate: Date
    let categories: [HealthDataCategory]
    let dateRange: DateRange

    init(
        fileURL: URL,
        format: ExportFormat,
        recordCount: Int,
        categories: [HealthDataCategory],
        dateRange: DateRange,
        exportDate: Date = Date()
    ) {
        self.fileURL = fileURL
        self.format = format
        self.recordCount = recordCount
        self.categories = categories
        self.dateRange = dateRange
        self.exportDate = exportDate
    }
}
