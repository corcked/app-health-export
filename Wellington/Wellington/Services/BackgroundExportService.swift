import Foundation
import BackgroundTasks
import Observation
import os

@Observable
final class BackgroundExportService {
    static let shared = BackgroundExportService()

    private let logger = Logger(subsystem: "com.wellington", category: "BackgroundExport")

    var lastExportDate: Date? {
        get {
            UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.lastBackgroundExportDate) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppConstants.UserDefaultsKeys.lastBackgroundExportDate)
        }
    }

    func scheduleBackgroundExport() {
        let scheduleRaw = UserDefaults.standard.string(
            forKey: AppConstants.UserDefaultsKeys.backgroundExportSchedule
        ) ?? ExportSchedule.daily.rawValue

        let schedule = ExportSchedule(rawValue: scheduleRaw) ?? .daily

        let request = BGProcessingTaskRequest(
            identifier: AppConstants.backgroundExportTaskIdentifier
        )
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Calendar.current.date(
            byAdding: .day,
            value: schedule.intervalDays,
            to: Date()
        )

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled background export: \(schedule.rawValue)")
        } catch {
            logger.error("Failed to schedule background export: \(error.localizedDescription)")
        }
    }

    func cancelBackgroundExport() {
        BGTaskScheduler.shared.cancel(
            taskRequestWithIdentifier: AppConstants.backgroundExportTaskIdentifier
        )
        logger.info("Cancelled background export")
    }

    func handleBackgroundExport(task: BGProcessingTask) async {
        let exportTask = Task {
            await performExport()
        }

        task.expirationHandler = {
            exportTask.cancel()
        }

        let success = await exportTask.value
        task.setTaskCompleted(success: success)

        // Reschedule if still enabled
        if UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.backgroundExportEnabled) {
            scheduleBackgroundExport()
        }
    }

    @discardableResult
    func performExport() async -> Bool {
        logger.info("Starting background export")

        let healthKitService = HealthKitService()
        let fileStorageService = FileStorageService()
        let exportService = ExportService(
            healthKitService: healthKitService,
            fileStorageService: fileStorageService
        )

        // Load saved preferences
        let categoriesRaw = UserDefaults.standard.stringArray(
            forKey: AppConstants.UserDefaultsKeys.selectedCategories
        ) ?? []

        let categories = categoriesRaw.compactMap { HealthDataCategory(rawValue: $0) }
        guard !categories.isEmpty else {
            logger.warning("No categories selected for background export")
            return false
        }

        let formatRaw = UserDefaults.standard.string(
            forKey: AppConstants.UserDefaultsKeys.exportFormat
        ) ?? ExportFormat.csv.rawValue

        let format = ExportFormat(rawValue: formatRaw) ?? .csv

        let dateRangeModeRaw = UserDefaults.standard.string(
            forKey: AppConstants.UserDefaultsKeys.exportDateRangeMode
        ) ?? DateRangeMode.last7Days.rawValue

        let dateRangeMode = DateRangeMode(rawValue: dateRangeModeRaw) ?? .last7Days
        let dateRange = DateRange.from(mode: dateRangeMode)

        do {
            let result = try await exportService.export(
                categories: categories,
                format: format,
                dateRange: dateRange
            )
            lastExportDate = Date()
            logger.info("Background export completed: \(result.recordCount) records")
            return true
        } catch {
            logger.error("Background export failed: \(error.localizedDescription)")
            return false
        }
    }
}
