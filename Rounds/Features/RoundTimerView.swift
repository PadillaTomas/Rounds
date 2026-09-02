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
    /// Guards the one-shot history write.
    @State private var recorded = false
    /// "Save this workout?" prompt after Stop.
    @State private var askToSave = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    init(activity: RoundsActivity, sourceName: String? = nil, dimOtherAudio: Bool = true) {
        self.activity = activity
        self.sourceName = sourceName
        _engine = State(wrappedValue: RoundTimerEngine(
            activity: activity,
            cues: CuePlayer(dimsOtherAudio: dimOtherAudio)
        ))
    }

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
            if isFinished {
                WKAmbientBackground(.done)
            } else {
                WKAmbientBackground(phase: wkPhase)
            }

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

                if !isFinished {
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
        .safeAreaInset(edge: .bottom) { controls }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            engine.start()
        }
        .onChange(of: engine.runState) { _, state in
            // The final bell: record automatically, no prompt.
            if state == .finished, engine.finishReason == .completed { recordActivity() }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            engine.stop()
        }
        .alert(Copy.Timer.saveTitle, isPresented: $askToSave) {
            Button(Copy.Timer.saveKeep) { recordActivity(); dismiss() }
            Button(Copy.Timer.saveDiscard, role: .cancel) { dismiss() }
        } message: {
            Text(Copy.Timer.saveMessage)
        }
    }

    /// Stop pressed. If a full round ran, ask whether to keep it; otherwise just
    /// leave (nothing worth recording).
    private func stopAndAskToSave() {
        engine.stop()
        if engine.completedRounds >= 1 {
            askToSave = true
        } else {
            dismiss()
        }
    }

    /// Write the finished workout to history — once.
    private func recordActivity() {
        guard !recorded, engine.runState == .finished else { return }
        recorded = true
        modelContext.insert(CompletedActivity(
            startedAt: engine.sessionStart,
            elapsedSeconds: engine.elapsed,
            completedRounds: engine.completedRounds,
            plannedRounds: activity.rounds,
            roundSeconds: activity.roundSeconds,
            restSeconds: activity.restSeconds,
            sourceName: sourceName
        ))
        try? modelContext.save()
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
        if isFinished {
            WKFooterActions {
                WKButton(Copy.Timer.done, style: .primary) { dismiss() }
            }
        } else {
            WKFooterActions {
                WKButton(engine.runState == .paused ? Copy.Timer.resume : Copy.Timer.pause,
                         style: .primary) {
                    engine.togglePause()
                }
                WKButton(Copy.Timer.stop, style: .secondary) {
                    stopAndAskToSave()
                }
            }
        }
    }
}

#Preview {
    RoundTimerView(activity: .default)
        .modelContainer(RoundsStore.preview)
}
