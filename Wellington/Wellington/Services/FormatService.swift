import Foundation
import SwiftUI

// MARK: - Protocol

protocol FormatService {
    func format(records: [HealthRecord], categories: [HealthDataCategory]) -> Data
    var fileExtension: String { get }
}

// MARK: - CSV Format Service

struct CSVFormatService: FormatService {
    var fileExtension: String { "csv" }

    private let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    func format(records: [HealthRecord], categories: [HealthDataCategory]) -> Data {
        var lines: [String] = []

        let header = "date,end_date,category,value,unit,source,workout_type,duration_seconds,distance,energy_burned,sleep_stage"
        lines.append(header)

        for record in records {
            let fields: [String] = [
                iso8601Formatter.string(from: record.startDate),
                iso8601Formatter.string(from: record.endDate),
                escapeCSV(record.category),
                String(record.value),
                escapeCSV(record.unit),
                escapeCSV(record.sourceName),
                escapeCSV(record.workoutType ?? ""),
                record.duration.map { String($0) } ?? "",
                record.totalDistance.map { String($0) } ?? "",
                record.totalEnergyBurned.map { String($0) } ?? "",
                escapeCSV(record.sleepStage ?? "")
            ]
            lines.append(fields.joined(separator: ","))
        }

        let csv = lines.joined(separator: "\n") + "\n"
        return Data(csv.utf8)
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}

// MARK: - JSON Format Service

struct JSONFormatService: FormatService {
    var fileExtension: String { "json" }

    struct ExportPayload: Codable {
        let exportDate: Date
        let dateRangeStart: Date
        let dateRangeEnd: Date
        let recordCount: Int
        let records: [HealthRecord]
    }

    func format(records: [HealthRecord], categories: [HealthDataCategory]) -> Data {
        let sortedRecords = records.sorted { $0.startDate < $1.startDate }

        let dateRangeStart = sortedRecords.first?.startDate ?? Date()
        let dateRangeEnd = sortedRecords.last?.endDate ?? Date()

        let payload = ExportPayload(
            exportDate: Date(),
            dateRangeStart: dateRangeStart,
            dateRangeEnd: dateRangeEnd,
            recordCount: records.count,
            records: sortedRecords
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        do {
            return try encoder.encode(payload)
        } catch {
            let fallback = "{\"error\": \"Failed to encode records: \(error.localizedDescription)\"}"
            return Data(fallback.utf8)
        }
    }
}

// MARK: - Markdown Format Service

struct MarkdownFormatService: FormatService {
    var fileExtension: String { "md" }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    func format(records: [HealthRecord], categories: [HealthDataCategory]) -> Data {
        let sortedRecords = records.sorted { $0.startDate < $1.startDate }

        let rangeStart = sortedRecords.first?.startDate ?? Date()
        let rangeEnd = sortedRecords.last?.endDate ?? Date()

        var lines: [String] = []

        // YAML frontmatter
        lines.append("---")
        lines.append("date: \(dateFormatter.string(from: Date()))")
        lines.append("type: health-export")
        lines.append("tags: [health, export, wellington]")
        lines.append("---")
        lines.append("")

        // Title
        let startStr = dateFormatter.string(from: rangeStart)
        let endStr = dateFormatter.string(from: rangeEnd)
        lines.append("# Health Export \u{2014} \(startStr) to \(endStr)")
        lines.append("")

        // Build a lookup from category rawValue to HealthDataCategory
        let categoryLookup = Dictionary(uniqueKeysWithValues: categories.map { ($0.rawValue, $0) })

        // Group records by category, preserving the order from the categories parameter
        let recordsByCategory = Dictionary(grouping: sortedRecords) { $0.category }

        for category in categories {
            guard let categoryRecords = recordsByCategory[category.rawValue], !categoryRecords.isEmpty else {
                continue
            }

            let sectionTitle = displayNameString(for: category)
            lines.append("## \(sectionTitle)")
            lines.append("")

            if category == .workouts {
                lines.append(formatWorkoutsTable(categoryRecords))
            } else if category == .sleepAnalysis {
                lines.append(formatSleepTable(categoryRecords))
            } else {
                lines.append(formatRegularTable(categoryRecords, category: category))
            }

            lines.append("")
        }

        // Handle any records whose category isn't in the provided categories list
        let knownCategoryRawValues = Set(categories.map { $0.rawValue })
        let unknownCategories = Set(sortedRecords.map { $0.category }).subtracting(knownCategoryRawValues)

        for unknownCategory in unknownCategories.sorted() {
            guard let categoryRecords = recordsByCategory[unknownCategory], !categoryRecords.isEmpty else {
                continue
            }

            let matchedCategory = categoryLookup[unknownCategory]
            let sectionTitle = matchedCategory.map { displayNameString(for: $0) } ?? unknownCategory
            lines.append("## \(sectionTitle)")
            lines.append("")

            if let matched = matchedCategory {
                if matched == .workouts {
                    lines.append(formatWorkoutsTable(categoryRecords))
                } else if matched == .sleepAnalysis {
                    lines.append(formatSleepTable(categoryRecords))
                } else {
                    lines.append(formatRegularTable(categoryRecords, category: matched))
                }
            } else {
                lines.append(formatGenericTable(categoryRecords))
            }

            lines.append("")
        }

        let markdown = lines.joined(separator: "\n")
        return Data(markdown.utf8)
    }

    // MARK: - Table Formatters

    private func formatWorkoutsTable(_ records: [HealthRecord]) -> String {
        var rows: [String] = []
        rows.append("| Date | Type | Duration | Distance | Calories |")
        rows.append("| --- | --- | --- | --- | --- |")

        for record in records {
            let date = dateTimeFormatter.string(from: record.startDate)
            let type = record.workoutType ?? "Unknown"
            let duration = record.duration.map { formatDuration($0) } ?? "-"
            let distance = record.totalDistance.map { formatNumber($0) + " m" } ?? "-"
            let calories = record.totalEnergyBurned.map { formatNumber($0) + " kcal" } ?? "-"
            rows.append("| \(date) | \(type) | \(duration) | \(distance) | \(calories) |")
        }

        return rows.joined(separator: "\n")
    }

    private func formatSleepTable(_ records: [HealthRecord]) -> String {
        var rows: [String] = []
        rows.append("| Date | Stage | Duration |")
        rows.append("| --- | --- | --- |")

        for record in records {
            let date = dateTimeFormatter.string(from: record.startDate)
            let stage = record.sleepStage ?? "Unknown"
            let duration = formatDuration(record.endDate.timeIntervalSince(record.startDate))
            rows.append("| \(date) | \(stage) | \(duration) |")
        }

        return rows.joined(separator: "\n")
    }

    private func formatRegularTable(_ records: [HealthRecord], category: HealthDataCategory) -> String {
        let unit = category.unitDisplayName
        let unitSuffix = unit.isEmpty ? "" : " \(unit)"

        var rows: [String] = []
        rows.append("| Date | Value\(unitSuffix.isEmpty ? "" : " (\(unit))") | Source |")
        rows.append("| --- | --- | --- |")

        for record in records {
            let date = dateTimeFormatter.string(from: record.startDate)
            let value = formatNumber(record.value)
            let source = record.sourceName
            rows.append("| \(date) | \(value)\(unitSuffix) | \(source) |")
        }

        return rows.joined(separator: "\n")
    }

    private func formatGenericTable(_ records: [HealthRecord]) -> String {
        var rows: [String] = []
        rows.append("| Date | Value | Unit | Source |")
        rows.append("| --- | --- | --- | --- |")

        for record in records {
            let date = dateTimeFormatter.string(from: record.startDate)
            let value = formatNumber(record.value)
            rows.append("| \(date) | \(value) | \(record.unit) | \(record.sourceName) |")
        }

        return rows.joined(separator: "\n")
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func formatNumber(_ value: Double) -> String {
        numberFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    private func displayNameString(for category: HealthDataCategory) -> String {
        switch category {
        case .steps: return "Steps"
        case .activeEnergy: return "Active Energy"
        case .basalEnergy: return "Resting Energy"
        case .distanceWalking: return "Distance"
        case .flightsClimbed: return "Flights Climbed"
        case .heartRate: return "Heart Rate"
        case .restingHeartRate: return "Resting Heart Rate"
        case .heartRateVariability: return "Heart Rate Variability"
        case .vo2Max: return "Cardio Fitness (VO₂ max)"
        case .oxygenSaturation: return "Oxygen Saturation"
        case .respiratoryRate: return "Respiratory Rate"
        case .bloodPressureSystolic: return "Blood Pressure (Systolic)"
        case .bloodPressureDiastolic: return "Blood Pressure (Diastolic)"
        case .bodyTemperature: return "Body Temperature"
        case .weight: return "Weight"
        case .bodyFatPercentage: return "Body Fat Percentage"
        case .height: return "Height"
        case .bodyMassIndex: return "Body Mass Index"
        case .sleepAnalysis: return "Sleep"
        case .workouts: return "Workouts"
        case .dietaryEnergy: return "Dietary Energy"
        case .dietaryWater: return "Water"
        }
    }
}
