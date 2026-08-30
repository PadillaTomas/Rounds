import XCTest
@testable import Rounds

final class RoundsActivityTests: XCTestCase {

    func testFullCardIsAFixedTwelveThreeMinuteRounds() {
        let card = RoundsActivity(mode: .fullCard, freeRounds: 99,
                                  freeRoundSeconds: 10, freeRestSeconds: 10)
        XCTAssertEqual(card.totalRounds, 12)
        XCTAssertEqual(card.roundSeconds, 180)
        XCTAssertEqual(card.restSeconds, 60)
    }

    func testFreeUsesItsOwnValues() {
        let free = RoundsActivity(mode: .free, freeRounds: 5,
                                  freeRoundSeconds: 45, freeRestSeconds: 35)
        XCTAssertEqual(free.totalRounds, 5)
        XCTAssertEqual(free.roundSeconds, 45)
        XCTAssertEqual(free.restSeconds, 35)
    }

    func testFreeRoundsZeroMeansUnbounded() {
        let free = RoundsActivity(mode: .free, freeRounds: 0,
                                  freeRoundSeconds: 45, freeRestSeconds: 35)
        XCTAssertNil(free.totalRounds)
    }

    func testDegenerateFreeDurationsAreFloored() {
        let free = RoundsActivity(mode: .free, freeRounds: 3,
                                  freeRoundSeconds: 0, freeRestSeconds: 0)
        XCTAssertEqual(free.roundSeconds, 10)
        XCTAssertEqual(free.restSeconds, 5)
    }

    func testModeRawValueRoundTrips() {
        for mode in RoundsMode.allCases {
            XCTAssertEqual(RoundsMode(rawValue: mode.rawValue), mode)
        }
    }
}
