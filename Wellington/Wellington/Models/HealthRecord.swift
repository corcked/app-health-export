import Foundation

struct HealthRecord: Codable, Identifiable {
    let id: UUID
    let category: String
    let value: Double
    let unit: String
    let startDate: Date
    let endDate: Date
    let sourceName: String
    let metadata: [String: String]?

    // Workout-specific fields
    let workoutType: String?
    let duration: TimeInterval?
    let totalDistance: Double?
    let totalEnergyBurned: Double?

    // Sleep-specific field
    let sleepStage: String?

    init(
        id: UUID = UUID(),
        category: String,
        value: Double,
        unit: String,
        startDate: Date,
        endDate: Date,
        sourceName: String,
        metadata: [String: String]? = nil,
        workoutType: String? = nil,
        duration: TimeInterval? = nil,
        totalDistance: Double? = nil,
        totalEnergyBurned: Double? = nil,
        sleepStage: String? = nil
    ) {
        self.id = id
        self.category = category
        self.value = value
        self.unit = unit
        self.startDate = startDate
        self.endDate = endDate
        self.sourceName = sourceName
        self.metadata = metadata
        self.workoutType = workoutType
        self.duration = duration
        self.totalDistance = totalDistance
        self.totalEnergyBurned = totalEnergyBurned
        self.sleepStage = sleepStage
    }
}
