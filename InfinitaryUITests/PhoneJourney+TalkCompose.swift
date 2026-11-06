import XCTest

/// The talk-compose part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2125 direction C, the first of the talk tests split from testTalkAndTasks: a photo and typed words, the draft
    /// kept across tabs, rotation and sheets, and the ask sent with its photo.
    func testComposeAndSend() async throws {
        try await launchJoined()
        // The single journey reached this part with the cards part's hero card on the stage, after a relaunch.
        _ = try await home("empty-cards")
        let hero = try await home("hero-card")
        XCTAssertTrue(cardHeading(try XCTUnwrap(hero["title"] as? String)).waitForPresence(timeout: 10), app.debugDescription)
        app.terminate(); try await launchPhoneApp(app)
        reach("In reach", timeout: 20)
        try await composeAndSend()
    }

    /// INF-2218's approved reading view: the existing saved round opens without sending another message.
    /// The talk fixture supplies the real saved reply; the sheet preserves its words and dismissal on both devices.
    private func verifyReplyReading(_ sent: [String: Any]) async throws {
        let round = try XCTUnwrap(sent["lastTurn"] as? [String: Any])
        let question = try XCTUnwrap(round["you"] as? String)
        let reply = try XCTUnwrap(round["reply"] as? [String: Any])
        let words = try XCTUnwrap(reply["words"] as? String ?? reply["text"] as? String)
        let before = try await home("talk-state", method: "GET")
        tapOnPhone(app.buttons["last-turn-reply"])
        let body = app.staticTexts["reply-note-words"]
        XCTAssertTrue(body.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(body.label, words, "The sheet keeps the saved reply's literal words")
        let bubble = app.buttons["reply-note-question"]
        XCTAssertTrue(bubble.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(bubble.label, question, "The shared bubble shows the original saved question without added quotes")
        XCTAssertTrue(app.staticTexts["You"].exists)
        XCTAssertTrue(app.staticTexts["First mate"].exists)
        XCTAssertFalse(app.staticTexts["reply-note-title"].exists)
        try await appearances("conversation-reply", showing: body)
        tapOnPhone(app.buttons["close-reply-note"])
        XCTAssertTrue(app.buttons["close-reply-note"].waitForAbsence(timeout: 10))
        let after = try await home("talk-state", method: "GET")
        XCTAssertEqual((after["writes"] as? [Any])?.count, (before["writes"] as? [Any])?.count,
                       "Reading and dismissing the sheet sends nothing")
        XCTAssertEqual((after["lastTurn"] as? [String: Any])?["you"] as? String, question)
    }

    /// INF-2218: realistic saved long and picture-only rounds through the task owner, not another reply store.
    /// The native sheet must keep exact multiline words, allow the long question to open/fold and send nothing.
    private func verifyLongReplyReading() async throws {
        _ = try await home("empty-cards")
        let fixture = try await home("reply-reading-fixture")
        app.terminate(); app.launch()
        let pictureQuestion = app.staticTexts["last-turn-you"]
        XCTAssertTrue(pictureQuestion.waitForPresence(timeout: 10), app.debugDescription)
        let pictureWords = pictureQuestion.label
        let before = try await home("talk-state", method: "GET")
        tapOnPhone(app.buttons["last-turn-reply"])
        let body = app.staticTexts["reply-note-words"]
        XCTAssertTrue(body.waitForPresence(timeout: 10))
        XCTAssertEqual(body.label, fixture["problemWords"] as? String)
        XCTAssertEqual(app.buttons["reply-note-question"].label, pictureWords)
        XCTAssertFalse(app.buttons["reply-note-question"].isEnabled)
        try await appearances("conversation-picture-problem", showing: body)
        tapOnPhone(app.buttons["close-reply-note"])
        XCTAssertTrue(app.buttons["close-reply-note"].waitForAbsence(timeout: 10))
        tapOnPhone(app.buttons["last-turn-older-reply"])
        XCTAssertTrue(body.waitForPresence(timeout: 10))
        XCTAssertEqual(body.label, fixture["words"] as? String)
        let bubble = app.buttons["reply-note-question"]
        XCTAssertTrue(bubble.isEnabled, "A question cut after two lines can be opened")
        XCTAssertEqual(bubble.label, fixture["question"] as? String)
        let folded = bubble.frame.height
        tapOnPhone(bubble)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate { _, _ in bubble.frame.height > folded }, object: nil, timeout: 10), .completed)
        tapOnPhone(bubble)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate { _, _ in bubble.frame.height == folded }, object: nil, timeout: 10), .completed)
        tapOnPhone(bubble)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate { _, _ in bubble.frame.height > folded }, object: nil, timeout: 10), .completed)
        XCTAssertEqual(body.label, fixture["words"] as? String)
        try await appearances("conversation-long-reply", showing: body)
        let scroll = app.scrollViews["reply-note-scroll"]
        if body.frame.maxY > scroll.frame.maxY {
            scroll.swipeUp()
            XCTAssertEqual(waitForPhonePredicate(NSPredicate { _, _ in body.frame.maxY <= scroll.frame.maxY + 1 }, object: nil, timeout: 10), .completed)
            picture("conversation-long-reply-scrolled")
        }
        tapOnPhone(app.buttons["close-reply-note"])
        XCTAssertTrue(app.buttons["close-reply-note"].waitForAbsence(timeout: 10))
        let after = try await home("talk-state", method: "GET")
        XCTAssertEqual((after["writes"] as? [Any])?.count, (before["writes"] as? [Any])?.count,
                       "Reading either saved round sends no message")
        let savedBefore = try XCTUnwrap(before["lastTurn"] as? NSDictionary)
        let savedAfter = try XCTUnwrap(after["lastTurn"] as? NSDictionary)
        XCTAssertEqual(savedAfter, savedBefore, "Reading and scrolling do not change saved words")
    }

    /// INF-64 piece 5: native input and controls reach the real Mac as captain actions.
    /// Data: a project-owned photo, a typed harbour ask, and an on-request task with a held mock-provider turn.
    /// Completion: the Mac keeps the ask/photo, runs that task, records interruption/continuation and hears the steer.
    /// Resources: each talk test's own fresh simulator/home only; no phone signing, microphone or real account.
    /// INF-2125 direction C splits it in three: composeAndSend, tasksAndSteer and draftsAcrossHomes.
    private func composeAndSend() async throws {
        let fixture = try await home("talk-fixture")
        let words = try XCTUnwrap(fixture["text"] as? String)
        addPhoneJourneyPhoto(app: app)
        let input = app.textFields["message-box"]
        focusForPhoneTyping(input, in: app); input.typeText(words)
        picture("message-and-photo")
        let beforeDraft = try await home("talk-state", method: "GET")
        try await verifyComposerDraft(words)
        let afterDraft = try await home("talk-state", method: "GET")
        XCTAssertEqual((afterDraft["writes"] as? [Any])?.count, (beforeDraft["writes"] as? [Any])?.count,
            "Command-Return behind the details sheet sends no hidden composer request")
        // The completed keyboard/details interactions follow rotation's intermediate redraw.
        picture("draft-portrait-ready")
        tapOnPhone(app.buttons["send-message"])
        let sent = try await home("talk-sent")
        let writes = try XCTUnwrap(sent["writes"] as? [[String: Any]])
        let message = try XCTUnwrap(writes.first { $0["channel"] as? String == "inf:converse" })
        XCTAssertEqual((message["actor"] as? [String: Any])?["kind"] as? String, "captain")
        let payload = try XCTUnwrap((message["args"] as? [[String: Any]])?.first)
        XCTAssertEqual(payload["text"] as? String, words)
        XCTAssertEqual(payload["visibleCardId"] as? String, fixture["visibleCardId"] as? String)
        XCTAssertNotNil(payload["visibleCardId"])
        XCTAssertNil(payload["pastCardId"])
        let images = try XCTUnwrap(payload["images"] as? [[String: Any]])
        XCTAssertEqual(images.count, 1); XCTAssertGreaterThan(try XCTUnwrap(images.first?["bytes"] as? Int), 0)
        XCTAssertEqual((sent["lastTurn"] as? [String: Any])?["you"] as? String, words)
        XCTAssertTrue(app.staticTexts["last-turn-you"].waitForPresence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "photo-chip").count, 0)
        verifyPhoneComposerBounds(app: app)
        picture("last-turn")
        try await verifyReplyReading(sent)
        try await verifyLongReplyReading()
    }

    /// INF-209 and INF-82 integration: one composer retains the actual typed/photo draft across tabs and rotation.
    /// This extends the existing real-home journey, using its owned simulator, selected photo and captain ask.
    private func verifyComposerDraft(_ words: String) async throws {
        try await verifyPhoneComposerDrafts(app: app, words: words, tab: { tab($0) }, picture: picture) { start in
            _ = try await self.home(start ? "capture-composer-start" : "capture-stop")
        }
    }
}
