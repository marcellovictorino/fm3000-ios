import XCTest

/// The talk-tasks part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2125 direction C, the second talk test: Tasks after a relaunch pair, search, start, interrupt, continue, steer
    /// and the notice that opens its card.
    func testTasksAndSteer() async throws {
        let fixture = try await launchWithLastTurn()
        try await tasksAndSteer(fixture)
    }

    /// The record's state line (key · state · computer) reading this state.
    private func recordReads(_ state: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", " · \(state) · ")).firstMatch
    }

    private func tasksAndSteer(_ fixture: [String: Any]) async throws {
        // One pair here for the hero pictures; the relaunch parts run INF-1735's 20.
        try await relaunchPairs(1, pictured: true)
        XCTAssertTrue(app.buttons["group-backlog"].waitForPresence(timeout: 10))
        picture("tasks")
        tapOnPhone(app.buttons["group-backlog"])
        XCTAssertTrue(app.buttons["task-phone-work"].waitForPresence(timeout: 10))
        picture("tasks-backlog")
        // INF-589 item 9: search waits above the list until it is pulled down, and Find a task opens it by key, as on the Mac.
        let search = app.textFields["task-search"]
        XCTAssertFalse(search.exists)
        app.scrollViews["tasks-list"].swipeDown()
        XCTAssertTrue(search.waitForPresence(timeout: 10))
        tapOnPhone(app.buttons["close-task-search"])
        XCTAssertTrue(search.waitForAbsence(timeout: 10))
        try await pressPhoneKey("f", modifiers: [.command, .shift], in: app)
        XCTAssertTrue(search.waitForPresence(timeout: 10))
        search.typeText("harbour")
        XCTAssertTrue(app.buttons["task-phone-work"].waitForPresence(timeout: 10))
        picture("task-search")
        tapOnPhone(app.buttons["task-phone-work"])
        XCTAssertTrue(app.buttons["start-task"].waitForPresence(timeout: 10))
        picture("task-before-start")
        _ = try await home("capture-talk-start")
        // INF-2553, the captain's "everything at once, the task record included": a start the computer still holds
        // already reads Starting on the record.
        _ = try await home("hold-card-action", body: #"{"channel":"inf:task:run"}"#)
        tapOnPhone(app.buttons["start-task"])
        _ = try await home("card-action-held")
        XCTAssertTrue(recordReads("Starting").waitForPresence(timeout: 10), "A start shows at the tap, before the computer answers")
        picture("task-start-at-tap")
        _ = try await home("release-card-action")
        let started = try await home("talk-started")
        XCTAssertNotNil(started["startedAt"] as? Double)
        XCTAssertTrue(started["executionDeviceId"] is NSNull, "The phone starts work on its Mac, never on the phone")
        XCTAssertTrue(app.buttons["Crewmate"].waitForPresence(timeout: 10)); tapOnPhone(app.buttons["Crewmate"])
        XCTAssertTrue(app.buttons["interrupt-task"].waitForPresence(timeout: 10))
        picture("crewmate-working")
        _ = try await home("capture-stop")
        // INF-2553: an interrupt the computer still holds already reads Stopping on the record.
        _ = try await home("hold-card-action", body: #"{"channel":"inf:task:interrupt"}"#)
        tapOnPhone(app.buttons["interrupt-task"])
        _ = try await home("card-action-held")
        XCTAssertTrue(recordReads("Stopping").waitForPresence(timeout: 10), "An interrupt shows at the tap, before the computer answers")
        picture("task-interrupt-at-tap")
        _ = try await home("release-card-action")
        let interrupted = try await home("talk-interrupted")
        let events = try XCTUnwrap(interrupted["events"] as? [[String: Any]])
        XCTAssertTrue(events.contains { $0["kind"] as? String == "interrupted" && $0["actor"] as? String == "captain" })
        XCTAssertEqual(interrupted["activity"] as? String, "idle", "Interrupt stops the turn and keeps it steerable")
        _ = try await home("talk-resumable")
        XCTAssertTrue(app.buttons["continue-task"].waitForPresence(timeout: 10))
        picture("task-interrupted")
        tapOnPhone(app.buttons["continue-task"])
        XCTAssertTrue(app.buttons["interrupt-task"].waitForPresence(timeout: 20))
        let steer = try XCTUnwrap(fixture["steer"] as? String)
        let steerField = app.textFields["steer-box"]
        focusForPhoneTyping(steerField, in: app); steerField.typeText(steer)
        // INF-2553: a steer the computer still holds already shows in the transcript, marked sending, and the box clears.
        _ = try await home("hold-card-action", body: #"{"channel":"inf:task:steer"}"#)
        tapOnPhone(app.buttons["steer-task"])
        _ = try await home("card-action-held")
        XCTAssertTrue(app.staticTexts["crew-sending"].waitForPresence(timeout: 10), "A steer shows at the tap, before the computer answers")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label == %@", steer)).firstMatch.exists, "The sending line carries the steer's words")
        XCTAssertNotEqual(steerField.value as? String, steer, "The steer box clears at the tap")
        picture("task-steer-at-tap")
        _ = try await home("release-card-action")
        let steered = try await home("talk-steered")
        let task = try XCTUnwrap(steered["task"] as? [String: Any])
        XCTAssertEqual(task["outcome"] as? String, fixture["report"] as? String)
        let allWrites = try XCTUnwrap(steered["writes"] as? [[String: Any]])
        for write in allWrites { XCTAssertEqual((write["actor"] as? [String: Any])?["kind"] as? String, "captain") }
        XCTAssertTrue(allWrites.contains { $0["channel"] as? String == "inf:task:run" && ($0["args"] as? [String])?.last == "continue-task" })
        picture("crewmate-steered")
        tapOnPhone(app.buttons["close-record"])
        // INF-589 item 6: the notice is a quiet pill under the title on any tab, and a tap opens its card.
        let notice = app.buttons["phone-notice"]
        XCTAssertTrue(notice.waitForPresence(timeout: 10))
        // INF-1062: the notice sits under the top bar on any tab, never over its strip.
        let bar = app.navigationBars.firstMatch
        XCTAssertGreaterThanOrEqual(notice.frame.minY, bar.frame.maxY, "The notice sits under the bar, not over it")
        XCTAssertTrue(app.buttons["tab-tasks"].isSelected, "The notice shows on Tasks, where the record was")
        picture("foreground-notice")
        // INF-1541 piece 1: turned, an iPhone's strip moves into the bar; an iPad brings Home's stage beside the sidebar,
        // where INF-1524 counts the new card beside the pager, so its count is what the turn carries into view.
        turnPhone(to: .landscapeLeft, in: app,
                  moving: UIDevice.current.userInterfaceIdiom == .pad ? app.buttons["card-new"] : app.buttons["tab-home"])
        if UIDevice.current.userInterfaceIdiom == .pad {
            // INF-589 item 16: in landscape the stage is Home, beside the sidebar rather than across it.
            // INF-1524, the captain's pick: Home counts the new card beside the pager instead of a pill over the stage.
            let sidebar = phoneSidebar(app)
            XCTAssertTrue(sidebar.waitForPresence(timeout: 10))
            let fresh = app.buttons["card-new"]
            XCTAssertTrue(fresh.waitForPresence(timeout: 10), app.debugDescription)
            XCTAssertNotNil(fresh.label.wholeMatch(of: /[1-9][0-9]* new/), fresh.label)
            XCTAssertFalse(notice.exists, "Home counts the new card instead of a pill")
            XCTAssertGreaterThanOrEqual(fresh.frame.minX, sidebar.frame.maxX, "The count belongs to the stage")
            picture("notice-landscape")
        } else {
            // INF-589 item 17: on its side the card gets the height; the one-row bar keeps its strip and the notice waits.
            XCTAssertTrue(notice.waitForAbsence(timeout: 10))
            XCTAssertTrue(waitForPhonePress(app.buttons["tab-home"]), "The strip stays in the bar on its side")
            picture("on-its-side")
        }
        // Upright, the strip comes back under the bar: from the bar on an iPhone, and from nowhere on an iPad.
        turnPhone(to: .portrait, in: app, moving: app.buttons["tab-home"])
        XCTAssertTrue(notice.waitForPresence(timeout: 10), "Upright, the unread notice returns")
        let noticed = notice.label
        tapOnPhone(notice)
        XCTAssertTrue(notice.waitForAbsence(timeout: 10))
        let heading = app.staticTexts["card-title"]
        XCTAssertTrue(heading.waitForPresence(timeout: 10))
        XCTAssertTrue(noticed.hasSuffix(": " + heading.label), "The notice \(noticed) opens its own card, not \(heading.label)")
        // The card opens on Home, where the last turn and the message box are.
        XCTAssertTrue(app.buttons["tab-home"].isSelected)
        XCTAssertTrue(app.staticTexts["last-turn-you"].waitForPresence(timeout: 10))
    }
}
