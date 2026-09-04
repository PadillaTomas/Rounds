import XCTest
@testable import Rounds

final class FreeWorkoutStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "rounds.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultsAreThreeMinuteRoundsOneMinuteRestTwelveRounds() {
        XCTAssertEqual(FreeWorkoutStore.defaultRounds, 12)
        XCTAssertEqual(FreeWorkoutStore.defaultRoundSeconds, 180)
        XCTAssertEqual(FreeWorkoutStore.defaultRestSeconds, 60)
    }

    func testClampToMinimumsRaisesStaleSubMinimumValues() {
        defaults.set(3, forKey: FreeWorkoutStore.roundSecondsKey)
        defaults.set(1, forKey: FreeWorkoutStore.restSecondsKey)

        FreeWorkoutStore.clampToMinimums(defaults)

        XCTAssertEqual(defaults.integer(forKey: FreeWorkoutStore.roundSecondsKey),
                       RoundsActivity.minRoundSeconds)
        XCTAssertEqual(defaults.integer(forKey: FreeWorkoutStore.restSecondsKey),
                       RoundsActivity.minRestSeconds)
    }

    func testClampToMinimumsLeavesValidValuesAlone() {
        defaults.set(45, forKey: FreeWorkoutStore.roundSecondsKey)
        defaults.set(20, forKey: FreeWorkoutStore.restSecondsKey)

        FreeWorkoutStore.clampToMinimums(defaults)

        XCTAssertEqual(defaults.integer(forKey: FreeWorkoutStore.roundSecondsKey), 45)
        XCTAssertEqual(defaults.integer(forKey: FreeWorkoutStore.restSecondsKey), 20)
    }
}
