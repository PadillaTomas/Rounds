import SwiftUI
import UIKit
import UIWorkouts

/// The running screen. The whole background washes between the work and rest
/// phase colours as the timer flips — glanceable from across the gym — over a
/// large mono countdown and a round tally.
struct RoundTimerView: View {
    let activity: RoundsActivity

    @State private var engine: RoundTimerEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(activity: RoundsActivity, dimOtherAudio: Bool = true) {
        self.activity = activity
        _engine = State(wrappedValue: RoundTimerEngine(
            activity: activity,
            cues: CuePlayer(dimsOtherAudio: dimOtherAudio)
        ))
    }

    private var phaseColor: Color { engine.phase.wkPhase.color }
    private var isFinished: Bool { engine.runState == .finished }

    var body: some View {
        ZStack {
            WKColor.bg.ignoresSafeArea()
            (isFinished ? WKColor.stateDone : phaseColor)
                .opacity(0.14)
                .ignoresSafeArea()
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: engine.phase)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: engine.runState)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: WKSpace.xxl) {
                    WKLabelMono(headline)

                    ZStack {
                        WKProgressRing(
                            fraction: engine.fraction,
                            tint: engine.runState == .paused ? phaseColor.opacity(0.5) : phaseColor,
                            track: engine.phase.wkPhase.softColor,
                            lineWidth: 10
                        )
                        VStack(spacing: WKSpace.sm) {
                            Text(isFinished ? Copy.Timer.done : engine.phase.label)
                                .wkFont(.labelMono)
                                .foregroundStyle(engine.phase.wkPhase.onSoftColor)
                            WKTimeText(seconds: engine.remaining, size: .display)
                                .foregroundStyle(WKColor.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .padding(WKSpace.xxl)
                    }
                    .frame(maxWidth: 320)
                    .padding(.horizontal, WKSpace.xl)

                    tally
                }

                Spacer(minLength: 0)

                controls
            }
            .padding(WKSpace.lg)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            engine.start()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            engine.stop()
        }
    }

    private var headline: String {
        if let total = engine.totalRounds {
            return Copy.Timer.roundOfTotal(engine.round, total)
        }
        return Copy.Timer.round(engine.round)
    }

    @ViewBuilder private var tally: some View {
        if let total = engine.totalRounds, total <= 12 {
            HStack(spacing: WKSpace.sm) {
                ForEach(1...total, id: \.self) { i in
                    Circle()
                        .fill(i <= engine.round ? phaseColor : WKColor.border)
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityLabel(Copy.Timer.roundOfTotal(engine.round, total))
        } else {
            Text(Copy.Timer.round(engine.round))
                .wkFont(.labelMono)
                .foregroundStyle(WKColor.textTertiary)
        }
    }

    @ViewBuilder private var controls: some View {
        if isFinished {
            WKButton(Copy.Timer.done, style: .primary, size: .large) { dismiss() }
        } else {
            HStack(spacing: WKSpace.md) {
                WKButton(engine.runState == .paused ? Copy.Timer.resume : Copy.Timer.pause,
                         style: .softPhase(engine.phase.wkPhase),
                         size: .large) {
                    engine.togglePause()
                }
                WKButton(Copy.Timer.stop, style: .secondary, size: .large) {
                    engine.stop()
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    RoundTimerView(activity: .default)
}
