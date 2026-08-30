import UIWorkouts

/// A phase of a boxing round: the work period, or the rest between rounds.
enum RoundPhase: Equatable {
    case work
    case rest

    var label: String {
        switch self {
        case .work: return Copy.Timer.work
        case .rest: return Copy.Timer.rest
        }
    }

    /// Maps onto the design-system phase so screens pull colour from one place.
    ///
    /// TODO(Rounds palette): the confirmed Phase-3 boxing palette (Corner Red /
    /// Cooldown Teal / Mat Black) is not in UIWorkouts yet. Once it lands, this
    /// becomes `WKPhase.round` / `.rest` and no call site changes.
    var wkPhase: WKPhase {
        switch self {
        case .work: return .run
        case .rest: return .walk
        }
    }
}

/// A single audible/haptic event the timeline produces.
enum Cue: Equatable {
    /// Bell — a work period begins (first round, or after a rest).
    case roundStart
    /// Bell — a work period ends, rest begins.
    case roundEnd
    /// Wooden clap — ten seconds left in the work period.
    case tenSecondWarning
    /// End-of-fight bell — the final round's work period ended.
    case fightEnd
}
