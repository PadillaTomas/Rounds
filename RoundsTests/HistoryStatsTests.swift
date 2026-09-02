import XCTest
@testable import Rounds

final class HistoryStatsTests: XCTestCase {

    private func activity(daysAgo: Double, rounds: Int, planned: Int = 12) -> CompletedActivity {
        CompletedActivity(startedAt: .now.addingTimeInterval(-daysAgo * 86_400),
                          elapsedSeconds: rounds * 240,
                          completedRounds: rounds,
                          plannedRounds: planned,
                          roundSeconds: 180, restSeconds: 60)
    }

    func testTotalsSumCompletedRounds() {
        let stats = HistoryStats([activity(daysAgo: 0, rounds: 12),
                                  activity(daysAgo: 10, rounds: 8)])
        XCTAssertEqual(stats.totalWorkouts, 2)
        XCTAssertEqual(stats.totalRounds, 20)
    }

    func testThisWeekCountsOnlyActivitiesSinceTheWeekStart() {
        // A Wednesday, so "this week" (Mon-start locales) reaches back ~2 days.
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let now = cal.date(from: DateComponents(year: 2026, month: 9, day: 2, hour: 12))!
        let acts = [
            CompletedActivity(startedAt: now.addingTimeInterval(-1 * 3600), elapsedSeconds: 0,
                              completedRounds: 5, plannedRounds: 5, roundSeconds: 180, restSeconds: 60),
            CompletedActivity(startedAt: now.addingTimeInterval(-5 * 86_400), elapsedSeconds: 0,
                              completedRounds: 9, plannedRounds: 12, roundSeconds: 180, restSeconds: 60),
        ]
        let stats = HistoryStats(acts, now: now, calendar: cal)
        XCTAssertEqual(stats.workoutsThisWeek, 1)
        XCTAssertEqual(stats.totalWorkouts, 2)
        XCTAssertEqual(stats.totalRounds, 14)
    }

    func testEmpty() {
        let stats = HistoryStats([])
        XCTAssertEqual(stats.workoutsThisWeek, 0)
        XCTAssertEqual(stats.totalRounds, 0)
    }

    func testNonStopFlag() {
        XCTAssertTrue(activity(daysAgo: 0, rounds: 4, planned: 0).isNonStop)
        XCTAssertFalse(activity(daysAgo: 0, rounds: 4, planned: 12).isNonStop)
    }
}
