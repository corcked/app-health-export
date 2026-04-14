import Foundation

enum AppConstants {
    static let backgroundExportTaskIdentifier = "com.wellington.export.background"

    enum StoreKit {
        static let smallTipID = "wellington.tip.small"
        static let mediumTipID = "wellington.tip.medium"
        static let largeTipID = "wellington.tip.large"

        static let allProductIDs: [String] = [
            smallTipID,
            mediumTipID,
            largeTipID
        ]
    }

    enum iCloud {
        static let containerIdentifier: String? = nil // Uses default container
        static let exportFolderName = "Wellington Exports"
    }

    enum UserDefaultsKeys {
        static let selectedCategories = "selectedCategories"
        static let exportFormat = "exportFormat"
        static let autoSaveToiCloud = "autoSaveToiCloud"
        static let backgroundExportEnabled = "backgroundExportEnabled"
        static let backgroundExportSchedule = "backgroundExportSchedule"
        static let exportDateRangeMode = "exportDateRangeMode"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastBackgroundExportDate = "lastBackgroundExportDate"
    }
}
