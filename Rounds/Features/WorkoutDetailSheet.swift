import SwiftUI
import UIWorkouts

/// Tap a History row to see the whole workout. Built in the "Ambient Dark"
/// language — a `.done` wash, a mono date eyebrow, one serif headline, then the
/// numbers as stat cards and progress-underlined metric rows (canvas §3, the
/// "Post workout" composition). Reads only the stored ``CompletedActivity``, so
/// it works for every row — Pro or free, online or not.
struct WorkoutDetailSheet: View {
    let activity: CompletedActivity
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            WKAmbientBackground(.done)

            ScrollView {
                VStack(alignment: .leading, spacing: WKSpace.xl) {
                    header

                    HStack(spacing: WKSpace.md) {
                        WKStatCard(caption: Copy.History.statDuration,
                                   value: WKTimeFormat.clock(activity.elapsedSeconds))
                        WKStatCard(caption: Copy.History.statEnergy, value: energyValue)
                    }

                    WKCard {
                        VStack(spacing: WKSpace.lg) {
                            WKMetricRow(title: Copy.History.statRounds,
                                        value: roundsValue,
                                        fraction: roundsFraction)
                            if let effort = activity.effortRating {
                                let f = Double(effort) / 10
                                WKMetricRow(title: Copy.History.statEffort,
                                            value: Copy.History.effortValue(effort),
                                            fraction: f,
                                            tint: WKRamp.stop(at: f))
                            }
                            WKMetricRow(title: Copy.History.statRoundLength,
                                        value: WKTimeFormat.clock(activity.roundSeconds))
                            WKMetricRow(title: Copy.History.statRestLength,
                                        value: WKTimeFormat.clock(activity.restSeconds))
                        }
                    }
                }
                .padding(WKSpace.lg)
                .padding(.top, WKSpace.xl)
            }
        }
        .presentationBackground(WKColor.bg)
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: WKSpace.sm) {
            WKLabelMono(activity.startedAt.formatted(.dateTime.month().day().hour().minute()))
            Text(roundsValue)
                .wkFont(.displayM)
                .foregroundStyle(WKColor.textPrimary)
            Text(Copy.History.timing(WKTimeFormat.clock(activity.roundSeconds),
                                     WKTimeFormat.clock(activity.restSeconds)))
                .wkFont(.body)
                .foregroundStyle(WKColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var energyValue: String {
        guard let kcal = activity.activeEnergyKcal, kcal >= 1 else { return "—" }
        return Copy.History.kcalValue(Int(kcal.rounded()))
    }

    private var roundsValue: String {
        if activity.isNonStop || activity.completedRounds >= activity.plannedRounds {
            return Copy.History.roundsCount(activity.completedRounds)
        }
        return Copy.History.roundsOf(activity.completedRounds, activity.plannedRounds)
    }

    /// Underline only when there's a target to be a fraction of.
    private var roundsFraction: Double? {
        guard !activity.isNonStop, activity.plannedRounds > 0 else { return nil }
        return Double(activity.completedRounds) / Double(activity.plannedRounds)
    }
}

#if DEBUG
#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        WorkoutDetailSheet(activity: CompletedActivity(
            startedAt: .now, elapsedSeconds: 1980, completedRounds: 12,
            plannedRounds: 12, roundSeconds: 180, restSeconds: 60,
            sourceName: "Full Card", effortRating: 7, activeEnergyKcal: 226))
    }
}
#endif
