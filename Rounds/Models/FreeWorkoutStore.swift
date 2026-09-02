import Foundation

/// The persisted Free-workout setup — rounds, round length, rest length. The
/// wheels bind straight to these `UserDefaults` keys via `@AppStorage`, so the
/// last setup is always remembered between launches. (There is no "forget"
/// option — the setup screen simply reopens where you left it.)
enum FreeWorkoutStore {
    static let roundsKey = "rounds.freeRounds"
    static let roundSecondsKey = "rounds.freeRoundSeconds"
    static let restSecondsKey = "rounds.freeRestSeconds"

    static let defaultRounds = 12
    static let defaultRoundSeconds = 180
    static let defaultRestSeconds = 60

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
