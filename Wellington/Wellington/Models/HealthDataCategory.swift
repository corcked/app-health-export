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
    case basalEnergy
    case distanceWalking
    case flightsClimbed
    case workouts
    case heartRate
    case restingHeartRate
    case heartRateVariability
    case vo2Max
    case oxygenSaturation
    case respiratoryRate
    case bloodPressureSystolic
    case bloodPressureDiastolic
    case bodyTemperature
    case weight
    case bodyFatPercentage
    case height
    case bodyMassIndex
    case sleepAnalysis
    case dietaryEnergy
    case dietaryWater

    var id: String { rawValue }

    var group: CategoryGroup {
        switch self {
        case .steps, .activeEnergy, .basalEnergy, .distanceWalking, .flightsClimbed, .workouts:
            return .activity
        case .heartRate, .restingHeartRate, .heartRateVariability, .vo2Max, .oxygenSaturation, .respiratoryRate, .bloodPressureSystolic, .bloodPressureDiastolic:
            return .vitals
        case .weight, .bodyTemperature, .bodyFatPercentage, .height, .bodyMassIndex:
            return .body
        case .sleepAnalysis:
            return .sleep
        case .dietaryEnergy, .dietaryWater:
            return .nutrition
        }
    }

    var displayName: LocalizedStringKey {
        switch self {
        case .steps: "category_steps"
        case .activeEnergy: "category_active_energy"
        case .basalEnergy: "category_basal_energy"
        case .distanceWalking: "category_distance"
        case .flightsClimbed: "category_flights_climbed"
        case .heartRate: "category_heart_rate"
        case .restingHeartRate: "category_resting_heart_rate"
        case .heartRateVariability: "category_hrv"
        case .vo2Max: "category_vo2max"
        case .oxygenSaturation: "category_oxygen_saturation"
        case .respiratoryRate: "category_respiratory_rate"
        case .bloodPressureSystolic: "category_blood_pressure_systolic"
        case .bloodPressureDiastolic: "category_blood_pressure_diastolic"
        case .bodyTemperature: "category_body_temperature"
        case .weight: "category_weight"
        case .bodyFatPercentage: "category_body_fat"
        case .height: "category_height"
        case .bodyMassIndex: "category_bmi"
        case .sleepAnalysis: "category_sleep"
        case .workouts: "category_workouts"
        case .dietaryEnergy: "category_dietary_energy"
        case .dietaryWater: "category_dietary_water"
        }
    }

    var iconName: String {
        switch self {
        case .steps: "figure.walk"
        case .activeEnergy: "flame.fill"
        case .basalEnergy: "flame"
        case .distanceWalking: "map.fill"
        case .flightsClimbed: "figure.stairs"
        case .heartRate: "heart.fill"
        case .restingHeartRate: "heart.text.square"
        case .heartRateVariability: "waveform.path.ecg"
        case .vo2Max: "lungs.fill"
        case .oxygenSaturation: "drop.fill"
        case .respiratoryRate: "wind"
        case .bloodPressureSystolic, .bloodPressureDiastolic: "stethoscope"
        case .bodyTemperature: "thermometer"
        case .weight: "scalemass.fill"
        case .bodyFatPercentage: "percent"
        case .height: "ruler"
        case .bodyMassIndex: "figure.stand"
        case .sleepAnalysis: "bed.double.fill"
        case .workouts: "figure.run"
        case .dietaryEnergy: "fork.knife"
        case .dietaryWater: "drop.fill"
        }
    }

    var unitDisplayName: String {
        switch self {
        case .steps, .flightsClimbed: "count"
        case .activeEnergy, .basalEnergy, .dietaryEnergy: "kcal"
        case .distanceWalking: "m"
        case .heartRate, .restingHeartRate: "bpm"
        case .heartRateVariability: "ms"
        case .vo2Max: "mL/kg/min"
        case .oxygenSaturation, .bodyFatPercentage: "%"
        case .respiratoryRate: "br/min"
        case .bloodPressureSystolic, .bloodPressureDiastolic: "mmHg"
        case .bodyTemperature: "°C"
        case .weight: "kg"
        case .height: "cm"
        case .bodyMassIndex: "count"
        case .sleepAnalysis: ""
        case .workouts: ""
        case .dietaryWater: "mL"
        }
    }

    var sampleType: HKSampleType {
        switch self {
        case .steps: HKQuantityType(.stepCount)
        case .activeEnergy: HKQuantityType(.activeEnergyBurned)
        case .basalEnergy: HKQuantityType(.basalEnergyBurned)
        case .distanceWalking: HKQuantityType(.distanceWalkingRunning)
        case .flightsClimbed: HKQuantityType(.flightsClimbed)
        case .heartRate: HKQuantityType(.heartRate)
        case .restingHeartRate: HKQuantityType(.restingHeartRate)
        case .heartRateVariability: HKQuantityType(.heartRateVariabilitySDNN)
        case .vo2Max: HKQuantityType(.vo2Max)
        case .oxygenSaturation: HKQuantityType(.oxygenSaturation)
        case .respiratoryRate: HKQuantityType(.respiratoryRate)
        case .bloodPressureSystolic: HKQuantityType(.bloodPressureSystolic)
        case .bloodPressureDiastolic: HKQuantityType(.bloodPressureDiastolic)
        case .bodyTemperature: HKQuantityType(.bodyTemperature)
        case .weight: HKQuantityType(.bodyMass)
        case .bodyFatPercentage: HKQuantityType(.bodyFatPercentage)
        case .height: HKQuantityType(.height)
        case .bodyMassIndex: HKQuantityType(.bodyMassIndex)
        case .sleepAnalysis: HKCategoryType(.sleepAnalysis)
        case .workouts: HKWorkoutType.workoutType()
        case .dietaryEnergy: HKQuantityType(.dietaryEnergyConsumed)
        case .dietaryWater: HKQuantityType(.dietaryWater)
        }
    }

    var preferredUnit: HKUnit? {
        switch self {
        case .steps, .flightsClimbed: .count()
        case .activeEnergy, .basalEnergy, .dietaryEnergy: .kilocalorie()
        case .distanceWalking: .meter()
        case .heartRate, .restingHeartRate: .count().unitDivided(by: .minute())
        case .heartRateVariability: .secondUnit(with: .milli)
        case .vo2Max: HKUnit(from: "mL/kg*min")
        case .oxygenSaturation, .bodyFatPercentage: .percent()
        case .respiratoryRate: .count().unitDivided(by: .minute())
        case .bloodPressureSystolic, .bloodPressureDiastolic: .millimeterOfMercury()
        case .bodyTemperature: .degreeCelsius()
        case .weight: .gramUnit(with: .kilo)
        case .height: .meterUnit(with: .centi)
        case .bodyMassIndex: .count()
        case .sleepAnalysis, .workouts: nil
        case .dietaryWater: .literUnit(with: .milli)
        }
    }

    /// Whether this type uses cumulative statistics (daily totals) vs discrete samples
    var usesCumulativeStatistics: Bool {
        switch self {
        case .steps, .activeEnergy, .basalEnergy, .distanceWalking, .flightsClimbed, .dietaryEnergy, .dietaryWater:
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
