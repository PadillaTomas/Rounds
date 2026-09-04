import XCTest
@testable import Rounds

final class WorkoutEnergyTests: XCTestCase {

    func testBoxingUsesTheBoxingMET() {
        // 9.3 MET × 70 kg × 0.5 h
        let kcal = WorkoutEnergy.kcal(isBoxing: true, activeSeconds: 1800, bodyMassKg: 70)
        XCTAssertEqual(kcal, 9.3 * 70 * 0.5, accuracy: 0.001)
    }

    func testHiitUsesTheLowerMET() {
        let boxing = WorkoutEnergy.kcal(isBoxing: true, activeSeconds: 1200, bodyMassKg: 80)
        let hiit = WorkoutEnergy.kcal(isBoxing: false, activeSeconds: 1200, bodyMassKg: 80)
        XCTAssertLessThan(hiit, boxing)
    }

    func testZeroDurationBurnsNothing() {
        XCTAssertEqual(WorkoutEnergy.kcal(isBoxing: true, activeSeconds: 0, bodyMassKg: 70), 0)
    }

    func testCachedBodyMassFallsBackToTheDefault() {
        UserDefaults.standard.removeObject(forKey: "rounds.bodyMassKg")
        XCTAssertEqual(WorkoutEnergy.cachedBodyMassKg, WorkoutEnergy.defaultBodyMassKg)
        WorkoutEnergy.cachedBodyMassKg = 82.5
        XCTAssertEqual(WorkoutEnergy.cachedBodyMassKg, 82.5)
        UserDefaults.standard.removeObject(forKey: "rounds.bodyMassKg")
    }
}
