import XCTest
@testable import Rounds

final class RoundsActivityTests: XCTestCase {

    func testFullCardPresetIsTwelveThreeMinuteRounds() {
        let p = WorkoutPreset.fullCard
        let card = RoundsActivity(rounds: p.rounds,
                                  configuredRoundSeconds: p.roundSeconds,
                                  configuredRestSeconds: p.restSeconds)
        XCTAssertEqual(card.totalRounds, 12)
        XCTAssertEqual(card.roundSeconds, 180)
        XCTAssertEqual(card.restSeconds, 60)
    }

    func testUsesItsOwnValues() {
        let free = RoundsActivity(rounds: 5,
                                  configuredRoundSeconds: 45, configuredRestSeconds: 35)
        XCTAssertEqual(free.totalRounds, 5)
        XCTAssertEqual(free.roundSeconds, 45)
        XCTAssertEqual(free.restSeconds, 35)
    }

    func testFreeRoundsZeroMeansUnbounded() {
        let free = RoundsActivity(rounds: 0,
                                  configuredRoundSeconds: 45, configuredRestSeconds: 35)
        XCTAssertNil(free.totalRounds)
    }

    func testDegenerateDurationsAreFlooredToTheMinimums() {
        let free = RoundsActivity(rounds: 3,
                                  configuredRoundSeconds: 3, configuredRestSeconds: 1)
        XCTAssertEqual(free.roundSeconds, RoundsActivity.minRoundSeconds)
        XCTAssertEqual(free.restSeconds, RoundsActivity.minRestSeconds)
    }

    func testActivePresetMatchingIsExact() {
        let p = WorkoutPreset.fullCard
        XCTAssertTrue(p.matches(rounds: 12, roundSeconds: 180, restSeconds: 60))
        XCTAssertFalse(p.matches(rounds: 12, roundSeconds: 180, restSeconds: 45))
    }
}
