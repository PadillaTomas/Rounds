import Foundation

/// The pure timeline of a workout: given a whole-second offset from the first
/// bell, what round / phase are we in, how much is left, and which cue (if any)
/// fires at that instant. No clock, no timer, no observation — all of that lives
/// in ``RoundTimerEngine``. This is the part that's unit-tested.
struct RoundSequence {
    let activity: RoundsActivity

    var roundSeconds: Int { activity.roundSeconds }
    var restSeconds: Int { activity.restSeconds }
    var totalRounds: Int? { activity.totalRounds }

    /// Work + rest, the length of one full round for every round except a
    /// finite workout's last (which has no rest).
    private var cycle: Int { roundSeconds + restSeconds }

    /// Elapsed offset at which a finite workout is over.
    private var finishAt: Int? {
        totalRounds.map { ($0 - 1) * cycle + roundSeconds }
    }

    struct Tick: Equatable {
        var round: Int          // 1-based
        var phase: RoundPhase
        var remaining: Int      // whole seconds left in this phase
        var isFinished: Bool
    }

    /// State `elapsed` seconds after the first bell.
    func tick(atElapsed elapsed: Int) -> Tick {
        let t = max(0, elapsed)
        if let finishAt, t >= finishAt {
            return Tick(round: totalRounds ?? 1, phase: .work, remaining: 0, isFinished: true)
        }
        let round = t / cycle + 1
        let into = t % cycle
        if into < roundSeconds {
            return Tick(round: round, phase: .work,
                        remaining: roundSeconds - into, isFinished: false)
        }
        return Tick(round: round, phase: .rest,
                    remaining: cycle - into, isFinished: false)
    }

    /// The cue that fires the instant the clock reaches `elapsed` seconds, or
    /// `nil`. Bells at phase boundaries; a clap ten seconds before a work period
    /// ends.
    func cue(onCrossing elapsed: Int) -> Cue? {
        guard elapsed >= 0 else { return nil }
        guard elapsed > 0 else { return .roundStart }   // the first bell

        let prev = tick(atElapsed: elapsed - 1)
        let now = tick(atElapsed: elapsed)

        if now.isFinished, !prev.isFinished { return .fightEnd }
        if prev.phase == .work, now.phase == .rest { return .roundEnd }
        if prev.phase == .rest, now.phase == .work { return .roundStart }
        if now.phase == .work, !now.isFinished, roundSeconds > 10, now.remaining == 10 {
            return .tenSecondWarning
        }
        return nil
    }
}
