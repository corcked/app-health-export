import Foundation
import SwiftUI

enum ExportSchedule: String, CaseIterable, Identifiable, Codable {
    case daily
    case weekly

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .daily: "schedule_daily"
        case .weekly: "schedule_weekly"
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .daily: .day
        case .weekly: .weekOfYear
        }
    }

    var intervalDays: Int {
        switch self {
        case .daily: 1
        case .weekly: 7
        }
    }
}
