import XCTest

/// INF-1083's approved phone half: real files exercise the same owner as every UI observation.
/// No app, provider account or external resource. These tests ride with the existing rest part.
@MainActor final class PhoneWaitsTests: XCTestCase {
    func testDelayedFileSurvivesAStallOnlyWhenNotGrading() throws {
        let flag = try XCTUnwrap(ProcessInfo.processInfo.environment["INFINITARY_PERF_BUDGETS"])
        XCTAssertTrue(["0", "1"].contains(flag), "The launcher must pass its budget reading")
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        // INF-1396: the writer is its own thread, never a task. While every shared task thread is
        // busy, a detached task's write waits past the whole wall cap and the reader never sees it.
        let written = DispatchSemaphore(value: 0)
        let writer = Thread {
            Thread.sleep(forTimeInterval: 0.2)
            try? Data("work completed".utf8).write(to: file)
            written.signal()
        }
        writer.qualityOfService = .userInteractive
        writer.start()
        var first = true
        let observed = waitForPhonePredicate(NSPredicate { _, _ in
            if first {
                first = false
                // A real stalled reader, not extra headroom: the writer continues during the stall,
                // and the stall ends only once the write has finished, never by racing two sleeps.
                Thread.sleep(forTimeInterval: 0.3)
                written.wait()
                return false
            }
            return FileManager.default.fileExists(atPath: file.path)
        }, object: file as NSURL, timeout: 0.1)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "work completed")
        XCTAssertEqual(observed, flag == "1" ? .timedOut : .completed)
        print("Delayed native completion file: grades=\(flag), result=\(observed)")
    }

    func testMissingWorkReachesItsFailureDeadline() {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let started = ProcessInfo.processInfo.systemUptime
        let budget: TimeInterval = 0.1
        let result = waitForPhonePredicate(NSPredicate { _, _ in
            FileManager.default.fileExists(atPath: file.path)
        }, object: file as NSURL, timeout: budget)
        let elapsed = ProcessInfo.processInfo.systemUptime - started
        XCTAssertEqual(result, .timedOut, "Missing work must fail without external cancellation")
        // One polling turn of scheduling tolerance; whole-test timeouts remain enabled too.
        XCTAssertLessThanOrEqual(elapsed, phoneRequestBudget(budget) + 0.3)
        print("Missing native completion file: result=\(result), wall=\(elapsed)s, cap=\(phoneRequestBudget(budget))s")
    }

    func testFrozenClockStillExpiresAtTheWallCap() {
        let budget: TimeInterval = 0.1
        var clock = PhoneWaitDeadline(budget, graded: false)
        Thread.sleep(forTimeInterval: phoneRequestBudget(budget))
        // The stall counts at most two ticks, but the independent wall cap has expired.
        XCTAssertTrue(clock.expired())
        XCTAssertEqual(phoneRequestBudget(60), 600, "Long waits keep the approved ten-minute cap")
    }

    func testFormReadinessUsesEveryObservedNamedAnswer() {
        // INF-1122: actual Cards accessibility readings, including note and staged chart.
        let complete = NSPredicate(format: "SELF MATCHES %@", phoneAnsweredFormPattern)
        XCTAssertTrue(complete.evaluate(with: "3 of 3 picked"))
        XCTAssertTrue(complete.evaluate(with: "3 of 3 picked · 1 changed"))
        XCTAssertTrue(complete.evaluate(with: "3 of 3 answered"))
        XCTAssertFalse(complete.evaluate(with: "2 of 3 picked"))
        XCTAssertFalse(complete.evaluate(with: "2 of 3 answered"))
        XCTAssertFalse(complete.evaluate(with: "0 of 0 picked"))
    }

    func testSteadyReadingNeedsTwoEqualReadsOfAFoundTarget() {
        // INF-1541 piece 1 (the captain's choice "checks each target itself"): a tap waits until its target reads the
        // same twice. The frame is INF-1399's recorded crewmate target, then that target a point and a half on.
        let target = CGRect(x: 372.6666666666667, y: 392, width: 44, height: 44)
        var steady = PhoneSteadyReading<CGRect>()
        XCTAssertFalse(steady.read(nil))
        XCTAssertFalse(steady.read(nil), "A target never found never holds still")
        XCTAssertFalse(steady.read(target), "One read is not two")
        XCTAssertFalse(steady.read(target.offsetBy(dx: -1.5, dy: 0)), "A moving target is not steady")
        XCTAssertTrue(steady.read(target.offsetBy(dx: -1.5, dy: 0)))
        XCTAssertFalse(steady.read(nil), "A target that left is not steady")
    }

    func testImmediatePredicateIsReadDirectly() {
        // INF-975: a sub-second observation must actually evaluate the predicate.
        XCTAssertEqual(waitForPhonePredicate(NSPredicate { _, _ in true }, object: self, timeout: 0.001), .completed)
    }
}
