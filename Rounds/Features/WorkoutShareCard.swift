import SwiftUI
import UIWorkouts

/// The square image a user shares from a finished workout — the design canvas's
/// "4B Effort arc" composition, assembled from stock UIWorkouts parts: a
/// ``WKArcGauge`` placing perceived effort on the cool→hot ramp, the serif rounds
/// line, phase-timing chips, and two ``WKStatCard`` tiles. Ambient Dark, forced
/// dark. Never shown on screen — ``rendered(scale:)`` hands a `UIImage` to the
/// share sheet.
///
/// Rendered in the app's current appearance — the caller passes its resolved
/// `colorScheme` to ``rendered(scale:colorScheme:)``. Older records carry no
/// effort rating; the arc is dropped for those and the rounds line carries the
/// card on its own.
struct WorkoutShareCard: View {
    let activity: CompletedActivity

    /// Base point size; `ImageRenderer` scales this to pixels. 540 × scale 2 =
    /// a 1080 px square — the canvas's export size, and the ratio at which the
    /// fixed `WK` type scale matches the canvas proportions.
    static let side: CGFloat = 540

    var body: some View {
        ZStack(alignment: .top) {
            WKColor.bg
            WKAmbientBackground(.done, height: Self.side * 0.52)

            VStack(spacing: WKSpace.lg) {
                header

                if let effort = activity.effortRating {
                    // Position on the 1…10 scale, for the ramp tint.
                    let position = Double(effort - 1) / 9
                    VStack(spacing: WKSpace.xs) {
                        WKArcGauge(value: effort,
                                   in: 1...10,
                                   caption: Copy.History.statEffort,
                                   tint: WKRamp.stop(at: position))
                        Text(Copy.History.effortWord(effort))
                            .wkFont(.labelMono)
                            .foregroundStyle(WKRamp.stop(at: position))
                    }
                }

                VStack(spacing: WKSpace.md) {
                    Text(Copy.History.rounds(activity.roundsSummary))
                        .wkFont(.displayL)
                        .foregroundStyle(WKColor.textPrimary)
                    HStack(spacing: WKSpace.sm) {
                        WKStatChip(Copy.History.workChip(WKTimeFormat.clock(activity.roundSeconds)),
                                   tone: .run)
                        WKStatChip(Copy.History.restChip(WKTimeFormat.clock(activity.restSeconds)),
                                   tone: .walk)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: WKSpace.md) {
                    WKStatCard(caption: Copy.History.statDuration,
                               value: WKTimeFormat.clock(activity.elapsedSeconds))
                    WKStatCard(caption: Copy.History.statEnergy, value: energyValue)
                }
            }
            .padding(WKSpace.xl)
        }
        .frame(width: Self.side, height: Self.side)
        .background(WKColor.bg)
    }

    private var header: some View {
        HStack {
            Text(Copy.brand)
                .wkFont(.labelMono)
                .foregroundStyle(WKColor.textSecondary)
            Spacer()
            Text(WKTimeFormat.calendarDate(activity.startedAt, showsWeekday: false))
                .wkFont(.labelMono)
                .foregroundStyle(WKColor.textTertiary)
        }
    }

    private var energyValue: String {
        guard let kcal = activity.activeEnergyKcal, kcal >= 1 else { return "—" }
        return Copy.History.kcalValue(Int(kcal.rounded()))
    }
}

extension WorkoutShareCard {
    /// Render to a `UIImage` on the main actor, in the given appearance. `scale`
    /// 2 → a 1080 px square. `ImageRenderer` resolves the `WK` tokens against the
    /// `colorScheme` passed here (iOS 17+).
    @MainActor
    func rendered(scale: CGFloat = 2, colorScheme: ColorScheme) -> UIImage? {
        let renderer = ImageRenderer(content: environment(\.colorScheme, colorScheme))
        renderer.scale = scale
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

#if DEBUG
#Preview {
    WorkoutShareCard(activity: CompletedActivity(
        startedAt: .now, elapsedSeconds: 1980, completedRounds: 8,
        plannedRounds: 12, roundSeconds: 180, restSeconds: 60,
        sourceName: "Full Card", effortRating: 6, activeEnergyKcal: 226))
    .clipShape(RoundedRectangle(cornerRadius: WKRadius.card))
    .padding()
}
#endif
