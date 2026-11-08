import XCTest

/// The join-read part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2125 direction C, the first of the join tests split from testJoinAndRecover: a wrong Mac, joining and reading.
    /// Data: the disposable home's join note and a review finding. Completion: the phone reads both cards and its own
    /// sheets, keeps the strip at the largest type, and keeps its connection when idle, streamed to or made inactive.
    func testJoinAndRead() async throws {
        try await launchFresh()
        try await appearances("join", showing: app.staticTexts["Welcome aboard Infinitary"])
        try await submitLink("wrong-link")
        XCTAssertTrue(app.staticTexts["This is not the computer your link names. Nothing was sent."].waitForPresence(timeout: 15))
        let refused = try await home("state", method: "GET")
        XCTAssertEqual((refused["devices"] as? [Any])?.count, 0)
        picture("wrong-mac")
        try await join()
        // INF-63 accepted B survives the move from the read-only list to native card chrome.
        // Finish the finding before the feed snapshot used by the foundation's Activity checks.
        _ = try await home("review-finding")
        showCard("Review the phone connection finding")
        XCTAssertTrue(app.staticTexts["Review finding"].waitForPresence(timeout: 10))
        // INF-2714: the first mate's card is its own, so its head carries no task's key or title.
        XCTAssertFalse(app.buttons["card-task-key"].exists)
        XCTAssertFalse(app.staticTexts["Check the phone connection"].exists)
        XCTAssertTrue(app.webViews.staticTexts["The review needs your choice on the Mac."].waitForPresence(timeout: 10))
        // INF-64 piece 4's approved native choices replace the foundation's read-only absence check.
        let keepFinding = app.buttons["card-action-keep"]
        XCTAssertTrue(keepFinding.waitForPresence(timeout: 10))
        // INF-1083: body text exists before its drawn acknowledgement enables the native footer.
        waitUntilEnabled(keepFinding)
        XCTAssertTrue(keepFinding.isEnabled)
        picture("review-finding")
        tapOnPhone(app.buttons["put-aside-card"])
        XCTAssertTrue(cardHeading("Your phone is reading your Mac").waitForPresence(timeout: 10))
        let first = try await home("state", method: "GET")
        let devices = try XCTUnwrap(first["devices"] as? [[String: Any]])
        let phone = try XCTUnwrap(devices.first)
        XCTAssertEqual(phone["kind"] as? String, "view")
        XCTAssertEqual(phone["system"] as? String, "ios")
        XCTAssertTrue(app.staticTexts["Your phone is reading your Mac"].exists)
        XCTAssertFalse(app.buttons["Merge"].exists)
        XCTAssertTrue(app.webViews.staticTexts["This card belongs to the disposable test home."].firstMatch.waitForPresence(timeout: 10))
        verifyPhoneComposerBounds(app: app)
        picture("cards")
        try await appearances("cards", showing: app.staticTexts["Your phone is reading your Mac"])
        // INF-1062: the computer's name leaves the bar for its sheet, and Leave stays behind that sheet (INF-209).
        XCTAssertFalse(app.staticTexts["home-name"].exists, "The bar no longer carries the computer's name")
        XCTAssertFalse(app.buttons["leave"].exists)
        // INF-355: details must also work as the first hardware chord after relaunch.
        app.terminate(); try await launchPhoneApp(app)
        reach("In reach", timeout: 20)
        try await pressPhoneKey("i", modifiers: .command, in: app)
        XCTAssertTrue(app.buttons["close-computer-details"].waitForPresence(timeout: 10))
        XCTAssertEqual(app.staticTexts["home-name"].label, "Test Mac mini")
        XCTAssertTrue(app.staticTexts["In reach"].exists, "The computer's sheet says its reach")
        XCTAssertTrue(app.staticTexts["reached-address"].label.hasPrefix("127.0.0.1:"), "The sheet names the route reached, not the saved preference")
        XCTAssertTrue(app.buttons["leave"].exists)
        try await appearances("computer-details", showing: app.staticTexts["home-name"])
        tapOnPhone(app.buttons["close-computer-details"])
        // INF-1062, the captain's pick: Settings at the bar's left is this phone's own sheet, with no Leave in it.
        try await pressPhoneKey(",", modifiers: .command, in: app)
        XCTAssertTrue(app.buttons["close-phone-settings"].waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(app.staticTexts["app-version"].label.hasPrefix("Version "), app.staticTexts["app-version"].label)
        XCTAssertFalse(app.buttons["leave"].exists)
        try await appearances("phone-settings", showing: app.staticTexts["app-version"])
        tapOnPhone(app.buttons["close-phone-settings"])
        XCTAssertTrue(app.buttons["close-phone-settings"].waitForAbsence(timeout: 10))
        let settings = app.buttons["phone-settings"]
        XCTAssertTrue(waitForPhonePress(settings)); XCTAssertEqual(settings.label, "Settings")
        let strip = [app.buttons["tab-home"], app.buttons["tab-tasks"], app.buttons["tab-activity"]]
        XCTAssertLessThan(settings.frame.maxX, strip[0].frame.minX, "Settings sits left of the strip")
        // INF-1328: the segmented control draws its tabs edge to edge, in order and never overlapping.
        XCTAssertLessThanOrEqual(strip[0].frame.maxX, strip[1].frame.minX); XCTAssertLessThanOrEqual(strip[1].frame.maxX, strip[2].frame.minX)
        XCTAssertLessThan(strip[2].frame.maxX, app.buttons["computer-details"].frame.minX, "The computer sits right of the strip")
        XCTAssertTrue(strip[0].isSelected, "Home is the lit tab")
        let stripFrames = strip.map { $0.frame.integral }
        // INF-1541 piece 1: the card's heading redraws at the largest type before the strip is read against it.
        let heading = app.staticTexts["Your phone is reading your Mac"]
        let standard = waitForRedraw(heading, from: nil)
        _ = try await home("display-large", budget: displayBudget)
        let largest = waitForRedraw(heading, from: standard)
        XCTAssertTrue(waitForPhonePress(app.buttons["computer-details"]))
        // INF-1062: the strip keeps the bar's own size at the largest standard type, so no word truncates and the
        // bar's buttons stay where they were; growing words once truncated Activity and lost a tap on the computer.
        XCTAssertEqual(strip.map { $0.frame.integral }, stripFrames, "The strip's words keep the bar's own size at the largest type")
        picture("cards-largest-standard-type")
        computerDetails()
        XCTAssertTrue(waitForPhonePress(app.buttons["leave"]))
        picture("computer-details-largest-standard-type")
        tapOnPhone(app.buttons["close-computer-details"])
        _ = try await home("display-light", budget: displayBudget)
        _ = waitForRedraw(heading, from: largest)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // INF-1541 piece 1: turned, the card's heading moves onto the stage beside the sidebar, and back upright.
            turnPhone(to: .landscapeLeft, in: app, moving: heading)
            let sidebar = phoneSidebar(app)
            XCTAssertTrue(sidebar.waitForPresence(timeout: 10), app.debugDescription)
            XCTAssertTrue(app.staticTexts["Your phone is reading your Mac"].exists)
            XCTAssertLessThanOrEqual(sidebar.frame.maxX, app.scrollViews["card-scroll"].frame.minX)
            try await appearances("ipad-landscape", showing: app.staticTexts["Your phone is reading your Mac"])
            // INF-589 item 16: Tasks and Activity are a segmented pair at the sidebar's top, each scrolling alone.
            // INF-944 item 6: in the tabs' order, Tasks then Activity, opening on Tasks.
            let tasksRail = phoneSidebarRail("Tasks", in: sidebar), activityRail = phoneSidebarRail("Activity", in: sidebar)
            XCTAssertLessThan(tasksRail.frame.midX, activityRail.frame.midX, "Tasks comes before Activity")
            XCTAssertTrue(tasksRail.isSelected)
            let waiting = phoneTasksColumn(sidebar)
            XCTAssertTrue(waiting.waitForPresence(timeout: 10), "The sidebar opens on Tasks")
            XCTAssertTrue(waitForPhonePress(waiting))
            XCTAssertLessThanOrEqual(tasksRail.frame.maxY, waiting.frame.minY, "The pair sits at the sidebar's top")
            picture("ipad-landscape-tasks")
            tapOnPhone(activityRail)
            let activity = sidebar.staticTexts.matching(identifier: "activity-text").firstMatch
            XCTAssertTrue(activity.waitForPresence(timeout: 10), "Activity opens at once")
            XCTAssertFalse(waiting.exists)
            XCTAssertLessThanOrEqual(activityRail.frame.maxY, activity.frame.minY)
            tapOnPhone(tasksRail)
            XCTAssertTrue(waiting.waitForPresence(timeout: 10))
            XCTAssertFalse(activity.exists)
            turnPhone(to: .portrait, in: app, moving: heading)
            XCTAssertTrue(sidebar.waitForAbsence(timeout: 10))
        }
        // INF-136 #2: no product traffic for longer than both former pairing deadlines.
        let idle = try await home("idle")
        let idleBefore = try XCTUnwrap(idle["before"] as? [String: Int])
        let idleAfter = try XCTUnwrap(idle["after"] as? [String: Int])
        XCTAssertEqual(idleAfter["connections"], idleBefore["connections"], "An idle phone must keep its existing connection")
        // INF-136 #1/#12: a card revision witnesses processing all preceding stream pushes.
        let stream = try await home("stream")
        XCTAssertTrue(app.staticTexts["Streaming finished"].waitForPresence(timeout: 10))
        let streamed = try await home("state", method: "GET")
        let beforeStream = try XCTUnwrap(stream["before"] as? [String: Int])
        let afterStream = try XCTUnwrap(streamed["readings"] as? [String: Int])
        XCTAssertEqual(afterStream["feed"], beforeStream["feed"], "Streaming does not change Activity")
        XCTAssertEqual(afterStream["cards"], beforeStream["cards"], "The push already carries the card snapshot")
        _ = try await home("stream-reset")
        XCTAssertTrue(app.staticTexts["Your phone is reading your Mac"].waitForPresence(timeout: 10))
        // INF-136 #9: Control Center makes the scene inactive, not backgrounded.
        let beforeInactive = try await home("state", method: "GET")
        // INF-1646: a starved SpringBoard can stall on the pull's first touch, and the system keeps only its first ~180 ms of touches.
        // A default-speed pull lasts over a second, so its lift is dropped and Control Center never finishes opening; this pull lifts
        // within a tenth of a second and waits whole in that queue, so Control Center opens once SpringBoard resumes.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.01)).press(forDuration: 0.05,
            thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.65)),
            withVelocity: XCUIGestureVelocity(rawValue: 20_000), thenHoldForDuration: 0)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // A fresh simulator has no connectivity controls; the container itself witnesses the overlay.
        let controlCenter = springboard.otherElements["cc-root-folder-view"]
        XCTAssertTrue(controlCenter.waitForPresence(timeout: 10), springboard.debugDescription)
        // Dismiss the empty simulator's overlay without invoking iPad's Home/window gesture.
        tapOnPhone(springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.9)))
        XCTAssertTrue(controlCenter.waitForAbsence(timeout: 10))
        app.activate()
        reach("In reach", timeout: 10)
        let afterInactive = try await home("state", method: "GET")
        XCTAssertEqual((afterInactive["readings"] as? [String: Int])?["connections"],
            (beforeInactive["readings"] as? [String: Int])?["connections"], "An inactive scene keeps its connection")
    }
}
