import Foundation
import HealthKit
import os

@Observable
final class HealthKitService {

    // MARK: - Properties

    private let healthStore: HKHealthStore
    private let logger = Logger(subsystem: "com.wellington.app", category: "HealthKitService")

    private(set) var isAuthorized = false

    // MARK: - Availability

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Initialization

    init() {
        self.healthStore = HKHealthStore()
    }

    // MARK: - Authorization

    /// Requests read-only authorization for the specified health data categories.
    func requestAuthorization(for categories: [HealthDataCategory]) async throws {
        guard Self.isAvailable else {
            throw WellingtonError.healthKitNotAvailable
        }

        let readTypes: Set<HKObjectType> = Set(categories.map { $0.sampleType })

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
    }

    // MARK: - Fetch Records

    /// Fetches health records for a single category within the given date range.
    func fetchRecords(
        for category: HealthDataCategory,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HealthRecord] {
        guard Self.isAvailable else {
            throw WellingtonError.healthKitNotAvailable
        }

        if category.usesCumulativeStatistics {
            return try await fetchCumulativeStatistics(
                for: category,
                from: startDate,
                to: endDate
            )
        }

        switch category {
        case .sleepAnalysis:
            return try await fetchSleepRecords(from: startDate, to: endDate)
        case .workouts:
            return try await fetchWorkoutRecords(from: startDate, to: endDate)
        default:
            return try await fetchDiscreteSamples(
                for: category,
                from: startDate,
                to: endDate
            )
        }
    }

    /// Fetches health records for multiple categories within the given date range.
    func fetchAllRecords(
        categories: [HealthDataCategory],
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HealthDataCategory: [HealthRecord]] {
        try await withThrowingTaskGroup(
            of: (HealthDataCategory, [HealthRecord]).self
        ) { group in
            for category in categories {
                group.addTask {
                    let records = try await self.fetchRecords(
                        for: category,
                        from: startDate,
                        to: endDate
                    )
                    return (category, records)
                }
            }

            var results: [HealthDataCategory: [HealthRecord]] = [:]
            for try await (category, records) in group {
                results[category] = records
            }
            return results
        }
    }

    // MARK: - Cumulative Statistics (Steps, Active Energy, Distance, Dietary Energy)

    private func fetchCumulativeStatistics(
        for category: HealthDataCategory,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HealthRecord] {
        guard let quantityType = category.sampleType as? HKQuantityType,
              let unit = category.preferredUnit else {
            return []
        }

        let calendar = Calendar.current
        var interval = DateComponents()
        interval.day = 1

        let anchorDate = calendar.startOfDay(for: startDate)

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { [weak self] _, results, error in
                if let error {
                    self?.logger.error("Statistics query failed for \(category.rawValue): \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let results else {
                    continuation.resume(returning: [])
                    return
                }

                var records: [HealthRecord] = []

                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    guard let sum = statistics.sumQuantity() else { return }

                    let value = sum.doubleValue(for: unit)
                    let record = HealthRecord(
                        category: category.rawValue,
                        value: value,
                        unit: category.unitDisplayName,
                        startDate: statistics.startDate,
                        endDate: statistics.endDate,
                        sourceName: statistics.sources?.first?.name ?? "Apple Health"
                    )
                    records.append(record)
                }

                continuation.resume(returning: records)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Discrete Quantity Samples (Heart Rate, Weight, Temperature, etc.)

    private func fetchDiscreteSamples(
        for category: HealthDataCategory,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HealthRecord] {
        guard let quantityType = category.sampleType as? HKQuantityType,
              let unit = category.preferredUnit else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                if let error {
                    self?.logger.error("Sample query failed for \(category.rawValue): \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let records = quantitySamples.map { sample in
                    HealthRecord(
                        category: category.rawValue,
                        value: sample.quantity.doubleValue(for: unit),
                        unit: category.unitDisplayName,
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        sourceName: sample.sourceRevision.source.name
                    )
                }

                continuation.resume(returning: records)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Sleep Analysis

    private func fetchSleepRecords(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HealthRecord] {
        let categoryType = HKCategoryType(.sleepAnalysis)

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: categoryType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                if let error {
                    self?.logger.error("Sleep query failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let categorySamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let records = categorySamples.map { sample in
                    let stage = Self.sleepStageName(
                        for: HKCategoryValueSleepAnalysis(rawValue: sample.value)
                    )
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)

                    return HealthRecord(
                        category: HealthDataCategory.sleepAnalysis.rawValue,
                        value: duration / 3600.0, // hours
                        unit: "hr",
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        sourceName: sample.sourceRevision.source.name,
                        sleepStage: stage
                    )
                }

                continuation.resume(returning: records)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Workouts

    private func fetchWorkoutRecords(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HealthRecord] {
        let workoutType = HKWorkoutType.workoutType()

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                if let error {
                    self?.logger.error("Workout query failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }

                let records = workouts.map { workout in
                    let totalEnergy = workout.totalEnergyBurned?.doubleValue(
                        for: .kilocalorie()
                    )
                    let totalDist = workout.totalDistance?.doubleValue(for: .meter())

                    return HealthRecord(
                        category: HealthDataCategory.workouts.rawValue,
                        value: totalEnergy ?? 0,
                        unit: "kcal",
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        sourceName: workout.sourceRevision.source.name,
                        workoutType: Self.workoutActivityTypeName(workout.workoutActivityType),
                        duration: workout.duration,
                        totalDistance: totalDist,
                        totalEnergyBurned: totalEnergy
                    )
                }

                continuation.resume(returning: records)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Helpers

    private static func sleepStageName(for value: HKCategoryValueSleepAnalysis?) -> String {
        guard let value else { return "Unknown" }

        switch value {
        case .inBed:
            return "In Bed"
        case .asleepUnspecified:
            return "Asleep"
        case .awake:
            return "Awake"
        case .asleepCore:
            return "Core Sleep"
        case .asleepDeep:
            return "Deep Sleep"
        case .asleepREM:
            return "REM Sleep"
        @unknown default:
            return "Unknown"
        }
    }

    private static func workoutActivityTypeName(_ activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Traditional Strength Training"
        case .coreTraining: return "Core Training"
        case .crossTraining: return "Cross Training"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .highIntensityIntervalTraining: return "HIIT"
        case .jumpRope: return "Jump Rope"
        case .pilates: return "Pilates"
        case .dance: return "Dance"
        case .cooldown: return "Cooldown"
        case .pickleball: return "Pickleball"
        case .tennis: return "Tennis"
        case .badminton: return "Badminton"
        case .soccer: return "Soccer"
        case .basketball: return "Basketball"
        case .baseball: return "Baseball"
        case .golf: return "Golf"
        case .americanFootball: return "American Football"
        case .skatingSports: return "Skating"
        case .snowSports: return "Snow Sports"
        case .surfingSports: return "Surfing"
        case .waterFitness: return "Water Fitness"
        case .mixedCardio: return "Mixed Cardio"
        case .mindAndBody: return "Mind and Body"
        case .flexibility: return "Flexibility"
        case .other: return "Other"
        default: return "Workout"
        }
    }
}
