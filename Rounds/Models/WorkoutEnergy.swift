import Foundation

/// The active-calorie estimate, shared by the Health write and the history row so
/// both show the same number. MET method — `kcal = MET × body-mass(kg) × hours` —
/// with intensities from the 2024 Adult Compendium of Physical Activities
/// ("boxing, simulated boxing round" and "HIIT, vigorous"). It's an estimate:
/// population averages, no heart rate. A real figure needs a watch.
enum WorkoutEnergy {
    static let boxingMET = 9.3
    static let hiitMET = 8.0

    /// Default body mass when Health hasn't been read yet (an average adult).
    static let defaultBodyMassKg = 70.0

    /// The most recent body mass HealthKit reported, cached so the history
    /// estimate isn't stuck on the default. Written by ``HealthWriter``.
    static var cachedBodyMassKg: Double {
        get {
            let v = UserDefaults.standard.double(forKey: "rounds.bodyMassKg")
            return v > 0 ? v : defaultBodyMassKg
        }
        set { UserDefaults.standard.set(newValue, forKey: "rounds.bodyMassKg") }
    }

    static func kcal(isBoxing: Bool, activeSeconds: Int, bodyMassKg: Double) -> Double {
        guard activeSeconds > 0 else { return 0 }
        let met = isBoxing ? boxingMET : hiitMET
        return met * bodyMassKg * (Double(activeSeconds) / 3600)
    }
}
