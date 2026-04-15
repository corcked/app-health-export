import Foundation
import SwiftUI

enum DateRangeMode: String, CaseIterable, Identifiable, Codable {
    case lastDay = "1d"
    case last7Days = "7d"
    case last30Days = "30d"
    case last90Days = "90d"
    case lastYear = "1y"
    case allTime = "all"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .lastDay: "date_range_1d"
        case .last7Days: "date_range_7d"
        case .last30Days: "date_range_30d"
        case .last90Days: "date_range_90d"
        case .lastYear: "date_range_1y"
        case .allTime: "date_range_all"
        case .custom: "date_range_custom"
        }
    }
}

struct DateRange {
    let startDate: Date
    let endDate: Date

    static func from(mode: DateRangeMode, customStart: Date? = nil, customEnd: Date? = nil) -> DateRange {
        let now = Date()
        let calendar = Calendar.current

        switch mode {
        case .lastDay:
            return DateRange(
                startDate: calendar.date(byAdding: .day, value: -1, to: now)!,
                endDate: now
            )
        case .last7Days:
            return DateRange(
                startDate: calendar.date(byAdding: .day, value: -7, to: now)!,
                endDate: now
            )
        case .last30Days:
            return DateRange(
                startDate: calendar.date(byAdding: .day, value: -30, to: now)!,
                endDate: now
            )
        case .last90Days:
            return DateRange(
                startDate: calendar.date(byAdding: .day, value: -90, to: now)!,
                endDate: now
            )
        case .lastYear:
            return DateRange(
                startDate: calendar.date(byAdding: .year, value: -1, to: now)!,
                endDate: now
            )
        case .allTime:
            return DateRange(
                startDate: calendar.date(from: DateComponents(year: 2014, month: 1, day: 1))!,
                endDate: now
            )
        case .custom:
            return DateRange(
                startDate: customStart ?? calendar.date(byAdding: .day, value: -30, to: now)!,
                endDate: customEnd ?? now
            )
        }
    }
}
