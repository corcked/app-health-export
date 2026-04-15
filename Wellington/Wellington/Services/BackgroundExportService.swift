import Foundation
import BackgroundTasks
import UserNotifications
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

    // MARK: - Notifications

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(recordCount: Int, success: Bool, errorMessage: String? = nil) {
        let content = UNMutableNotificationContent()
        if success {
            content.title = "Export Complete"
            content.body = "\(recordCount) records exported successfully."
            content.sound = .default
        } else {
            content.title = "Export Failed"
            content.body = errorMessage ?? "An error occurred during background export."
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: "wellington.export.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Scheduling

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
        request.earliestBeginDate = nextScheduledDate(schedule: schedule)

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled background export: \(schedule.rawValue)")
        } catch {
            logger.error("Failed to schedule background export: \(error.localizedDescription)")
        }
    }

    private func nextScheduledDate(schedule: ExportSchedule) -> Date {
        let calendar = Calendar.current
        let preferredHour = UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.preferredExportHour) as? Int ?? 6

        var nextDate = calendar.date(
            byAdding: .day,
            value: schedule.intervalDays,
            to: Date()
        )!

        // Set preferred hour
        var components = calendar.dateComponents([.year, .month, .day], from: nextDate)
        components.hour = preferredHour
        components.minute = 0

        return calendar.date(from: components) ?? nextDate
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
            let log = ExportLog(recordCount: 0, format: "—", success: false, errorMessage: "No categories selected")
            ExportLog.save(log)
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

            // Save to chosen folder or iCloud Drive
            try await fileStorageService.copyToiCloud(fileURL: result.fileURL)

            lastExportDate = Date()
            logger.info("Background export completed: \(result.recordCount) records, saved to iCloud")

            // Log & notify
            let log = ExportLog(recordCount: result.recordCount, format: format.rawValue, success: true)
            ExportLog.save(log)
            sendNotification(recordCount: result.recordCount, success: true)

            return true
        } catch {
            logger.error("Background export failed: \(error.localizedDescription)")

            let log = ExportLog(recordCount: 0, format: format.rawValue, success: false, errorMessage: error.localizedDescription)
            ExportLog.save(log)
            sendNotification(recordCount: 0, success: false, errorMessage: error.localizedDescription)

            return false
        }
    }
}
