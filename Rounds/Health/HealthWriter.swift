import Foundation
import HealthKit

/// Writes finished workouts to the Health app: the `HKWorkout` itself, an
/// estimated active-energy sample, per-round segments, pause / resume events and
/// (iOS 18+) a perceived-effort score. Reads one thing — the latest body mass —
/// to estimate energy; nothing is transmitted anywhere.
///
/// Every call is a quiet no-op when Health is unavailable or the write isn't
/// permitted, so callers don't branch on permission state. A single
/// `HKHealthStore` for the app's lifetime (Apple's guidance), hence the shared
/// instance rather than an injected dependency.
@MainActor
final class HealthWriter {
    static let shared = HealthWriter()

    private let store = HKHealthStore()

    private init() {}

    enum Authorization { case granted, denied, unavailable }

    /// One finished workout, in Rounds' own terms — `HealthWriter` maps it to
    /// HealthKit so no other file touches the framework.
    struct Workout {
        var start: Date
        var end: Date
        var roundSeconds: Int
        var restSeconds: Int
        var plannedRounds: Int
        var completedRounds: Int
        var pauses: [DateInterval] = []
        /// Work periods only, in order — one Health segment each.
        var rounds: [Round] = []
        /// Perceived exertion, 1…10. Written only on iOS 18+.
        var effort: Int?

        struct Round { var index: Int; var interval: DateInterval }
    }

    private static var shareTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.activeEnergyBurned),
        ]
        if #available(iOS 18.0, *) { types.insert(HKQuantityType(.workoutEffortScore)) }
        return types
    }
    private static let readTypes: Set<HKObjectType> = [HKQuantityType(.bodyMass)]

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Ask for permission to write workouts + energy + effort and read body mass.
    /// Safe to call repeatedly: iOS only shows the sheet while undecided. We can
    /// read *share* status accurately (unlike read status), so we surface a real
    /// "denied".
    func requestAuthorization() async -> Authorization {
        guard isAvailable else { return .unavailable }
        try? await store.requestAuthorization(toShare: Self.shareTypes, read: Self.readTypes)
        return store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingDenied
            ? .denied : .granted
    }

    /// Save one finished workout. Does nothing if Health is unavailable, the run
    /// was empty, or the write isn't permitted.
    func save(_ w: Workout) async {
        guard isAvailable, w.end > w.start else { return }

        let type: HKWorkoutActivityType =
            w.roundSeconds >= 60 ? .boxing : .highIntensityIntervalTraining

        let config = HKWorkoutConfiguration()
        config.activityType = type

        let bodyMassKg = await latestBodyMassKg() ?? 70
        let energyKcal = estimatedActiveEnergyKcal(type: type, workout: w, bodyMassKg: bodyMassKg)

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: w.start)

            try await builder.addMetadata([
                HKMetadataKeyIndoorWorkout: true,
                HKMetadataKeyWorkoutBrandName: "Rounds",
                "RoundsPlannedRounds": w.plannedRounds,
                "RoundsCompletedRounds": w.completedRounds,
                "RoundsRoundSeconds": w.roundSeconds,
                "RoundsRestSeconds": w.restSeconds,
            ])

            let events = w.pauses.flatMap { pause in
                [HKWorkoutEvent(type: .pause, dateInterval: DateInterval(start: pause.start, duration: 0), metadata: nil),
                 HKWorkoutEvent(type: .resume, dateInterval: DateInterval(start: pause.end, duration: 0), metadata: nil)]
            }
            if !events.isEmpty { try await builder.addWorkoutEvents(events) }

            if let energyKcal {
                let sample = HKQuantitySample(
                    type: HKQuantityType(.activeEnergyBurned),
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: energyKcal),
                    start: w.start, end: w.end)
                try await builder.addSamples([sample])
            }

            for round in w.rounds {
                let segConfig = HKWorkoutConfiguration()
                segConfig.activityType = type
                let activity = HKWorkoutActivity(
                    workoutConfiguration: segConfig,
                    start: round.interval.start,
                    end: round.interval.end,
                    metadata: ["RoundsRound": round.index])
                try await builder.addWorkoutActivity(activity)
            }

            try await builder.endCollection(at: w.end)
            let workout = try await builder.finishWorkout()

            if #available(iOS 18.0, *), let effort = w.effort, let workout {
                let sample = HKQuantitySample(
                    type: HKQuantityType(.workoutEffortScore),
                    quantity: HKQuantity(unit: .appleEffortScore(), doubleValue: Double(effort)),
                    start: w.end, end: w.end)
                // `relate…` saves the sample itself — don't call store.save().
                try? await store.relateWorkoutEffortSample(sample, with: workout, activity: nil)
            }
        } catch {
            #if DEBUG
            print("⚠️ [HealthWriter] save failed: \(error)")
            #endif
        }
    }

    // MARK: - Estimation

    /// MET intensities from the 2024 Adult Compendium of Physical Activities:
    /// "boxing, simulated boxing round" and "HIIT, vigorous". Population averages —
    /// the estimate is rough by design; a real figure needs a heart-rate source.
    private static let boxingMET = 9.3
    private static let hiitMET = 8.0

    /// MET-based estimate: `MET × body-mass(kg) × active-hours`. Rest periods and
    /// paused time are excluded from the active duration.
    private func estimatedActiveEnergyKcal(type: HKWorkoutActivityType,
                                           workout w: Workout,
                                           bodyMassKg: Double) -> Double? {
        let paused = w.pauses.reduce(0) { $0 + $1.duration }
        let activeHours = max(0, w.end.timeIntervalSince(w.start) - paused) / 3600
        guard activeHours > 0 else { return nil }
        let met = type == .boxing ? Self.boxingMET : Self.hiitMET
        return met * bodyMassKg * activeHours
    }

    private func latestBodyMassKg() async -> Double? {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKQuantityType(.bodyMass),
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, _ in
                let kg = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }
}
