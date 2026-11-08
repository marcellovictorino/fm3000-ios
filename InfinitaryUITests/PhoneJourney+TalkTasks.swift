import XCTest

/// The talk-tasks part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2125 direction C, the second talk test: Tasks after a relaunch pair, search, start, interrupt, continue, steer
    /// and the notice that opens its card.
    func testTasksAndSteer() async throws {
        let fixture = try await launchWithLastTurn()
        try await tasksAndSteer(fixture)
    }

    /// INF-2935: the record's status pill, which reads the Mac's word for the task.
    private func recordReads(_ word: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "identifier == %@ AND label == %@", "task-record-status", word)).firstMatch
    }

    /// One entry of a row's long press menu, by the name it starts with; its line under the name, what it does or why it
    /// cannot run, may follow in the same label.
    private func moveEntry(_ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
    }

    /// INF-2928 piece 3, the captain's "Every move the Mac allows on that row": a swipe on a Backlog row shows the Mac's
    /// row Start, dim with the Mac's reason when it cannot start; a long press shows the row's moves under its summary,
    /// a move that cannot run stays dim, and Drop task asks in the record's words before the Mac drops it. One press on
    /// a Start that can run sends the Mac's start, and a refusal says why.
    private func rowMoves() async throws {
        let seeded = try await home("row-moves-fixture")
        let id = try XCTUnwrap(seeded["id"] as? String)
        let row = app.buttons["task-\(id)"]
        XCTAssertTrue(row.waitForPresence(timeout: 10), app.debugDescription)
        waitForSteadyTarget(row)
        row.swipeLeft()
        let waiting = app.buttons["row-start-\(id)"]
        XCTAssertTrue(waiting.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertFalse(waiting.isEnabled, "A Start that cannot run stays dim")
        let reason = app.staticTexts["row-start-reason"]
        XCTAssertTrue(reason.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(reason.label, seeded["startReason"] as? String, "The row says the Mac's reason it cannot start")
        picture("task-row-start-reason")
        tapOnPhone(row)
        XCTAssertTrue(waiting.waitForAbsence(timeout: 10), "A tap on the row closes its Start instead of opening it")
        XCTAssertFalse(app.buttons["close-record"].exists, "The tap opened no record")
        // The long press: the Mac's menu for a Backlog row that waits on another task.
        waitForSteadyTarget(row)
        row.press(forDuration: 1.2)
        let drop = moveEntry("Drop task")
        XCTAssertTrue(drop.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(moveEntry("Open record").exists, app.debugDescription)
        XCTAssertTrue(moveEntry("Queue it").isEnabled, "Queue it runs at once, as on the Mac")
        XCTAssertFalse(moveEntry("Start now").isEnabled, "Start now cannot run while the task it waits on is open")
        picture("task-moves")
        tapOnPhone(drop)
        let ask = app.alerts.firstMatch
        XCTAssertTrue(ask.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(ask.label, seeded["drop"] as? String, "Drop task asks in the record's words")
        picture("task-drop-ask")
        tapOnPhone(ask.buttons["Drop task"])
        let dropped = try await home("row-moves-dropped")
        let writes = try XCTUnwrap(dropped["writes"] as? [[String: Any]])
        XCTAssertTrue(writes.contains { write in
            let args = write["args"] as? [Any] ?? []
            return write["channel"] as? String == "inf:task:run" && args.first as? String == id
                && args.dropFirst().first as? String == "drop-task" && args.count == 3
        }, "Drop task sends the Mac's drop with what it asked about: \(writes)")
        // A Start that can run: one press sends the Mac's start, with no ask, and its refusal says why.
        let work = app.buttons["task-phone-work"]
        XCTAssertTrue(work.waitForPresence(timeout: 10))
        waitForSteadyTarget(work)
        work.swipeLeft()
        let start = app.buttons["row-start-phone-work"]
        XCTAssertTrue(start.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(start.isEnabled)
        picture("task-row-start")
        let refusal = "This task changed on your computer. Look at it again."
        _ = try await home("refuse-next-change", body: #"{"channel":"inf:task:run","words":"\#(refusal)"}"#)
        tapOnPhone(start)
        let notice = app.buttons["change-notice"]
        XCTAssertTrue(notice.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(notice.label, refusal)
        XCTAssertTrue(start.waitForAbsence(timeout: 10), "Start closes the row once pressed")
        let state = try await home("talk-state", method: "GET")
        let sent = try XCTUnwrap(state["writes"] as? [[String: Any]])
        XCTAssertTrue(sent.contains { ($0["args"] as? [String]) == ["phone-work", "start-task"] }, "The row's Start is the Mac's start: \(sent)")
        tapOnPhone(notice)
        XCTAssertTrue(notice.waitForAbsence(timeout: 10))
    }

    private func tasksAndSteer(_ fixture: [String: Any]) async throws {
        // One pair here for the hero pictures; the relaunch parts run INF-1735's 20.
        try await relaunchPairs(1, pictured: true)
        XCTAssertTrue(app.buttons["group-backlog"].waitForPresence(timeout: 10))
        picture("tasks")
        // INF-2928 piece 1: as on the Mac, a group with no tasks does not show.
        for empty in ["waiting", "working", "queued", "landed"] {
            XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "group-\(empty)").firstMatch.exists, "\(empty) has no tasks")
        }
        tapOnPhone(app.buttons["group-backlog"])
        XCTAssertTrue(app.buttons["task-phone-work"].waitForPresence(timeout: 10))
        picture("tasks-backlog")
        try await rowMoves()
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
        // A search keeps the groups and opens them, as the Mac's does.
        XCTAssertTrue(app.buttons["group-backlog"].exists, app.debugDescription)
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
        // INF-2935: the Mac's tabs; the Crewmate tab's status line carries Stop, the Mac's word for Interrupt.
        let crewmateTab = app.buttons["record-tab-crewmate"]
        XCTAssertTrue(crewmateTab.waitForPresence(timeout: 10)); tapOnPhone(crewmateTab)
        let stop = app.buttons["crew-stop"]
        XCTAssertTrue(stop.waitForPresence(timeout: 10))
        XCTAssertEqual(stop.label, "Stop")
        picture("crewmate-working")
        _ = try await home("capture-stop")
        // INF-2553: a Stop the computer still holds already reads Stopping on the record.
        _ = try await home("hold-card-action", body: #"{"channel":"inf:task:interrupt"}"#)
        tapOnPhone(stop)
        _ = try await home("card-action-held")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier == %@ AND label == %@", "crew-stop", "Stopping…")).firstMatch
            .waitForPresence(timeout: 10), "A Stop shows at the tap, before the computer answers")
        picture("task-interrupt-at-tap")
        _ = try await home("release-card-action")
        let interrupted = try await home("talk-interrupted")
        let events = try XCTUnwrap(interrupted["events"] as? [[String: Any]])
        XCTAssertTrue(events.contains { $0["kind"] as? String == "interrupted" && $0["actor"] as? String == "captain" })
        XCTAssertEqual(interrupted["activity"] as? String, "idle", "Interrupt stops the turn and keeps it steerable")
        _ = try await home("talk-resumable")
        // The record bar, with Continue, ends Info; the Crewmate tab ends with its status line and the message box.
        tapOnPhone(app.buttons["record-tab-info"])
        XCTAssertTrue(recordReads("Interrupted").waitForPresence(timeout: 10))
        XCTAssertTrue(app.buttons["continue-task"].waitForPresence(timeout: 10))
        picture("task-interrupted")
        tapOnPhone(app.buttons["continue-task"])
        tapOnPhone(crewmateTab)
        XCTAssertTrue(stop.waitForPresence(timeout: 20))
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
