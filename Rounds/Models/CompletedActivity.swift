import Foundation
import SwiftData

/// One finished workout, recorded automatically when the timer reaches the final
/// bell (and, for Non-Stop, when it's stopped after at least one full round).
/// A flat snapshot — it copies the numbers it needs so a later edit to the saved
/// ``Workout`` never rewrites history.
@Model
final class CompletedActivity {
    var startedAt: Date
    /// Wall-clock seconds the workout actually ran (excludes paused time).
    var elapsedSeconds: Int
    /// Work periods completed. Equals ``plannedRounds`` for a workout run to the
    /// end; fewer if a Non-Stop workout was stopped.
    var completedRounds: Int
    /// The round count the workout was set up with, or `0` for Non-Stop.
    var plannedRounds: Int
    var roundSeconds: Int
    var restSeconds: Int
    /// The preset / saved-workout name this was started from, if any.
    var sourceName: String?
    /// Perceived exertion, 1…10, from the finish screen. `nil` until rated.
    var effortRating: Int?

    init(startedAt: Date,
         elapsedSeconds: Int,
         completedRounds: Int,
         plannedRounds: Int,
         roundSeconds: Int,
         restSeconds: Int,
         sourceName: String? = nil,
         effortRating: Int? = nil) {
        self.startedAt = startedAt
        self.elapsedSeconds = elapsedSeconds
        self.completedRounds = completedRounds
        self.plannedRounds = plannedRounds
        self.roundSeconds = roundSeconds
        self.restSeconds = restSeconds
        self.sourceName = sourceName
        self.effortRating = effortRating
    }

    var isNonStop: Bool { plannedRounds <= 0 }
}
