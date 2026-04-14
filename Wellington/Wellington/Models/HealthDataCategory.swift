import Foundation
import HealthKit
import SwiftUI

enum CategoryGroup: String, CaseIterable, Identifiable, Codable {
    case activity = "activity"
    case vitals = "vitals"
    case body = "body"
    case sleep = "sleep"
    case nutrition = "nutrition"

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .activity: "category_group_activity"
        case .vitals: "category_group_vitals"
        case .body: "category_group_body"
        case .sleep: "category_group_sleep"
        case .nutrition: "category_group_nutrition"
        }
    }

    var iconName: String {
        switch self {
        case .activity: "figure.run"
        case .vitals: "heart.fill"
        case .body: "figure.stand"
        case .sleep: "bed.double.fill"
        case .nutrition: "fork.knife"
        }
    }
}

enum HealthDataCategory: String, CaseIterable, Identifiable, Codable {
    case steps
    case activeEnergy
    case distanceWalking
    case heartRate
    case restingHeartRate
    case oxygenSaturation
    case respiratoryRate
    case bloodPressureSystolic
    case bloodPressureDiastolic
    case bodyTemperature
    case weight
    case sleepAnalysis
    case workouts
    case dietaryEnergy

    var id: String { rawValue }

    var group: CategoryGroup {
        switch self {
        case .steps, .activeEnergy, .distanceWalking, .workouts:
            return .activity
        case .heartRate, .restingHeartRate, .oxygenSaturation, .respiratoryRate, .bloodPressureSystolic, .bloodPressureDiastolic:
            return .vitals
        case .weight, .bodyTemperature:
            return .body
        case .sleepAnalysis:
            return .sleep
        case .dietaryEnergy:
            return .nutrition
        }
    }

    var displayName: LocalizedStringKey {
        switch self {
        case .steps: "category_steps"
        case .activeEnergy: "category_active_energy"
        case .distanceWalking: "category_distance"
        case .heartRate: "category_heart_rate"
        case .restingHeartRate: "category_resting_heart_rate"
        case .oxygenSaturation: "category_oxygen_saturation"
        case .respiratoryRate: "category_respiratory_rate"
        case .bloodPressureSystolic: "category_blood_pressure_systolic"
        case .bloodPressureDiastolic: "category_blood_pressure_diastolic"
        case .bodyTemperature: "category_body_temperature"
        case .weight: "category_weight"
        case .sleepAnalysis: "category_sleep"
        case .workouts: "category_workouts"
        case .dietaryEnergy: "category_dietary_energy"
        }
    }

    var iconName: String {
        switch self {
        case .steps: "figure.walk"
        case .activeEnergy: "flame.fill"
        case .distanceWalking: "map.fill"
        case .heartRate: "heart.fill"
        case .restingHeartRate: "heart.text.square"
        case .oxygenSaturation: "lungs.fill"
        case .respiratoryRate: "wind"
        case .bloodPressureSystolic, .bloodPressureDiastolic: "stethoscope"
        case .bodyTemperature: "thermometer"
        case .weight: "scalemass.fill"
        case .sleepAnalysis: "bed.double.fill"
        case .workouts: "figure.run"
        case .dietaryEnergy: "fork.knife"
        }
    }

    var unitDisplayName: String {
        switch self {
        case .steps: "count"
        case .activeEnergy, .dietaryEnergy: "kcal"
        case .distanceWalking: "m"
        case .heartRate, .restingHeartRate: "bpm"
        case .oxygenSaturation: "%"
        case .respiratoryRate: "br/min"
        case .bloodPressureSystolic, .bloodPressureDiastolic: "mmHg"
        case .bodyTemperature: "°C"
        case .weight: "kg"
        case .sleepAnalysis: ""
        case .workouts: ""
        }
    }

    var sampleType: HKSampleType {
        switch self {
        case .steps: HKQuantityType(.stepCount)
        case .activeEnergy: HKQuantityType(.activeEnergyBurned)
        case .distanceWalking: HKQuantityType(.distanceWalkingRunning)
        case .heartRate: HKQuantityType(.heartRate)
        case .restingHeartRate: HKQuantityType(.restingHeartRate)
        case .oxygenSaturation: HKQuantityType(.oxygenSaturation)
        case .respiratoryRate: HKQuantityType(.respiratoryRate)
        case .bloodPressureSystolic: HKQuantityType(.bloodPressureSystolic)
        case .bloodPressureDiastolic: HKQuantityType(.bloodPressureDiastolic)
        case .bodyTemperature: HKQuantityType(.bodyTemperature)
        case .weight: HKQuantityType(.bodyMass)
        case .sleepAnalysis: HKCategoryType(.sleepAnalysis)
        case .workouts: HKWorkoutType.workoutType()
        case .dietaryEnergy: HKQuantityType(.dietaryEnergyConsumed)
        }
    }

    var preferredUnit: HKUnit? {
        switch self {
        case .steps: .count()
        case .activeEnergy, .dietaryEnergy: .kilocalorie()
        case .distanceWalking: .meter()
        case .heartRate, .restingHeartRate: .count().unitDivided(by: .minute())
        case .oxygenSaturation: .percent()
        case .respiratoryRate: .count().unitDivided(by: .minute())
        case .bloodPressureSystolic, .bloodPressureDiastolic: .millimeterOfMercury()
        case .bodyTemperature: .degreeCelsius()
        case .weight: .gramUnit(with: .kilo)
        case .sleepAnalysis, .workouts: nil
        }
    }

    /// Whether this type uses cumulative statistics (daily totals) vs discrete samples
    var usesCumulativeStatistics: Bool {
        switch self {
        case .steps, .activeEnergy, .distanceWalking, .dietaryEnergy:
            return true
        default:
            return false
        }
    }

    static var groupedCategories: [(group: CategoryGroup, categories: [HealthDataCategory])] {
        CategoryGroup.allCases.compactMap { group in
            let categories = Self.allCases.filter { $0.group == group }
            return categories.isEmpty ? nil : (group: group, categories: categories)
        }
    }
}
