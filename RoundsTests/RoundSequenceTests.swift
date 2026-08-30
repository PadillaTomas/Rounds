import XCTest
@testable import Rounds

final class RoundSequenceTests: XCTestCase {

    /// 2 rounds, 10 s work, 5 s rest → cycle 15, finishes at elapsed 25.
    /// (10 / 5 are the model's minimums, so nothing gets floored.)
    private let twoRounds = RoundSequence(activity: RoundsActivity(
        mode: .free, freeRounds: 2, freeRoundSeconds: 10, freeRestSeconds: 5))

    // MARK: tick

    func testWorkThenRestThenWork() {
        XCTAssertEqual(twoRounds.tick(atElapsed: 0),
                       .init(round: 1, phase: .work, remaining: 10, isFinished: false))
        XCTAssertEqual(twoRounds.tick(atElapsed: 9),
                       .init(round: 1, phase: .work, remaining: 1, isFinished: false))
        XCTAssertEqual(twoRounds.tick(atElapsed: 10),
                       .init(round: 1, phase: .rest, remaining: 5, isFinished: false))
        XCTAssertEqual(twoRounds.tick(atElapsed: 15),
                       .init(round: 2, phase: .work, remaining: 10, isFinished: false))
    }

    func testFinishesAfterTheLastWorkPeriodWithNoTrailingRest() {
        XCTAssertFalse(twoRounds.tick(atElapsed: 24).isFinished)
        XCTAssertTrue(twoRounds.tick(atElapsed: 25).isFinished)
        XCTAssertTrue(twoRounds.tick(atElapsed: 999).isFinished)
    }

    func testNegativeElapsedClampsToStart() {
        XCTAssertEqual(twoRounds.tick(atElapsed: -10).remaining, 10)
    }

    // MARK: cues

    func testBellsAtEveryBoundary() {
        XCTAssertEqual(twoRounds.cue(onCrossing: 0), .roundStart)   // first bell
        XCTAssertEqual(twoRounds.cue(onCrossing: 10), .roundEnd)    // round 1 work ends
        XCTAssertEqual(twoRounds.cue(onCrossing: 15), .roundStart)  // round 2 begins
        XCTAssertEqual(twoRounds.cue(onCrossing: 25), .fightEnd)    // last round ends
    }

    func testNoCueMidPhase() {
        XCTAssertNil(twoRounds.cue(onCrossing: 3))
        XCTAssertNil(twoRounds.cue(onCrossing: 7))
        XCTAssertNil(twoRounds.cue(onCrossing: 12))
        XCTAssertNil(twoRounds.cue(onCrossing: 20))
    }

    func testTenSecondWarningOnlyWhenTheRoundIsLongerThanTenSeconds() {
        let long = RoundSequence(activity: RoundsActivity(
            mode: .free, freeRounds: 1, freeRoundSeconds: 15, freeRestSeconds: 5))
        XCTAssertEqual(long.cue(onCrossing: 5), .tenSecondWarning)  // 10 s left
        XCTAssertEqual(long.cue(onCrossing: 15), .fightEnd)

        // 10 s round: no second in it ever has "10 s remaining" past the start bell.
        for second in 0...10 {
            XCTAssertNotEqual(twoRounds.cue(onCrossing: second), .tenSecondWarning)
        }
    }

    // MARK: unbounded

    func testInfiniteWorkoutNeverFinishesAndKeepsCountingRounds() {
        let free = RoundSequence(activity: RoundsActivity(
            mode: .free, freeRounds: 0, freeRoundSeconds: 10, freeRestSeconds: 5))
        XCTAssertNil(free.totalRounds)
        XCTAssertEqual(free.tick(atElapsed: 15).round, 2)
        XCTAssertEqual(free.tick(atElapsed: 30).round, 3)
        XCTAssertFalse(free.tick(atElapsed: 10_000).isFinished)
        XCTAssertEqual(free.cue(onCrossing: 15), .roundStart)
        XCTAssertEqual(free.cue(onCrossing: 10), .roundEnd)
    }
}
