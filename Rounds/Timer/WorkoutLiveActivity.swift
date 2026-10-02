import ActivityKit
import Foundation

/// Mirrors the running workout onto the Lock Screen / Dynamic Island.
@MainActor
final class WorkoutLiveActivity {
    typealias State = RoundsActivityAttributes.ContentState

    private var activity: Activity<RoundsActivityAttributes>?
    private var pending: Task<Void, Never>?

    /// Stamped on every state sent. A Lock Screen tap carries the revision it was
    /// drawn with, so a second tap on a stale card is ignored.
    private(set) var revision = 0

    func start(_ state: State) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard let created = try? Activity.request(
            attributes: RoundsActivityAttributes(),
            content: .init(state: stamped(state), staleDate: Self.staleDate(for: state))) else { return }
        activity = created
        Task {
            for stale in Activity<RoundsActivityAttributes>.activities where stale.id != created.id {
                await stale.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    func update(_ state: State) {
        guard let activity else { return }
        let content = ActivityContent(state: stamped(state), staleDate: Self.staleDate(for: state))
        let previous = pending
        pending = Task {
            await previous?.value
            if state.isFinished {
                await activity.end(content, dismissalPolicy: .after(Date().addingTimeInterval(15)))
            } else {
                await activity.update(content)
            }
        }
    }

    private func stamped(_ state: State) -> State {
        revision += 1
        var state = state
        state.revision = revision
        return state
    }

    /// Waits until every queued update has reached the system.
    func flush() async { await pending?.value }

    /// Past this the system flags the card stale — only reached if the app was
    /// killed and could not send the next update.
    private static func staleDate(for state: State) -> Date {
        state.pausedAt == nil ? state.phaseEnd.addingTimeInterval(10)
                              : Date().addingTimeInterval(600)
    }

    static func endAll() async {
        for activity in Activity<RoundsActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// For app termination: waits briefly so the end reaches the system.
    nonisolated static func endAllBlocking() {
        let done = DispatchSemaphore(value: 0)
        Task.detached { await endAll(); done.signal() }
        _ = done.wait(timeout: .now() + 3)
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    static func leadIn(until end: Date, seconds: Int) -> State {
        State(isWork: true, phaseLabel: Copy.Timer.getReady, roundText: "",
              phaseEnd: end, phaseDuration: TimeInterval(seconds), remaining: seconds,
              pausedAt: nil,
              isFinished: false, canControl: false, canSkip: false)
    }

    static func running(_ engine: RoundTimerEngine) -> State {
        let finished = engine.runState == .finished
        let roundText = engine.totalRounds.map { Copy.Timer.tally(engine.round, $0) }
            ?? Copy.Timer.round(engine.round)
        return State(
            isWork: engine.phase == .work,
            phaseLabel: finished ? Copy.Timer.done : engine.phase.label,
            roundText: roundText,
            phaseEnd: engine.phaseEnd,
            phaseDuration: TimeInterval(engine.phaseDuration),
            remaining: engine.remaining,
            pausedAt: engine.pausedAt,
            isFinished: finished,
            canControl: !finished,
            canSkip: engine.canSkip)
    }
}
