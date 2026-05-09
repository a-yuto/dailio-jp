import Foundation
import HealthKit

/// 本番用の SleepProvider。HKHealthStore + HKSampleQueryDescriptor で sleepAnalysis を集計する。
final class HealthKitSleepProvider: SleepProvider {
    private let store: HKHealthStore
    private let aggregator = SleepAggregator()

    init(store: HKHealthStore = HKHealthStore()) {
        self.store = store
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.unavailable
        }
        let type = HKCategoryType(.sleepAnalysis)
        try await store.requestAuthorization(toShare: [], read: [type])
    }

    func previousNightSleepHours(for date: Date) async throws -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }

        let logicalDay = LogicalDay(of: date)
        let range = logicalDay.previousNightSleepRange
        let type = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(
            withStart: range.lowerBound,
            end: range.upperBound,
            options: []
        )
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: type, predicate: predicate)],
            sortDescriptors: []
        )

        let samples = try await descriptor.result(for: store)
        let segments = samples.compactMap { SleepSegment(sample: $0) }
        let total = aggregator.totalSleepHours(segments: segments, in: range)
        return total > 0 ? total : nil
    }
}

// MARK: - Errors

enum HealthKitError: Error {
    case unavailable
}

// MARK: - HealthKit → SleepSegment 変換

private extension SleepSegment {
    init?(sample: HKCategorySample) {
        guard let stage = Stage(healthKitValue: sample.value) else { return nil }
        self.init(start: sample.startDate, end: sample.endDate, stage: stage)
    }
}

private extension SleepSegment.Stage {
    init?(healthKitValue: Int) {
        switch HKCategoryValueSleepAnalysis(rawValue: healthKitValue) {
        case .inBed: self = .inBed
        case .asleepUnspecified: self = .asleepUnspecified
        case .awake: self = .awake
        case .asleepCore: self = .asleepCore
        case .asleepDeep: self = .asleepDeep
        case .asleepREM: self = .asleepREM
        default: return nil
        }
    }
}
