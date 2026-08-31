import Foundation

/// A fully-resolved workout the timer can run. Value type — the timer engine
/// takes a snapshot of this at Start and never reads it again.
struct RoundsActivity: Identifiable {
    let id = UUID()
    /// Number of rounds, or `0` for an unbounded workout.
    var rounds: Int
    /// Raw wheel values; the timeline reads the floored ``roundSeconds`` /
    /// ``restSeconds`` below so a degenerate 0:00 can never reach the engine.
    var configuredRoundSeconds: Int
    var configuredRestSeconds: Int

    /// Shortest sensible work / rest period. The setup wheels don't offer less;
    /// the floors below are a safety net for any other path (presets, restored
    /// defaults, a bad persisted value).
    static let minRoundSeconds = 10
    static let minRestSeconds = 5

    static let `default` = RoundsActivity(
        rounds: 12, configuredRoundSeconds: 180, configuredRestSeconds: 60
    )

    var roundSeconds: Int { max(Self.minRoundSeconds, configuredRoundSeconds) }
    var restSeconds: Int { max(Self.minRestSeconds, configuredRestSeconds) }

    /// Total rounds, or `nil` for an unbounded workout.
    var totalRounds: Int? { rounds <= 0 ? nil : rounds }
}

/// A named starting point the setup screen loads into the wheels. Presets are
/// just a triple of wheel values — once loaded the setup is fully editable.
struct WorkoutPreset: Identifiable {
    let id = UUID()
    var title: String
    /// One-line stat summary, e.g. "12 rounds · 3:00 work · 1:00 rest".
    var summary: String
    /// A sentence of plain-language context, shown in the presets sheet.
    var detail: String
    var rounds: Int
    var roundSeconds: Int
    var restSeconds: Int

    static let fullCard = WorkoutPreset(
        title: Copy.Presets.fullCardTitle,
        summary: Copy.Presets.fullCardSummary,
        detail: Copy.Presets.fullCardDetail,
        rounds: 12, roundSeconds: 180, restSeconds: 60
    )

    static let all: [WorkoutPreset] = [.fullCard]

    /// Whether the current wheel values already match this preset exactly.
    func matches(rounds: Int, roundSeconds: Int, restSeconds: Int) -> Bool {
        self.rounds == rounds
            && self.roundSeconds == roundSeconds
            && self.restSeconds == restSeconds
    }
}
