import Foundation
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable, Codable {
    case csv
    case json
    case markdown

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .csv: "csv"
        case .json: "json"
        case .markdown: "md"
        }
    }

    var contentType: UTType {
        switch self {
        case .csv: .commaSeparatedText
        case .json: .json
        case .markdown: .plainText
        }
    }

    var displayName: String {
        switch self {
        case .csv: "CSV"
        case .json: "JSON"
        case .markdown: "Markdown"
        }
    }
}
