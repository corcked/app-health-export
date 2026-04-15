import Foundation

struct ExportLog: Codable, Identifiable {
    let id: UUID
    let date: Date
    let recordCount: Int
    let format: String
    let success: Bool
    let errorMessage: String?

    init(date: Date = Date(), recordCount: Int, format: String, success: Bool, errorMessage: String? = nil) {
        self.id = UUID()
        self.date = date
        self.recordCount = recordCount
        self.format = format
        self.success = success
        self.errorMessage = errorMessage
    }

    static func loadAll() -> [ExportLog] {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.UserDefaultsKeys.exportLogs),
              let logs = try? JSONDecoder().decode([ExportLog].self, from: data) else {
            return []
        }
        return logs.sorted { $0.date > $1.date }
    }

    static func save(_ log: ExportLog) {
        var logs = loadAll()
        logs.insert(log, at: 0)
        // Keep last 100 entries
        if logs.count > 100 {
            logs = Array(logs.prefix(100))
        }
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: AppConstants.UserDefaultsKeys.exportLogs)
        }
    }

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.exportLogs)
    }
}
