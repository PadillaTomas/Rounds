import SwiftUI
import SwiftData
import UIWorkouts

/// The third tab: every finished workout, most recent first, with two running
/// totals up top. Records are written by ``RoundTimerView`` — this screen only
/// reads and lets you delete a stray entry.
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CompletedActivity.startedAt, order: .reverse)
    private var activities: [CompletedActivity]

    @State private var pendingDelete: CompletedActivity?
    @State private var detail: CompletedActivity?

    private var stats: HistoryStats { HistoryStats(activities) }

    var body: some View {
        NavigationStack {
            Group {
                if activities.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: WKSpace.lg) {
                        totals
                        WKSectionHeader(Copy.History.recent)
                        ScrollView {
                            VStack(spacing: WKSpace.sm) {
                                ForEach(activities) { activity in
                                    Button { detail = activity } label: {
                                        HistoryRow(activity: activity)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(Copy.History.delete, role: .destructive) {
                                            pendingDelete = activity
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, WKSpace.lg)
                        }
                    }
                    .padding(.horizontal, WKSpace.lg)
                    .padding(.top, WKSpace.lg)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(WKColor.bg)
            .navigationTitle(Copy.History.title)
            .navigationBarTitleDisplayMode(.inline)
            .alert(Copy.History.deleteTitle,
                   isPresented: Binding(get: { pendingDelete != nil },
                                        set: { if !$0 { pendingDelete = nil } })) {
                Button(Copy.Common.cancel, role: .cancel) { pendingDelete = nil }
                Button(Copy.History.delete, role: .destructive) {
                    if let pendingDelete { modelContext.delete(pendingDelete) }
                    pendingDelete = nil
                }
            } message: {
                Text(Copy.History.deleteMessage)
            }
            .sheet(item: $detail) { activity in
                WorkoutDetailSheet(activity: activity)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var totals: some View {
        HStack(spacing: WKSpace.md) {
            WKStatCard(caption: Copy.History.thisWeek, value: "\(stats.workoutsThisWeek)")
            WKStatCard(caption: Copy.History.totalRounds, value: "\(stats.totalRounds)")
        }
    }

    private var emptyState: some View {
        VStack(spacing: WKSpace.sm) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(WKColor.textTertiary)
            Text(Copy.History.empty)
                .wkFont(.callout)
                .foregroundStyle(WKColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(WKSpace.xl)
    }
}

/// One activity, as a two-line card: date + total time on top, the rounds/timing
/// line below. Every workout is hand-dialled for now, so the date is the heading.
private struct HistoryRow: View {
    let activity: CompletedActivity

    var body: some View {
        WKCard {
            VStack(alignment: .leading, spacing: WKSpace.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(activity.startedAt.formatted(.dateTime.weekday().month().day().hour().minute()))
                        .wkFont(.callout)
                        .foregroundStyle(WKColor.textPrimary)
                    Spacer(minLength: WKSpace.sm)
                    Text(WKTimeFormat.clock(activity.elapsedSeconds))
                        .wkFont(.labelMono)
                        .foregroundStyle(WKColor.textSecondary)
                }
                Text(roundsLine)
                    .wkFont(.caption)
                    .foregroundStyle(WKColor.textTertiary)
            }
        }
    }

    private var roundsLine: String {
        let rounds: String
        if activity.isNonStop {
            rounds = "\(Copy.Setup.infinite) · \(Copy.History.roundsCount(activity.completedRounds))"
        } else if activity.completedRounds >= activity.plannedRounds {
            rounds = Copy.History.roundsCount(activity.plannedRounds)
        } else {
            rounds = Copy.History.roundsOf(activity.completedRounds, activity.plannedRounds)
        }
        return Copy.History.line(rounds,
                                 WKTimeFormat.clock(activity.roundSeconds),
                                 WKTimeFormat.clock(activity.restSeconds))
    }
}

#if DEBUG
#Preview {
    HistoryView()
        .modelContainer(RoundsStore.preview)
}
#endif
