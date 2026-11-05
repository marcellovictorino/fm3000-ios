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

/// INF-2101 / INF-2291: pixel proof launches the disposable app; keep it outside the clock-only --waits selection.
/// The ordinary rest part still runs every test here, including the exact native references.
@MainActor final class PhoneTargetPixelsTests: XCTestCase {
    func testCaptureExtentMatchesTheRecordedNativeAllocator() {
        // INF-2101 / INF-2251: these inputs and outputs were executed through iOS 27's native buffer callback
        // and allocator. Retaining an even integer-part fraction is not the same as always rounding down to even.
        let readings: [(CGFloat, CGFloat)] = [(235.9999999999999, 234), (236.00000000000023, 236),
                                              (234.25, 234), (234.75, 235), (235, 234), (236, 236), (237, 236)]
        for (pixels, allocated) in readings {
            XCTAssertEqual(phoneCaptureExtent(pixels), allocated, "Native allocation for \(pixels)")
        }
    }

    func testRecordedFramesCropInNativeCoordinatesBeforeRotating() {
        // INF-2101 / INF-2251: actual failing-run frames and byte-exact reference locations, not rounded printouts.
        let backing = CGSize(width: 1178, height: 2556)
        let portrait = CGRect(x: 24, y: 539.3333333333333, width: 345, height: 78.66666666666674)
        XCTAssertEqual(phoneTargetCrop(frame: portrait, screen: CGRect(x: 0, y: 0, width: 393, height: 852),
                                       scale: 3, orientation: .up, backing: backing),
                       CGRect(x: 72, y: 1618, width: 1034, height: 236))
        let landscape = CGRect(x: 216, y: 166.66666666666663, width: 420, height: 78.66666666666663)
        XCTAssertEqual(phoneTargetCrop(frame: landscape, screen: CGRect(x: 0, y: 0, width: 852, height: 393),
                                       scale: 3, orientation: .left, backing: backing),
                       CGRect(x: 443, y: 648, width: 234, height: 1260))
        // INF-2251's live transform retained this fractional origin; an integer crop cannot stand in for it.
        let subpixel = CGRect(x: 147.75, y: 216.125, width: 78.66666666666663, height: 420)
        let screen = CGRect(x: 0, y: 0, width: 393, height: 852)
        XCTAssertNil(phoneTargetCrop(frame: subpixel, screen: screen, scale: 3, orientation: .up, backing: backing))
        // INF-2291: the same recorded unsupported origin must go straight to native capture, not capture twice.
        var displays = 0, natives = 0
        XCTAssertNil(phoneTargetPixels({ displays += 1; return XCUIScreen.main.screenshot().image },
                                      frame: subpixel, screen: screen, scale: 3,
                                      native: { natives += 1; return nil }))
        XCTAssertEqual(displays, 0)
        XCTAssertEqual(natives, 1)
    }

    /// INF-2101: removing repeated screenshot queries must retain the target's actual pixels in both orientations.
    /// Real native controls, not drawn stand-ins: XCTest's own element picture is the independent reference.
    func testTargetPixelsMatchXCTestWithoutResolvingTheTargetAgain() async throws {
        continueAfterFailure = false
        PhoneFailures.watch()
        try skipPhoneAnimationWait()
        let app = XCUIApplication()
        app.launchEnvironment["INFINITARY_ISOLATED_PHONE_TEST"] = "1"
        XCUIDevice.shared.orientation = .portrait
        try await launchPhoneApp(app)
        defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        let paste = app.buttons["paste-link"]
        // INF-2101: rest's preceding journey may have joined this disposable app. Launching preserves that join;
        // establish our own welcome fixture through its ordinary Leave action, without changing test order or data owners.
        let computer = app.buttons["computer-details"]
        XCTAssertEqual(waitForPhonePredicate(NSPredicate { _, _ in paste.exists || computer.exists },
                                            object: app, timeout: 10), .completed, app.debugDescription)
        if computer.exists {
            tapOnPhone(computer)
            let leave = app.buttons["leave"]
            XCTAssertTrue(leave.waitForPresence(timeout: 10), app.debugDescription)
            tapOnPhone(leave)
            let confirm = app.buttons["confirm-leave"].firstMatch
            XCTAssertTrue(confirm.waitForPresence(timeout: 10), app.debugDescription)
            tapOnPhone(confirm)
        }
        XCTAssertTrue(paste.waitForPresence(timeout: 10), app.debugDescription)

        func pixels(_ image: UIImage) throws -> Data {
            let cgImage = try XCTUnwrap(image.cgImage)
            var bytes = Data(count: cgImage.width * cgImage.height * 4)
            try bytes.withUnsafeMutableBytes { buffer in
                let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: cgImage.width, height: cgImage.height,
                    bitsPerComponent: 8, bytesPerRow: cgImage.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
            }
            return bytes
        }

        func upright(_ image: UIImage) -> UIImage {
            guard image.imageOrientation != .up else { return image }
            let format = UIGraphicsImageRendererFormat()
            format.scale = image.scale
            return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: image.size))
            }
        }

        func check(_ target: XCUIElement, _ name: String) throws {
            waitForSteadyTarget(target)
            let screen = app.frame, frame = try target.snapshot().frame
            let display = XCUIScreen.main.screenshot()
            let keptDisplay = XCTAttachment(screenshot: display)
            keptDisplay.name = "target-pixels-\(name)-display"; keptDisplay.lifetime = .keepAlways; add(keptDisplay)
            print("Target pixel frame \(name): frame=\(frame), screen=\(screen)")
            XCTAssertTrue(screen.contains(frame), "The reference target must be entirely visible before comparing its pixels")
            let cropped = try XCTUnwrap(phoneTargetPixels({ display.image }, frame: frame, screen: screen, scale: display.image.scale))
            let actual = try XCTUnwrap(UIImage(data: cropped))
            let native = target.screenshot().image
            let reference = upright(native)
            print("Target pixel inputs \(name): frame=\(frame), screen=\(screen), display=\(display.image.size) scale=\(display.image.scale) orientation=\(display.image.imageOrientation.rawValue), native=\(native.size) scale=\(native.scale) orientation=\(native.imageOrientation.rawValue), crop=\(actual.size)")
            for (label, image) in [("crop", actual), ("reference", reference)] {
                let kept = XCTAttachment(image: image)
                kept.name = "target-pixels-\(name)-\(label)"; kept.lifetime = .keepAlways; add(kept)
            }
            XCTAssertEqual(actual.cgImage?.width, reference.cgImage?.width, name)
            XCTAssertEqual(actual.cgImage?.height, reference.cgImage?.height, name)
            XCTAssertEqual(try pixels(actual), try pixels(reference), "\(name): the screen crop is the same picture as XCTest's target crop")
            XCTAssertNil(phoneTargetPixels({ XCTFail("An off-screen target must not capture the display"); return display.image },
                                           frame: frame.offsetBy(dx: screen.maxX, dy: screen.maxY), screen: screen, scale: display.image.scale),
                         "An off-screen target supplies no pixels")
            print("Target pixel reference \(name): matched")
        }

        try check(paste, "portrait")
        turnPhone(to: .landscapeLeft, in: app, moving: paste)
        // On iPhone the welcome page's buttons are below the landscape viewport. Reveal the real target first;
        // an off-screen frame correctly supplies no crop and cannot be a visible-pixel reference.
        if !app.frame.contains(try paste.snapshot().frame) { app.scrollViews.firstMatch.swipeUp() }
        try check(paste, "landscape")
        // Go through portrait so turnPhone's moved-frame observation still witnesses each rotation.
        turnPhone(to: .portrait, in: app, moving: paste)
        turnPhone(to: .landscapeRight, in: app, moving: paste)
        if !app.frame.contains(try paste.snapshot().frame) { app.scrollViews.firstMatch.swipeUp() }
        try check(paste, "landscape-right")
        turnPhone(to: .portrait, in: app, moving: paste)
        tapOnPhone(paste)
        let link = app.textFields["join-link"]
        XCTAssertTrue(link.waitForPresence(timeout: 10))
        try check(link, "sheet")
    }
}
