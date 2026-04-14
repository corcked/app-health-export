import Foundation

enum WellingtonError: LocalizedError {
    case healthKitNotAvailable
    case healthKitAuthorizationDenied
    case noDataForSelectedCategories
    case noCategoriesSelected
    case exportFailed(underlying: Error)
    case iCloudUnavailable
    case fileWriteFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return String(localized: "error_healthkit_not_available")
        case .healthKitAuthorizationDenied:
            return String(localized: "error_healthkit_authorization_denied")
        case .noDataForSelectedCategories:
            return String(localized: "error_no_data")
        case .noCategoriesSelected:
            return String(localized: "error_no_categories")
        case .exportFailed(let underlying):
            return String(localized: "error_export_failed \(underlying.localizedDescription)")
        case .iCloudUnavailable:
            return String(localized: "error_icloud_unavailable")
        case .fileWriteFailed(let underlying):
            return String(localized: "error_file_write_failed \(underlying.localizedDescription)")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .healthKitNotAvailable:
            return String(localized: "error_recovery_healthkit_not_available")
        case .healthKitAuthorizationDenied:
            return String(localized: "error_recovery_healthkit_denied")
        case .noDataForSelectedCategories:
            return String(localized: "error_recovery_no_data")
        case .noCategoriesSelected:
            return String(localized: "error_recovery_no_categories")
        case .exportFailed:
            return String(localized: "error_recovery_export_failed")
        case .iCloudUnavailable:
            return String(localized: "error_recovery_icloud")
        case .fileWriteFailed:
            return String(localized: "error_recovery_file_write")
        }
    }
}
