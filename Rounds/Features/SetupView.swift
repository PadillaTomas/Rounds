import SwiftUI
import UIWorkouts

/// The one setup screen — deliberately a single non-scrolling height: a title
/// row with a presets menu, one card (rounds stepper + round/rest wheels), and
/// the Start button pinned to the bottom. Last-used values persist.
struct SetupView: View {
    /// `0` == Non-Stop.
    @AppStorage(FreeWorkoutStore.roundsKey) private var freeRounds = FreeWorkoutStore.defaultRounds
    @AppStorage(FreeWorkoutStore.roundSecondsKey) private var freeRoundSeconds = FreeWorkoutStore.defaultRoundSeconds
    @AppStorage(FreeWorkoutStore.restSecondsKey) private var freeRestSeconds = FreeWorkoutStore.defaultRestSeconds
    @AppStorage("rounds.dimOtherAudio") private var dimOtherAudio = true
    @AppStorage("rounds.muteCues") private var muteCues = false

    @State private var running: RoundsActivity?
    /// Name of the preset the running values came from, if they match one exactly.
    @State private var runningSource: String?
    @State private var showPresets = false
    /// The round count to restore when Non-Stop is switched back off.
    @State private var lastFiniteRounds = FreeWorkoutStore.defaultRounds

    var body: some View {
        VStack(spacing: WKSpace.xl) {
            header
            workoutCard
            Spacer(minLength: 0)
            WKButton(Copy.Setup.start, style: .primary, size: .regular) {
                runningSource = WorkoutPreset.all.first {
                    $0.matches(rounds: freeRounds,
                               roundSeconds: freeRoundSeconds,
                               restSeconds: freeRestSeconds)
                }?.title
                running = RoundsActivity(rounds: freeRounds,
                                         configuredRoundSeconds: freeRoundSeconds,
                                         configuredRestSeconds: freeRestSeconds)
            }
        }
        .padding(WKSpace.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WKColor.bg)
        .fullScreenCover(item: $running) { activity in
            RoundTimerView(activity: activity,
                           sourceName: runningSource,
                           dimOtherAudio: dimOtherAudio,
                           muteCues: muteCues)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: WKSpace.xs) {
            WKLabelMono(Copy.Setup.eyebrow)
            Text(Copy.Setup.title)
                .wkFont(.titleM)
                .foregroundStyle(WKColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var presetsButton: some View {
        Button { showPresets = true } label: {
            Label(Copy.Presets.heading, systemImage: "square.stack.3d.up")
                .wkFont(.callout)
                .foregroundStyle(WKColor.accent)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .sheet(isPresented: $showPresets) {
            PresetsSheet { preset in
                withAnimation(.snappy) {
                    freeRounds = preset.rounds
                    freeRoundSeconds = preset.roundSeconds
                    freeRestSeconds = preset.restSeconds
                }
                showPresets = false
            }
        }
    }

    // MARK: - Card

    /// Rounds, round length and rest length — one card, three stacked sections.
    private var workoutCard: some View {
        WKCard {
            VStack(alignment: .leading, spacing: WKSpace.lg) {
                roundsSection
                Divider().overlay(WKColor.border)
                durationSection(Copy.Setup.roundLength, total: $freeRoundSeconds,
                                min: RoundsActivity.minRoundSeconds)
                Divider().overlay(WKColor.border)
                durationSection(Copy.Setup.restLength, total: $freeRestSeconds,
                                min: RoundsActivity.minRestSeconds)
                Divider().overlay(WKColor.border)
                presetsButton
            }
        }
    }

    private var isNonStop: Bool { freeRounds <= 0 }

    private var roundsSection: some View {
        VStack(spacing: WKSpace.lg) {
            HStack {
                Text(Copy.Setup.rounds)
                    .wkFont(.body)
                    .foregroundStyle(WKColor.textPrimary)
                Spacer(minLength: WKSpace.md)
                WKStepper(
                    value: Binding(get: { isNonStop ? lastFiniteRounds : freeRounds },
                                   set: { freeRounds = $0 }),
                    in: 1...99
                )
                .disabled(isNonStop)
                .opacity(isNonStop ? 0.4 : 1)
                .accessibilityLabel(Copy.Setup.rounds)
            }

            Button {
                withAnimation(.snappy) {
                    freeRounds = isNonStop ? max(1, lastFiniteRounds) : 0
                }
            } label: {
                Text(Copy.Setup.infinite)
                    .wkFont(.body)
                    .foregroundStyle(isNonStop ? WKColor.accent : WKColor.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isNonStop ? [.isSelected] : [])
        }
        .onChange(of: freeRounds) { _, new in
            if new > 0 { lastFiniteRounds = new }
        }
        .onAppear {
            if freeRounds > 0 { lastFiniteRounds = freeRounds }
        }
    }

    /// Minutes and seconds as two independent wheels. Below one minute the
    /// seconds wheel starts at `minTotal` — the picker never offers a value the
    /// timer would silently floor.
    private func durationSection(_ title: String, total: Binding<Int>, min minTotal: Int) -> some View {
        let firstSecond = total.wrappedValue < 60 ? minTotal : 0
        return VStack(alignment: .leading, spacing: WKSpace.xs) {
            Text(title)
                .wkFont(.body)
                .foregroundStyle(WKColor.textPrimary)
            HStack(spacing: 0) {
                wheel(Copy.Setup.unitMinutes, selection: minutesBinding(total, min: minTotal),
                      values: Array(0...10))
                unit(Copy.Setup.unitMinutes)
                wheel(Copy.Setup.unitSeconds, selection: secondsBinding(total, min: minTotal),
                      values: Array(firstSecond...59)) {
                    String(format: "%02d", $0)
                }
                unit(Copy.Setup.unitSeconds)
            }
            .frame(height: 96)
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

    private func minutesBinding(_ total: Binding<Int>, min minTotal: Int) -> Binding<Int> {
        Binding(get: { total.wrappedValue / 60 },
                set: { total.wrappedValue = max(minTotal, $0 * 60 + total.wrappedValue % 60) })
    }

    private func secondsBinding(_ total: Binding<Int>, min minTotal: Int) -> Binding<Int> {
        Binding(get: { total.wrappedValue % 60 },
                set: { total.wrappedValue = max(minTotal, (total.wrappedValue / 60) * 60 + $0) })
    }
}

/// The "Default workouts" sheet — a short list of ready-made setups, each with a
/// line of context. Picking one loads it into the wheels and closes.
struct PresetsSheet: View {
    let onSelect: (WorkoutPreset) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: WKSpace.md) {
                    ForEach(WorkoutPreset.all) { preset in
                        Button { onSelect(preset) } label: {
                            WKCard {
                                VStack(alignment: .leading, spacing: WKSpace.xs) {
                                    Text(preset.title)
                                        .wkFont(.headline)
                                        .foregroundStyle(WKColor.textPrimary)
                                    Text(preset.summary)
                                        .wkFont(.callout)
                                        .foregroundStyle(WKColor.textSecondary)
                                    Text(preset.detail)
                                        .wkFont(.caption)
                                        .foregroundStyle(WKColor.textTertiary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(WKSpace.lg)
            }
            .background(WKColor.bg)
            .navigationTitle(Copy.Presets.heading)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    SetupView()
        .environment(ProStore())
}
