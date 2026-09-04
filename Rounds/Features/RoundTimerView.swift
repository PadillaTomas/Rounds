import AVFoundation
import SwiftUI
import SwiftData
import UIKit
import UIWorkouts

/// The running screen. A ``WKTimerDial`` counts down the current phase over a
/// ``WKAmbientBackground`` washed to the phase colour — glanceable from across
/// the gym — with the round tally in a pill up top, what's coming next and the
/// progress track below, and the controls pinned to the bottom.
struct RoundTimerView: View {
    let activity: RoundsActivity
    /// The preset / saved-workout name this run started from, if any.
    let sourceName: String?

    @State private var engine: RoundTimerEngine
    /// The history row for this run — inserted once when the workout finishes,
    /// then updated with the effort rating (and mirrored to Health) on Done.
    @State private var recordedActivity: CompletedActivity?
    /// Perceived exertion picked on the finish screen, 1…10.
    @State private var effort = 6
    /// The "Stop this workout?" confirmation.
    @State private var confirmStop = false
    /// True while we paused the engine ourselves to show that confirmation.
    @State private var pausedForConfirm = false
    /// Seconds left in the "get ready" countdown; the engine hasn't started yet
    /// while this is > 0.
    @State private var leadIn = Self.leadInSeconds
    @State private var didStartEngine = false
    @State private var leadInTimer: Timer?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// Whether to also send the finished workout to Apple Health. Resolved by the
    /// caller (Pro + the Settings toggle) so this view stays unaware of both.
    private let writeToHealth: Bool

    /// A breather to set the phone down and get into stance before the first bell.
    private static let leadInSeconds = 5

    init(activity: RoundsActivity,
         sourceName: String? = nil,
         dimOtherAudio: Bool = true,
         muteCues: Bool = false,
         writeToHealth: Bool = false) {
        self.activity = activity
        self.sourceName = sourceName
        self.writeToHealth = writeToHealth
        _engine = State(wrappedValue: RoundTimerEngine(
            activity: activity,
            cues: CuePlayer(dimsOtherAudio: dimOtherAudio, muted: muteCues)
        ))
    }

    private var isCountingIn: Bool { !didStartEngine && leadIn > 0 }

    private var isFinished: Bool { engine.runState == .finished }
    private var wkPhase: WKPhase { engine.phase.wkPhase }
    private var pillTone: WKPill.Tone { engine.phase == .work ? .run : .walk }

    private var dialState: WKTimerDial.State {
        switch engine.runState {
        case .running:  return .running
        case .paused:   return .paused
        case .finished: return .complete
        }
    }

    var body: some View {
        ZStack {
            WKColor.bg.ignoresSafeArea()
            if isCountingIn {
                WKAmbientBackground(phase: .run)
            } else if isFinished {
                WKAmbientBackground(.done)
            } else {
                WKAmbientBackground(phase: wkPhase)
            }

            if isCountingIn {
                leadInContent
            } else {
                runningContent
            }
        }
        .safeAreaInset(edge: .bottom) { controls }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            startLeadIn()
        }
        .onChange(of: engine.runState) { _, state in
            // The final bell: record automatically, no prompt.
            if state == .finished, engine.finishReason == .completed { recordActivity() }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: AVAudioSession.interruptionNotification)) { note in
            handleAudioInterruption(note)
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            leadInTimer?.invalidate(); leadInTimer = nil
            if didStartEngine { engine.stop() }
        }
        .alert(Copy.Timer.stopTitle, isPresented: $confirmStop) {
            if engine.completedRounds >= 1 {
                // Save & finish drops onto the finish screen (rate effort, then Done).
                Button(Copy.Timer.stopSave) { engine.stop(); recordActivity() }
                Button(Copy.Timer.stopDiscard, role: .destructive) { engine.stop(); dismiss() }
            } else {
                Button(Copy.Timer.stopConfirm, role: .destructive) { engine.stop(); dismiss() }
            }
            Button(Copy.Timer.stopResume, role: .cancel) { resumeAfterConfirm() }
        } message: {
            Text(engine.completedRounds >= 1 ? Copy.Timer.stopMessageSave : Copy.Timer.stopMessage)
        }
    }

    @ViewBuilder private var runningContent: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, WKSpace.lg)
                .padding(.top, WKSpace.sm)

            Spacer(minLength: WKSpace.lg)

            WKTimerDial(
                fraction: engine.fraction,
                phase: wkPhase,
                caption: engine.phase.label,
                seconds: engine.remaining,
                label: engine.phase.label,   // "Round" / "Rest", not "Run" / "Walk"
                state: dialState
            )
            .frame(width: 300, height: 300)
            .frame(maxWidth: .infinity)

            Spacer(minLength: WKSpace.lg)

            if isFinished {
                effortPrompt
            } else {
                upNext
                    .padding(.horizontal, WKSpace.lg)
                if !trackSegments.isEmpty {
                    WKSegmentedTrack(segments: trackSegments)
                        .padding(.horizontal, WKSpace.lg)
                        .padding(.top, WKSpace.sm)
                        .padding(.bottom, WKSpace.lg)
                } else {
                    Color.clear.frame(height: WKSpace.lg)
                }
            }
        }
    }

    /// Shown on the finish screen — a 1…10 perceived-exertion pick, written to
    /// history and (iOS 18+, Pro) to Health when the runner taps Done.
    private var effortPrompt: some View {
        VStack(spacing: WKSpace.sm) {
            Text(Copy.Timer.effortPrompt)
                .wkFont(.headline)
                .foregroundStyle(WKColor.textPrimary)
            WKScaleSelector(
                range: 1...10, selection: $effort,
                endLabels: (Copy.Timer.effortEasy, Copy.Timer.effortHard),
                maxPerRow: 5)
        }
        .padding(.horizontal, WKSpace.lg)
        .padding(.bottom, WKSpace.lg)
    }

    // MARK: - Lead-in

    private var leadInContent: some View {
        VStack(spacing: WKSpace.md) {
            WKLabelMono(Copy.Timer.getReady)
            Text("\(leadIn)")
                .wkFont(.metricL)
                .foregroundStyle(WKColor.textPrimary)
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: leadIn)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func startLeadIn() {
        guard !didStartEngine, leadInTimer == nil else { return }
        leadInTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            leadIn -= 1
            if leadIn <= 0 { finishLeadIn() }
        }
    }

    /// End the countdown and ring the first bell.
    private func finishLeadIn() {
        guard !didStartEngine else { return }
        leadInTimer?.invalidate(); leadInTimer = nil
        leadIn = 0
        didStartEngine = true
        engine.start()
    }

    // MARK: - Stop

    private func requestStop() {
        if isCountingIn { dismiss(); return }
        if engine.runState == .running {
            engine.togglePause()
            pausedForConfirm = true
        }
        confirmStop = true
    }

    private func resumeAfterConfirm() {
        if pausedForConfirm, engine.runState == .paused { engine.togglePause() }
        pausedForConfirm = false
    }

    /// A phone call (or any audio interruption) pauses the workout. It stays
    /// paused when the call ends — the fighter taps Resume when they're back.
    private func handleAudioInterruption(_ note: Notification) {
        guard didStartEngine, engine.runState == .running,
              let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: raw) == .began
        else { return }
        engine.togglePause()
    }

    /// Insert the history row — once — the moment the workout finishes. The
    /// effort rating and the Health write happen later, on ``finishAndDismiss()``.
    private func recordActivity() {
        guard recordedActivity == nil, engine.runState == .finished else { return }

        let record = CompletedActivity(
            startedAt: engine.sessionStart,
            elapsedSeconds: engine.elapsed,
            completedRounds: engine.completedRounds,
            plannedRounds: activity.rounds,
            roundSeconds: activity.roundSeconds,
            restSeconds: activity.restSeconds,
            sourceName: sourceName
        )
        modelContext.insert(record)
        try? modelContext.save()
        recordedActivity = record
    }

    /// Done on the finish screen: store the effort rating, mirror the workout to
    /// Health (Pro + opted in), and close.
    private func finishAndDismiss() {
        if let record = recordedActivity {
            record.effortRating = effort
            try? modelContext.save()

            if writeToHealth {
                let workout = HealthWriter.Workout(
                    start: engine.sessionStart,
                    end: engine.sessionEnd ?? Date(),
                    roundSeconds: activity.roundSeconds,
                    restSeconds: activity.restSeconds,
                    plannedRounds: activity.rounds,
                    completedRounds: engine.completedRounds,
                    pauses: engine.pauseIntervals,
                    rounds: engine.segments
                        .filter { $0.phase == .work }
                        .map { .init(index: $0.round, interval: $0.interval) },
                    effort: effort
                )
                Task { await HealthWriter.shared.save(workout) }
            }
        }
        dismiss()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Spacer()
            if let total = engine.totalRounds {
                WKPill(Copy.Timer.tally(engine.round, total), tone: pillTone)
            } else {
                WKPill(Copy.Timer.round(engine.round), tone: pillTone)
            }
        }
    }

    // MARK: - Up next

    @ViewBuilder private var upNext: some View {
        Text(nextText)
            .wkFont(.callout)
            .foregroundStyle(WKColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nextText: String {
        guard let next = nextPhase else { return Copy.Timer.lastRound }
        return Copy.Timer.nextUp(next.phase.label.lowercased(),
                                 WKTimeFormat.clock(next.seconds))
    }

    /// The phase after the current one — `nil` on a finite workout's last work
    /// period.
    private var nextPhase: (phase: RoundPhase, seconds: Int)? {
        switch engine.phase {
        case .work:
            if let total = engine.totalRounds, engine.round >= total { return nil }
            return (.rest, engine.activity.restSeconds)
        case .rest:
            return (.work, engine.activity.roundSeconds)
        }
    }

    // MARK: - Progress track

    private var trackSegments: [WKTrackSegment] {
        guard let phases = engine.sequence.phases else { return [] }
        return phases.enumerated().map { index, entry in
            WKTrackSegment(id: index,
                           weight: Double(entry.seconds),
                           progress: progress(round: entry.round, phase: entry.phase),
                           phase: entry.phase.wkPhase)
        }
    }

    private func progress(round: Int, phase: RoundPhase) -> WKTrackSegment.Progress {
        if round != engine.round { return round < engine.round ? .done : .upcoming }
        if phase == engine.phase { return .current }
        // Same round, other phase: work is done once its rest has begun.
        return (phase == .work && engine.phase == .rest) ? .done : .upcoming
    }

    // MARK: - Controls

    @ViewBuilder private var controls: some View {
        if isCountingIn {
            WKFooterActions {
                WKButton(Copy.Timer.stop, style: .secondary) { requestStop() }
            }
        } else if isFinished {
            WKFooterActions {
                WKButton(Copy.Timer.done, style: .primary) { finishAndDismiss() }
            }
        } else {
            WKFooterActions {
                WKButton(engine.runState == .paused ? Copy.Timer.resume : Copy.Timer.pause,
                         style: .primary) {
                    engine.togglePause()
                }
                WKButton(Copy.Timer.stop, style: .secondary) {
                    requestStop()
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    RoundTimerView(activity: .default)
        .modelContainer(RoundsStore.preview)
}
#endif
