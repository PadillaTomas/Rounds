import XCTest
@testable import Rounds

final class CompletedActivityTests: XCTestCase {

    private func activity(completed: Int, planned: Int) -> CompletedActivity {
        CompletedActivity(startedAt: .now, elapsedSeconds: 600,
                          completedRounds: completed, plannedRounds: planned,
                          roundSeconds: 180, restSeconds: 60)
    }

    func testFinishedPlanReadsAsTheFullTotal() {
        XCTAssertEqual(activity(completed: 12, planned: 12).roundsSummary, .total(12))
    }

    func testOvershootClampsToThePlannedCount() {
        // completedRounds should never exceed planned, but if it does, don't
        // surface "13 of 12".
        XCTAssertEqual(activity(completed: 13, planned: 12).roundsSummary, .total(12))
    }

    func testStoppedEarlyReadsAsDoneOfPlanned() {
        XCTAssertEqual(activity(completed: 8, planned: 12).roundsSummary,
                       .partial(done: 8, planned: 12))
    }

    func testNonStopReadsAsWhateverWasDone() {
        XCTAssertEqual(activity(completed: 5, planned: 0).roundsSummary, .total(5))
        XCTAssertEqual(activity(completed: 0, planned: 0).roundsSummary, .total(0))
    }
}
