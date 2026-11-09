import XCTest

/// The cards-place part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-3124, the captain: "interacting with a thread on a card: currently, it auto scroll down to the latest message
    /// update at the bottom. That disrupts my flow", with direction B and the jump down whenever they read above.
    /// Data: a first mate card whose fourteen-message thread is longer than its back on the iPhone and the iPad, then two new first mate lines.
    /// Completion: the back opens at its foot with no jump down; scrolled to its start it shows a plain arrow; the two
    /// new lines leave the first message where it was and count "↓ 2 new"; the jump goes to the first of them; then, at
    /// its foot, two exchanges of a reply and the stand-in first mate's answer each stay in view with no jump down.
    func testThreadKeepsItsPlace() async throws {
        try await launchJoined()
        let fixture = try await home("place-card")
        let title = try XCTUnwrap(fixture["title"] as? String)
        let first = try XCTUnwrap(fixture["first"] as? String)
        let count = try XCTUnwrap(fixture["count"] as? Int)
        XCTAssertTrue(cardHeading(title).waitForPresence(timeout: 10), app.debugDescription)
        waitForShownBodyRevealed()
        let cue = app.buttons["thread-cue"]
        XCTAssertTrue(cue.waitForPresence(timeout: 10), app.debugDescription)
        reveal(cue); tapOnPhone(cue)
        let back = app.descendants(matching: .any).matching(identifier: "card-back").firstMatch
        XCTAssertTrue(back.waitForPresence(timeout: 10), app.debugDescription)
        let thread = app.scrollViews["card-thread"]
        let jump = app.buttons["thread-jump"]
        let opening = back.staticTexts[first]
        // A thread opens at its foot, where nothing waits below.
        waitForSteadyTarget(thread)
        XCTAssertFalse(jump.exists, "The thread opened above its foot\n\(app.debugDescription)")
        // The captain scrolls back to the thread's start; the jump down shows as a plain arrow.
        for _ in 0..<8 where !(opening.exists && opening.isHittable) { thread.swipeDown() }
        waitForSteadyTarget(opening)
        XCTAssertTrue(opening.isHittable, "The thread's first message cannot be reached\n\(app.debugDescription)")
        XCTAssertTrue(jump.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(jump.label, "↓")
        let before = opening.frame
        picture("1-thread-read-from-its-start")
        let more = try await home("place-card-more")
        let added = try XCTUnwrap(more["added"] as? String)
        let label = app.staticTexts["thread-count"]
        let arrived = NSPredicate { _, _ in label.exists && label.label == "THREAD · \(count + 2)" }
        XCTAssertEqual(waitForPhonePredicate(arrived, object: nil, timeout: 20), .completed, app.debugDescription)
        // The new lines move nothing: the first message holds its place, and the jump counts them.
        let counted = NSPredicate { _, _ in jump.exists && jump.label == "↓ 2 NEW" }
        XCTAssertEqual(waitForPhonePredicate(counted, object: nil, timeout: 10), .completed, app.debugDescription)
        waitForSteadyTarget(opening)
        XCTAssertEqual(opening.frame.minY, before.minY, accuracy: 1, "A new line moved the thread\n\(app.debugDescription)")
        picture("2-two-new-below")
        // The jump goes to the first new line.
        tapOnPhone(jump)
        let firstNew = back.staticTexts[added]
        XCTAssertTrue(waitForPhonePress(firstNew), "The jump did not reach the first new line\n\(app.debugDescription)")
        picture("3-at-the-new-lines")
        // At its foot the thread follows: across two exchanges the captain's reply and the answer are in view, and no jump
        // down shows.
        let answer = try XCTUnwrap(fixture["replyAnswer"] as? String)
        let reply = app.textFields["card-reply"]
        let send = app.buttons["send-reply"]
        for exchange in 1...2 {
            XCTAssertFalse(jump.exists, "The thread left its foot before exchange \(exchange)\n\(app.debugDescription)")
            let words = "Exchange \(exchange): go ahead with Thursday."
            reveal(reply); focusForPhoneTyping(reply, in: app); reply.typeText(words)
            reveal(send); tapOnPhone(send)
            // A line just added reads no tap point while the thread scrolls it into view, so each line is first read inside
            // the thread's frame, then as pressable.
            let sent = back.staticTexts[words]
            XCTAssertTrue(waitForInThread(sent, thread), "The reply is not in view\n\(app.debugDescription)")
            XCTAssertTrue(waitForPhonePress(sent), "The reply is not in view\n\(app.debugDescription)")
            let answers = back.staticTexts.matching(NSPredicate(format: "label == %@", answer))
            let answered = NSPredicate { _, _ in answers.count == exchange }
            XCTAssertEqual(waitForPhonePredicate(answered, object: nil, timeout: 30), .completed, app.debugDescription)
            let latest = answers.element(boundBy: exchange - 1)
            XCTAssertTrue(waitForInThread(latest, thread), "Answer \(exchange) is not in view\n\(app.debugDescription)")
            XCTAssertTrue(waitForPhonePress(latest), "Answer \(exchange) is not in view\n\(app.debugDescription)")
            XCTAssertFalse(jump.exists, "Answer \(exchange) was counted, not shown\n\(app.debugDescription)")
        }
        picture("4-following-at-the-foot")
    }

    /// Whether `line` comes to sit wholly inside the thread's own frame, read from frames alone.
    private func waitForInThread(_ line: XCUIElement, _ thread: XCUIElement) -> Bool {
        let inside = NSPredicate { _, _ in
            line.exists && !line.frame.isEmpty && thread.frame.contains(line.frame)
        }
        return waitForPhonePredicate(inside, object: nil, timeout: 10) == .completed
    }
}
