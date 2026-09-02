import Foundation

/// The handful of totals the History screen shows above the list. Pure — takes a
/// slice of activities and a clock, so it's unit-tested without a store.
struct HistoryStats {
    var workoutsThisWeek: Int
    var totalWorkouts: Int
    var totalRounds: Int

    init(_ activities: [CompletedActivity],
         now: Date = .now,
         calendar: Calendar = .current) {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        workoutsThisWeek = activities.filter { $0.startedAt >= weekStart }.count
        totalWorkouts = activities.count
        totalRounds = activities.reduce(0) { $0 + $1.completedRounds }
    }
}
