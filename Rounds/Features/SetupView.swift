import SwiftUI
import UIWorkouts

/// The one setup screen: pick Full Card or Free. Free reveals wheel pickers for
/// round count, round length and rest length. Last-used values persist.
struct SetupView: View {
    @AppStorage("rounds.mode") private var mode: RoundsMode = .fullCard
    /// `0` == infinite.
    @AppStorage(FreeWorkoutStore.roundsKey) private var freeRounds = FreeWorkoutStore.defaultRounds
    @AppStorage(FreeWorkoutStore.roundSecondsKey) private var freeRoundSeconds = FreeWorkoutStore.defaultRoundSeconds
    @AppStorage(FreeWorkoutStore.restSecondsKey) private var freeRestSeconds = FreeWorkoutStore.defaultRestSeconds
    @AppStorage("rounds.dimOtherAudio") private var dimOtherAudio = true

    @State private var running: RoundsActivity?
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WKSpace.xl) {
                    WKScreenHeader(
                        eyebrow: Copy.Setup.eyebrow,
                        title: Copy.Setup.title,
                        body: Copy.Setup.body
                    )

                    VStack(spacing: WKSpace.md) {
                        ForEach(RoundsMode.allCases) { option in
                            WKChoiceCard(title: option.title,
                                         body: option.detail,
                                         isSelected: mode == option) { mode = option }
                        }
                    }

                    if mode == .free {
                        VStack(spacing: WKSpace.md) {
                            roundsCard
                            durationCard(Copy.Setup.roundLength, total: $freeRoundSeconds)
                            durationCard(Copy.Setup.restLength, total: $freeRestSeconds)
                        }
                    }
                }
                .padding(WKSpace.lg)
            }
            .background(WKColor.bg)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(WKColor.textSecondary)
                    .accessibilityLabel(Copy.A11y.settings)
                }
            }
            .safeAreaInset(edge: .bottom) {
                WKFooterActions {
                    WKButton(Copy.Setup.start, style: .primary, size: .large) {
                        running = RoundsActivity(mode: mode,
                                                 freeRounds: freeRounds,
                                                 freeRoundSeconds: freeRoundSeconds,
                                                 freeRestSeconds: freeRestSeconds)
                    }
                }
            }
        }
        .fullScreenCover(item: $running) { activity in
            RoundTimerView(activity: activity, dimOtherAudio: dimOtherAudio)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Cards

    /// A single wheel — "Infinite" first, then 1…99.
    private var roundsCard: some View {
        WKCard {
            VStack(alignment: .leading, spacing: WKSpace.xs) {
                Text(Copy.Setup.rounds)
                    .wkFont(.body)
                    .foregroundStyle(WKColor.textPrimary)
                Picker(Copy.Setup.rounds, selection: $freeRounds) {
                    Text(Copy.Setup.infinite).tag(0)
                    ForEach(1...99, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 110)
                .clipped()
            }
        }
    }

    /// Minutes and seconds as two independent wheels.
    private func durationCard(_ title: String, total: Binding<Int>) -> some View {
        WKCard {
            VStack(alignment: .leading, spacing: WKSpace.xs) {
                Text(title)
                    .wkFont(.body)
                    .foregroundStyle(WKColor.textPrimary)
                HStack(spacing: 0) {
                    wheel(Copy.Setup.unitMinutes, selection: minutesBinding(total), values: Array(0...10))
                    unit(Copy.Setup.unitMinutes)
                    wheel(Copy.Setup.unitSeconds, selection: secondsBinding(total), values: Array(0...59)) {
                        String(format: "%02d", $0)
                    }
                    unit(Copy.Setup.unitSeconds)
                }
                .frame(height: 110)
            }
        }
    }

    private func wheel(_ label: String,
                       selection: Binding<Int>,
                       values: [Int],
                       format: @escaping (Int) -> String = { "\($0)" }) -> some View {
        Picker(label, selection: selection) {
            ForEach(values, id: \.self) { Text(format($0)).tag($0) }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private func unit(_ text: String) -> some View {
        Text(text)
            .wkFont(.caption)
            .foregroundStyle(WKColor.textTertiary)
            .padding(.trailing, WKSpace.sm)
    }

    // MARK: - Bindings

    private func minutesBinding(_ total: Binding<Int>) -> Binding<Int> {
        Binding(get: { total.wrappedValue / 60 },
                set: { total.wrappedValue = $0 * 60 + total.wrappedValue % 60 })
    }

    private func secondsBinding(_ total: Binding<Int>) -> Binding<Int> {
        Binding(get: { total.wrappedValue % 60 },
                set: { total.wrappedValue = (total.wrappedValue / 60) * 60 + $0 })
    }
}

#Preview {
    SetupView()
}
