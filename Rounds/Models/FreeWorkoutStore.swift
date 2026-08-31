import Foundation

/// The persisted Free-workout setup (rounds, round length, rest length) and the
/// "remember it" preference.
///
/// The wheels bind straight to these `UserDefaults` keys via `@AppStorage`, so
/// while "Save last used free workout" is on they persist for free. When it's
/// off, ``resetIfNotSaving()`` wipes them back to the defaults at launch (and
/// when the toggle is switched off), so the setup screen always opens on
/// 12 rounds of 3:00 with 1:00 rest.
enum FreeWorkoutStore {
    static let saveKey = "rounds.saveFreeWorkout"
    static let roundsKey = "rounds.freeRounds"
    static let roundSecondsKey = "rounds.freeRoundSeconds"
    static let restSecondsKey = "rounds.freeRestSeconds"

    static let defaultRounds = 12
    static let defaultRoundSeconds = 180
    static let defaultRestSeconds = 60

    /// Whether the Free setup is remembered between launches. Defaults to `true`
    /// (the key is absent on first launch).
    static func isSaving(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: saveKey) as? Bool ?? true
    }

    /// If "save last used" is off, restore the Free values to their defaults.
    /// Call at launch and whenever the toggle is switched off.
    static func resetIfNotSaving(_ defaults: UserDefaults = .standard) {
        guard !isSaving(defaults) else { return }
        defaults.set(defaultRounds, forKey: roundsKey)
        defaults.set(defaultRoundSeconds, forKey: roundSecondsKey)
        defaults.set(defaultRestSeconds, forKey: restSecondsKey)
    }

    /// Raise a stored duration that predates the current minimums (e.g. a value
    /// saved by an early build whose wheels allowed sub-minimum picks).
    static func clampToMinimums(_ defaults: UserDefaults = .standard) {
        if let r = defaults.object(forKey: roundSecondsKey) as? Int, r < RoundsActivity.minRoundSeconds {
            defaults.set(RoundsActivity.minRoundSeconds, forKey: roundSecondsKey)
        }
        if let r = defaults.object(forKey: restSecondsKey) as? Int, r < RoundsActivity.minRestSeconds {
            defaults.set(RoundsActivity.minRestSeconds, forKey: restSecondsKey)
        }
    }
}
