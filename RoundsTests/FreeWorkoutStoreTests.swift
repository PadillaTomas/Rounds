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

    func testSavingIsOnByDefaultWhenTheKeyIsAbsent() {
        XCTAssertTrue(FreeWorkoutStore.isSaving(defaults))
    }

    func testSavingOnKeepsStoredValues() {
        defaults.set(true, forKey: FreeWorkoutStore.saveKey)
        defaults.set(5, forKey: FreeWorkoutStore.roundsKey)
        defaults.set(90, forKey: FreeWorkoutStore.roundSecondsKey)

        FreeWorkoutStore.resetIfNotSaving(defaults)

        XCTAssertEqual(defaults.integer(forKey: FreeWorkoutStore.roundsKey), 5)
        XCTAssertEqual(defaults.integer(forKey: FreeWorkoutStore.roundSecondsKey), 90)
    }

    func testSavingOffRestoresTheDefaults() {
        defaults.set(false, forKey: FreeWorkoutStore.saveKey)
        defaults.set(5, forKey: FreeWorkoutStore.roundsKey)
        defaults.set(90, forKey: FreeWorkoutStore.roundSecondsKey)
        defaults.set(20, forKey: FreeWorkoutStore.restSecondsKey)

        FreeWorkoutStore.resetIfNotSaving(defaults)

        XCTAssertEqual(defaults.integer(forKey: FreeWorkoutStore.roundsKey),
                       FreeWorkoutStore.defaultRounds)
        XCTAssertEqual(defaults.integer(forKey: FreeWorkoutStore.roundSecondsKey),
                       FreeWorkoutStore.defaultRoundSeconds)
        XCTAssertEqual(defaults.integer(forKey: FreeWorkoutStore.restSecondsKey),
                       FreeWorkoutStore.defaultRestSeconds)
    }

    func testDefaultsAreThreeMinuteRoundsOneMinuteRestTwelveRounds() {
        XCTAssertEqual(FreeWorkoutStore.defaultRounds, 12)
        XCTAssertEqual(FreeWorkoutStore.defaultRoundSeconds, 180)
        XCTAssertEqual(FreeWorkoutStore.defaultRestSeconds, 60)
    }
}
