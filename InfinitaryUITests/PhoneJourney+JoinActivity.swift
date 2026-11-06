import XCTest

/// The join-activity part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2125 direction C, the second join test: Activity, the empty stage, a relaunch's identity, out of reach and catch-up.
    /// Data: the join note, the review finding closed as the first join test closes it, and a recorded report while away.
    /// Completion: Activity shows the computer's lines newest last, the phone rejoins as itself and catches up when back.
    func testActivityAndCatchUp() async throws {
        try await launchJoined()
        // The state the first join test reached before Activity: the review finding read and closed on the phone.
        _ = try await home("review-finding")
        showCard("Review the phone connection finding")
        XCTAssertTrue(app.staticTexts["Review finding"].waitForPresence(timeout: 10))
        tapOnPhone(app.buttons["put-aside-card"])
        XCTAssertTrue(cardHeading("Your phone is reading your Mac").waitForPresence(timeout: 10))
        let first = try await home("state", method: "GET")
        let phone = try XCTUnwrap((first["devices"] as? [[String: Any]])?.first)
        tab("Activity")
        let feed = try XCTUnwrap(first["feed"] as? [[String: Any]])
        let line = try XCTUnwrap(feed.first?["text"] as? String)
        XCTAssertTrue(app.staticTexts[line].waitForPresence(timeout: 10))
        // INF-1845, the captain: "At the bottom on both, as on the Mac" - the newest line is the last row.
        XCTAssertEqual(app.staticTexts.matching(identifier: "activity-text").allElementsBoundByIndex.last?.label, feed.last?["text"] as? String)
        try await appearances("activity", showing: app.staticTexts[line])
        tab("Home")
        _ = try await home("empty-cards")
        // INF-1060: as on the Mac, the empty stage is the character alone, with no line under it.
        XCTAssertTrue(app.otherElements["phone-character"].waitForPresence(timeout: 10))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == 'No cards to read yet.'")).count, 0)
        // INF-589 item 11: with no card to page, the chevrons and count hide; the pager hides entirely when nothing is minimized.
        for id in ["previous-card", "next-card"] {
            XCTAssertFalse(app.buttons[id].exists, "\(id) shows on an empty stage")
        }
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "card-pager").firstMatch.exists, "The pager shows on an empty stage")
        _ = try await home("capture-character-start")
        try await appearances("empty-stage", showing: app.buttons["phone-settings"])
        _ = try await home("capture-stop")
        _ = try await home("stream-reset")
        XCTAssertTrue(app.staticTexts["Your phone is reading your Mac"].waitForPresence(timeout: 10))

        app.terminate(); try await launchPhoneApp(app)
        reach("In reach", timeout: 20)
        let afterLaunch = try await home("state", method: "GET")
        XCTAssertEqual((afterLaunch["devices"] as? [[String: Any]])?.first?["id"] as? String, phone["id"] as? String)

        _ = try await home("offline")
        outOfReach()
        XCTAssertTrue(app.staticTexts["Your phone is reading your Mac"].exists)
        // INF-589 item 11: out of reach is said once; under the composer, one line says only that changes are off.
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'out of reach' AND NOT (label ==[c] 'Out of reach')")).count, 0,
            app.debugDescription)
        XCTAssertEqual(app.staticTexts["connection-refusal"].label, "Changes are off until Test Mac mini is back.")
        try await appearances("out-of-reach", showing: app.staticTexts["connection-refusal"])
        computerDetails()
        XCTAssertTrue(app.buttons["forget-mac"].exists)
        picture("computer-details-out-of-reach")
        tapOnPhone(app.buttons["close-computer-details"])
        // Record the recovery itself, not the separate appearance and details checks above.
        _ = try await home("capture-start")
        let change = try await home("change")
        _ = try await home("online")
        reach("In reach", timeout: 20)
        let title = try XCTUnwrap(change["title"] as? String)
        showCard(title)
        XCTAssertTrue(cardHeading(title).waitForPresence(timeout: 10))
        picture("caught-up")
        _ = try await home("capture-stop")
        tab("Activity")
        let caughtUp = try await home("state", method: "GET")
        let caughtUpFeed = try XCTUnwrap(caughtUp["feed"] as? [[String: Any]])
        let newest = try XCTUnwrap(caughtUpFeed.last?["text"] as? String)
        XCTAssertTrue(app.staticTexts[newest].waitForPresence(timeout: 10))
        XCTAssertEqual(app.staticTexts.matching(identifier: "activity-text").allElementsBoundByIndex.last?.label, newest)
        let taskKey = try XCTUnwrap(caughtUpFeed.last?["taskKey"] as? String)
        let keyLabel = NSPredicate(format: "label == %@", taskKey)
        XCTAssertTrue(app.descendants(matching: .any).matching(keyLabel).firstMatch.exists,
            "Activity shows the actual computer-authored task key")
        picture("activity-caught-up")
        // INF-1845, the captain's plan B: tapping a line shows its summary, with the whole words.
        tapOnPhone(app.staticTexts[newest])
        let summaryText = app.staticTexts["activity-summary-text"]
        XCTAssertTrue(summaryText.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(summaryText.label, newest)
        picture("activity-summary")
        tapOnPhone(app.buttons["close-activity-summary"])
        XCTAssertTrue(summaryText.waitForAbsence(timeout: 10))
        // Tapping a line's key opens that task's record.
        let key = try XCTUnwrap(app.buttons.matching(identifier: "activity-key").allElementsBoundByIndex.last)
        XCTAssertEqual(key.label, taskKey)
        tapOnPhone(key)
        XCTAssertTrue(app.staticTexts["task-record-title"].waitForPresence(timeout: 10), app.debugDescription)
        tapOnPhone(app.buttons["close-record"])
        tab("Activity")
        // INF-1062, the captain: Activity runs to the foot with nothing over it, so after scrolling to its end
        // the last row is whole in the window and pressable; the message box belongs to Home.
        XCTAssertFalse(app.textFields["message-box"].exists, "Activity has no message box over it")
        XCTAssertFalse(app.otherElements["phone-composer"].exists)
        let long = try await home("long-activity")
        let newestLine = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", try XCTUnwrap(long["newest"] as? String))).firstMatch
        XCTAssertTrue(newestLine.waitForPresence(timeout: 10), app.debugDescription)
        let oldest = app.staticTexts.matching(NSPredicate(format: "label == %@", try XCTUnwrap(caughtUpFeed.first?["text"] as? String))).firstMatch
        // INF-1845, the captain: "make sure activity tab auto-scrolls to the bottom like how a chat app normally would";
        // the newest line, the last row, is whole in the window and pressable with no swipe.
        waitForSteadyTarget(newestLine)
        XCTAssertTrue(waitForPhonePress(newestLine), "The newest line, the last row, shows without a swipe: \(app.debugDescription)")
        XCTAssertLessThanOrEqual(newestLine.frame.maxY, app.frame.maxY, "The last row is whole in the window")
        picture("activity-end")
        let list = app.scrollViews["activity-list"]
        for _ in 0..<12 where !(oldest.exists && oldest.isHittable) { list.swipeDown() }
        // INF-1541 piece 1: XCTest no longer waits out the last swipe's glide, so the row is read once it holds still.
        waitForSteadyTarget(oldest)
        XCTAssertTrue(waitForPhonePress(oldest), "The oldest line, the first row, can be reached and pressed: \(app.debugDescription)")
        tab("Home")
    }
}
