import ActivityKit
import AppIntents
import SwiftUI
import UIWorkouts
import WidgetKit

struct RoundsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoundsActivityAttributes.self) { context in
            Group {
                if context.isStale {
                    Text("Workout ended")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                } else {
                    LockScreenView(state: context.state)
                }
            }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.phaseLabel)
                            .font(.headline)
                            .foregroundStyle(state.tint)
                        if !state.roundText.isEmpty {
                            Text(state.roundText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    PhaseTimer(state: state)
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .frame(maxWidth: 110, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if state.canControl, !context.isStale { Controls(state: state) }
                }
            } compactLeading: {
                Image(systemName: state.isWork ? "figure.boxing" : "pause.circle")
                    .foregroundStyle(state.tint)
            } compactTrailing: {
                PhaseTimer(state: state)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .frame(width: 44)
            } minimal: {
                Image(systemName: state.isWork ? "figure.boxing" : "pause.circle")
                    .foregroundStyle(state.tint)
            }
        }
    }
}

private extension RoundsActivityAttributes.ContentState {
    var tint: Color { (isWork ? WKPhase.run : WKPhase.walk).color }
}

private struct PhaseTimer: View {
    let state: RoundsActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.isFinished {
                Text("0:00")
            } else if state.pausedAt != nil {
                Text(WKTimeFormat.clock(state.remaining))
            } else {
                Text(timerInterval: state.phaseStart...state.phaseEnd,
                     countsDown: true, showsHours: false)
            }
        }
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    }
}

private struct LockScreenView: View {
    let state: RoundsActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.phaseLabel)
                        .font(.headline)
                        .foregroundStyle(state.tint)
                    if !state.roundText.isEmpty {
                        Text(state.roundText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                PhaseTimer(state: state)
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 150, alignment: .trailing)
            }
            progress
            if state.canControl { Controls(state: state) }
        }
    }

    @ViewBuilder private var progress: some View {
        if state.pausedAt != nil {
            ProgressView(value: min(1, max(0, 1 - Double(state.remaining) / max(1, state.phaseDuration))))
                .tint(state.tint)
        } else if state.isFinished {
            ProgressView(value: 1).tint(state.tint)
        } else {
            ProgressView(timerInterval: state.phaseStart...state.phaseEnd, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(state.tint)
        }
    }
}

private struct Controls: View {
    let state: RoundsActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            Button(intent: TogglePauseIntent(revision: state.revision)) {
                key(state.pausedAt == nil ? "pause.fill" : "play.fill",
                    fill: state.tint, icon: .black)
            }
            Button(intent: SkipIntervalIntent(revision: state.revision)) {
                key("forward.fill", fill: .white.opacity(0.18), icon: .white)
            }
            .disabled(!state.canSkip)
            .opacity(state.canSkip ? 1 : 0.4)
        }
        .buttonStyle(.plain)
    }

    private func key(_ symbol: String, fill: Color, icon: Color) -> some View {
        Image(systemName: symbol)
            .foregroundStyle(icon)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(fill, in: Capsule())
    }
}
