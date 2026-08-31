import XCTest
@testable import Rounds

/// Records every cue the engine fires, in order.
private final class CueSpy: CuePlaying {
    private(set) var log: [String] = []
    func roundStarted()     { log.append("start") }
    func roundEnded()       { log.append("end") }
    func tenSecondWarning() { log.append("warn") }
    func sessionFinished()  { log.append("final") }
    func sessionDidBegin()  { log.append("begin") }
    func sessionDidEnd()    { log.append("didEnd") }
}

final class RoundTimerEngineTests: XCTestCase {

    /// 2 rounds, 10 s work, 5 s rest (the model minimums, so nothing floors).
    private func makeEngine(_ activity: RoundsActivity = RoundsActivity(
        rounds: 2, configuredRoundSeconds: 10, configuredRestSeconds: 5
    )) -> (RoundTimerEngine, CueSpy, () -> Void, (TimeInterval) -> Void) {
        var clock = Date(timeIntervalSince1970: 1_000)
        let spy = CueSpy()
        let engine = RoundTimerEngine(activity: activity, cues: spy, now: { clock })
        let advance: () -> Void = { engine.advance() }
        let tickForward: (TimeInterval) -> Void = { clock = clock.addingTimeInterval($0) }
        return (engine, spy, advance, tickForward)
    }

    func testStartRingsTheFirstBell() {
        let (engine, spy, _, _) = makeEngine()
        engine.start()
        XCTAssertEqual(spy.log, ["begin", "start"])
        XCTAssertEqual(engine.round, 1)
        XCTAssertEqual(engine.phase, .work)
        XCTAssertEqual(engine.remaining, 10)
    }

    func testRunsThroughEveryBoundaryInOrder() {
        let (engine, spy, advance, tick) = makeEngine()
        engine.start()

        tick(10); advance()
        XCTAssertEqual(spy.log, ["begin", "start", "end"])
        XCTAssertEqual(engine.phase, .rest)

        tick(5); advance()                       // elapsed 15 → round 2 begins
        XCTAssertEqual(spy.log, ["begin", "start", "end", "start"])
        XCTAssertEqual(engine.round, 2)
        XCTAssertEqual(engine.phase, .work)

        tick(10); advance()                      // elapsed 25 → done
        XCTAssertEqual(spy.log.suffix(2).map { $0 }, ["final", "didEnd"])
        XCTAssertEqual(engine.runState, .finished)
        XCTAssertEqual(engine.remaining, 0)
    }

    func testTenSecondWarningFires() {
        let (engine, spy, advance, tick) = makeEngine(
            RoundsActivity(rounds: 1, configuredRoundSeconds: 15, configuredRestSeconds: 5))
        engine.start()
        tick(5); advance()                       // elapsed 5 → 10 s left
        XCTAssertEqual(spy.log, ["begin", "start", "warn"])
    }

    func testPauseFreezesTheClockAndResumeContinues() {
        let (engine, _, advance, tick) = makeEngine(
            RoundsActivity(rounds: 5, configuredRoundSeconds: 10, configuredRestSeconds: 5))
        engine.start()
        tick(3); advance()
        XCTAssertEqual(engine.remaining, 7)

        engine.togglePause()
        tick(100); advance()                     // guarded no-op while paused
        XCTAssertEqual(engine.remaining, 7)
        XCTAssertEqual(engine.runState, .paused)

        engine.togglePause()                     // resume
        tick(2); advance()
        XCTAssertEqual(engine.remaining, 5)       // 3 + 2 s of work elapsed
        XCTAssertEqual(engine.runState, .running)
    }

    func testStopFinishesWithoutAFinalBellAndIsIdempotent() {
        let (engine, spy, _, _) = makeEngine(
            RoundsActivity(rounds: 5, configuredRoundSeconds: 10, configuredRestSeconds: 5))
        engine.start()
        engine.stop()
        engine.stop()
        XCTAssertEqual(engine.runState, .finished)
        XCTAssertFalse(spy.log.contains("final"))
        XCTAssertEqual(spy.log.filter { $0 == "didEnd" }.count, 1)
    }

    func testFractionProgressesAcrossThePhase() {
        let (engine, _, advance, tick) = makeEngine(
            RoundsActivity(rounds: 3, configuredRoundSeconds: 10, configuredRestSeconds: 5))
        engine.start()
        XCTAssertEqual(engine.fraction, 0, accuracy: 0.001)
        tick(5); advance()
        XCTAssertEqual(engine.fraction, 0.5, accuracy: 0.001)
    }
}
