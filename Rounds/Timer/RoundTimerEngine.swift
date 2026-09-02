import Foundation
import Observation

/// Drives a workout: a repeating timer advances a whole-second clock, the pure
/// ``RoundSequence`` says what that means, and cues are fired as second
/// boundaries are crossed. Deadline-based (not a decrementing counter) so it
/// stays accurate across a dropped tick or a spin in the run loop.
///
/// The clock is injectable (`now`) so tests can drive it directly; screen
/// wake-lock lives in the view, not here, to keep this UIKit-free and testable.
@Observable
final class RoundTimerEngine {
    enum RunState { case running, paused, finished }
    /// How a finished workout ended — drives whether it's recorded to history.
    enum FinishReason: Equatable { case completed, stoppedEarly }

    private(set) var phase: RoundPhase = .work
    private(set) var round = 1
    private(set) var remaining: Int
    private(set) var runState: RunState = .running
    private(set) var finishReason: FinishReason?

    /// When the workout started (fixed at ``start()``, unaffected by pauses).
    @ObservationIgnored private(set) var sessionStart = Date()

    let sequence: RoundSequence

    @ObservationIgnored private let cues: CuePlaying
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var startDate = Date()
    @ObservationIgnored private var pauseDate: Date?
    @ObservationIgnored private var lastCrossed = -1
    @ObservationIgnored private var ticker: Timer?

    init(activity: RoundsActivity,
         cues: CuePlaying = CuePlayer(),
         now: @escaping () -> Date = Date.init) {
        self.sequence = RoundSequence(activity: activity)
        self.cues = cues
        self.now = now
        self.remaining = activity.roundSeconds
    }

    var activity: RoundsActivity { sequence.activity }
    var totalRounds: Int? { sequence.totalRounds }

    private var phaseDuration: Int {
        phase == .work ? sequence.roundSeconds : sequence.restSeconds
    }

    /// 0…1 progress through the current phase.
    var fraction: Double {
        guard phaseDuration > 0 else { return 0 }
        return min(1, max(0, 1 - Double(remaining) / Double(phaseDuration)))
    }

    // MARK: - Lifecycle

    func start() {
        guard runState != .finished else { return }
        cues.sessionDidBegin()
        sessionStart = now()
        startDate = now()
        advance()               // fires the first bell, sets round 1 / work
        startTicker()
    }

    func togglePause() {
        switch runState {
        case .running:
            runState = .paused
            pauseDate = now()
            ticker?.invalidate(); ticker = nil
        case .paused:
            if let pauseDate {
                startDate += now().timeIntervalSince(pauseDate)
            }
            pauseDate = nil
            runState = .running
            startTicker()
        case .finished:
            break
        }
    }

    /// Ends the workout early. Idempotent.
    func stop() { finish(.stoppedEarly) }

    /// Wall-clock seconds the workout ran, paused time excluded. Live while
    /// running, frozen at the value reached when it finished.
    var elapsed: Int { runState == .finished ? finalElapsed : elapsedSeconds() }
    @ObservationIgnored private var finalElapsed = 0

    /// Work periods finished. A completed workout counts every round; a workout
    /// stopped during a round counts the ones whose bell already rang.
    var completedRounds: Int {
        if finishReason == .completed { return totalRounds ?? round }
        return phase == .rest ? round : round - 1
    }

    // MARK: - Ticking

    private func startTicker() {
        ticker?.invalidate()
        let t = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in self?.advance() }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func elapsedSeconds() -> Int {
        let reference = pauseDate ?? now()
        return max(0, Int(reference.timeIntervalSince(startDate)))
    }

    /// Called every tick (and once at start). Fires cues for every second
    /// boundary crossed since the last call, then publishes the new state.
    func advance() {
        guard runState == .running else { return }
        let elapsed = elapsedSeconds()

        if elapsed > lastCrossed {
            for second in (lastCrossed + 1)...elapsed {
                fire(sequence.cue(onCrossing: second))
            }
            lastCrossed = elapsed
        }

        let tick = sequence.tick(atElapsed: elapsed)
        round = tick.round
        phase = tick.phase
        remaining = tick.remaining
        if tick.isFinished { finish(.completed) }
    }

    private func fire(_ cue: Cue?) {
        switch cue {
        case .roundStart:       cues.roundStarted()
        case .roundEnd:         cues.roundEnded()
        case .tenSecondWarning: cues.tenSecondWarning()
        case .fightEnd:         cues.sessionFinished()
        case nil:               break
        }
    }

    private func finish(_ reason: FinishReason) {
        guard runState != .finished else { return }
        finalElapsed = elapsedSeconds()
        finishReason = reason
        runState = .finished
        ticker?.invalidate(); ticker = nil
        remaining = 0
        cues.sessionDidEnd()
    }
}
