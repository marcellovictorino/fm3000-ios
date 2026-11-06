import XCTest

/// The cards-media part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2125 direction C, the third cards test: pictures, a recording, a thread, a body's choice, out of reach and large type.
    func testCardMediaAndBody() async throws {
        app.launchEnvironment["INFINITARY_TEST_RETRIED_CARD_LAG"] = "3"
        try await launchJoined()
        try await verifyCardMediaAndBody()
    }

    private func verifyCardMediaAndBody() async throws {
        let fixture = try await home("cards-fixture")
        let choice = try XCTUnwrap(fixture["choice"] as? String)
        let chart = try XCTUnwrap(fixture["conversation"] as? String)
        let note = try XCTUnwrap(fixture["note"] as? String)
        // INF-1879: put the staged choice aside without discarding it or answering it.
        showCard(choice)
        let reported = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", #"[0-9]+ of [0-9]+ answered · 1 changed"#)).firstMatch
        XCTAssertTrue(reported.waitForPresence(timeout: 10), app.debugDescription)
        tapOnPhone(app.buttons["put-aside-card"])
        XCTAssertTrue(cardHeading(choice).waitForAbsence(timeout: 10), app.debugDescription)
        XCTAssertFalse(app.alerts.firstMatch.exists, "Putting a card aside never asks to discard its staged settings")

        showCard(chart)
        // INF-1062: with no bar under it, scrolling a long card leaves the message box where it is, in the column's width.
        if UIDevice.current.userInterfaceIdiom == .phone {
            let composer = app.otherElements["phone-composer"].firstMatch
            let before = composer.frame
            app.scrollViews["card-scroll"].swipeUp()
            XCTAssertEqual(composer.frame.minY, before.minY, accuracy: 1, "Scrolling a card does not move the message box")
            XCTAssertEqual(composer.frame.width, before.width, accuracy: 1, "Scrolling a card does not narrow the message box")
            verifyPhoneComposerBounds(app: app)
            try await appearances("card-scrolled", showing: app.buttons["put-aside-card"])
        }
        let pictureElement = app.webViews.images["Blue harbour survey"].firstMatch
        XCTAssertTrue(pictureElement.waitForPresence(timeout: 10))
        reveal(pictureElement); tapOnPhone(pictureElement)
        XCTAssertTrue(app.webViews["card-picture"].waitForPresence(timeout: 10))
        picture("picture-viewer")
        _ = try await home("capture-picture-start")
        app.webViews["card-picture"].pinch(withScale: 1.6, velocity: 1)
        picture("picture-zoomed")
        _ = try await home("capture-stop")
        tapOnPhone(app.buttons["Done"])
        // The home measures the recording and owns its duration label.
        let play = app.webViews.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Play the demo,")).firstMatch
        reveal(play)
        _ = try await home("capture-media-start")
        tapOnPhone(play)
        let player = app.descendants(matching: .any).matching(identifier: "card-recording").firstMatch
        XCTAssertTrue(player.waitForPresence(timeout: 10))
        // The body's Play already starts playback; AVKit may hide its controls before a short clip ends.
        // Completion comes from the real player's end notification, not a transient controls snapshot.
        XCTAssertTrue(app.staticTexts["recording-finished"].waitForPresence(timeout: 15), app.debugDescription)
        tapOnPhone(app.buttons["Play again"])
        XCTAssertTrue(app.staticTexts["recording-finished"].waitForPresence(timeout: 15))
        let mediaState = XCTAttachment(string: app.debugDescription)
        mediaState.name = "recording-controls"; mediaState.lifetime = .keepAlways; add(mediaState)
        picture("recording-playing")
        _ = try await home("capture-stop")
        tapOnPhone(app.buttons["Done"])
        let reply = app.textFields["card-reply"]
        reveal(reply)
        _ = try await home("capture-reply-start")
        focusForPhoneTyping(reply, in: app); reply.typeText("Keep the northern entrance clear.")
        let send = app.buttons["send-reply"]
        reveal(send); tapOnPhone(send)
        XCTAssertTrue(app.staticTexts["Keep the northern entrance clear."].waitForPresence(timeout: 10), app.debugDescription)
        // The reply wakes the first mate, whose answer joins this card's thread a turn later. The count is read once that
        // answer is in, or an answer landing after the read leaves the thread one longer than the count.
        let back = app.descendants(matching: .any).matching(identifier: "card-back").firstMatch
        XCTAssertTrue(back.waitForPresence(timeout: 10), app.debugDescription)
        let answer = try XCTUnwrap(fixture["replyAnswer"] as? String)
        XCTAssertTrue(back.staticTexts[answer].waitForPresence(timeout: 10), app.debugDescription)
        let replied = try await home("card-state", method: "GET")
        let thread = try XCTUnwrap(replied["thread"] as? [String: Any])
        let sent = thread["messages"] as? [[String: Any]] ?? []
        XCTAssertTrue(sent.contains {
            $0["who"] as? String == "captain" && $0["text"] as? String == "Keep the northern entrance clear."
        })
        // INF-1919 (the captain's Approve and build): the send turns the card over to its thread, where the reply shows.
        XCTAssertEqual(app.staticTexts["thread-count"].label, "THREAD · \(sent.count)")
        picture("card-thread-sent")
        // Card turns it back; the face's latest line names the reply, and an answer that lands there lights it.
        tapOnPhone(app.buttons["thread-return"])
        let cue = app.buttons["thread-cue"]
        XCTAssertTrue(cue.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(back.waitForAbsence(timeout: 10), "The face hides the back")
        _ = try await home("thread-answer")
        XCTAssertTrue(waitForPhonePredicate(NSPredicate { _, _ in cue.value as? String == "1 new" }, object: cue, timeout: 10) == .completed,
                      app.debugDescription)
        XCTAssertTrue(app.buttons["put-aside-card"].exists, "A landing reply never turns the card")
        picture("card-thread-unread")
        tapOnPhone(cue)
        XCTAssertTrue(app.staticTexts["I kept your harbour reply with this chart."].waitForPresence(timeout: 10))
        picture("card-thread")
        _ = try await home("capture-stop")
        // Command-backslash turns it back, as on the Mac; the line is read now.
        try await pressPhoneKey("\\", modifiers: .command, in: app)
        XCTAssertTrue(waitForPhonePredicate(NSPredicate { _, _ in cue.value as? String == "\(sent.count + 1) messages" }, object: cue, timeout: 10) == .completed,
                      app.debugDescription)
        let browser = app.buttons["card-action-browser"]
        reveal(browser); tapOnPhone(browser)
        XCTAssertTrue(app.staticTexts["Do this on Test Mac mini."].waitForPresence(timeout: 10))

        _ = try await home("offline")
        outOfReach()
        XCTAssertFalse(app.buttons["put-aside-card"].isEnabled)
        XCTAssertFalse(app.buttons["card-action-body"].isEnabled)
        let atDisconnect = try await home("card-state", method: "GET")
        let bodyButton = app.webViews.buttons["Choose from the body"]
        reveal(bodyButton); tapOnPhone(bodyButton)
        picture("card-out-of-reach")
        _ = try await home("online")
        reach("In reach", timeout: 20)
        let afterReconnect = try await home("card-state", method: "GET")
        let writes: ([String: Any]) -> Int = { state in (state["calls"] as? [[String: Any]] ?? []).filter { $0["channel"] as? String == "inf:cards:act" }.count }
        XCTAssertEqual(writes(afterReconnect), writes(atDisconnect), "An offline body action is never replayed")
        // INF-2553 (the captain: "the card leaves at the tap and the next card is up at once"): the body's choice
        // takes the card off Home while the computer still holds its request, so no second input can reach it.
        _ = try await home("hold-card-action")
        reveal(bodyButton); tapOnPhone(bodyButton)
        _ = try await home("card-action-held")
        XCTAssertTrue(cardHeading(chart).waitForAbsence(timeout: 10), "A body choice shows at the tap, before the computer answers")
        picture("card-choice-at-tap")
        _ = try await home("release-card-action")
        XCTAssertFalse(cardHeading(chart).exists, "The computer's answer leaves the choice as shown")
        let bodyChoice = try await home("card-state", method: "GET")
        XCTAssertEqual(writes(bodyChoice), writes(afterReconnect) + 1, "The choice sends one change")
        let bodyPast = try XCTUnwrap(bodyChoice["conversation"] as? [String: Any])
        XCTAssertEqual((bodyPast["ending"] as? [String: Any])?["actionId"] as? String, "body")
        // The choice wakes the first mate; its turn ends before INF-1060 below reads the footer's reply button.
        _ = try await home("card-choice-turn-ended")
        _ = try await home("show-body-past")
        XCTAssertTrue(app.staticTexts["Past"].waitForPresence(timeout: 10))
        XCTAssertEqual((bodyPast["ending"] as? [String: Any])?["by"] as? String, "frame")
        let pastWords = try XCTUnwrap(bodyChoice["conversationEnding"] as? String)
        XCTAssertTrue(app.staticTexts["past-ending"].label.hasPrefix(pastWords), "A script's choice is not credited to the captain")
        // INF-1879: photograph the past card's minus only once its body is drawn, not its incoming shell.
        showCard(chart)
        picture("past-body-choice")
        tapOnPhone(app.buttons["put-aside-card"])
        showCard(note)
        // INF-2553 (the captain: "to its place in the stack, with a short notice where you are"): a close the
        // computer refuses brings the card back where it was and says why on Home.
        let refusal = "This card changed on your computer. Look at it again."
        _ = try await home("refuse-next-change", body: #"{"channel":"inf:cards:close","words":"\#(refusal)"}"#)
        tapOnPhone(app.buttons["put-aside-card"])
        let notice = app.buttons["change-notice"]
        XCTAssertTrue(notice.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(notice.label, refusal)
        XCTAssertTrue(cardHeading(note).waitForPresence(timeout: 10), "A refused close puts the card back")
        picture("card-close-refused")
        tapOnPhone(notice)
        XCTAssertTrue(notice.waitForAbsence(timeout: 10))
        if UIDevice.current.userInterfaceIdiom == .phone {
            // INF-2553, the captain's pick for an iPhone on its side, where the pill has no room: the words stay on
            // the place's own line until its next change, so they are never cleared unseen. In a stack of two, the
            // card that came back keeps them while the other card is up.
            let asked = try await home("asked-card")
            let second = try XCTUnwrap(asked["title"] as? String)
            showCard(second)
            turnPhone(to: .landscapeLeft, in: app, moving: cardHeading(second))
            _ = try await home("refuse-next-change", body: #"{"channel":"inf:cards:close","words":"\#(refusal)"}"#)
            tapOnPhone(app.buttons["put-aside-card"])
            showCard(note)
            XCTAssertFalse(app.staticTexts["card-error"].exists, "The words stay with the card that came back")
            showCard(second)
            let line = app.staticTexts["card-error"]
            XCTAssertTrue(line.waitForPresence(timeout: 10), app.debugDescription)
            XCTAssertEqual(line.label, refusal)
            XCTAssertFalse(notice.exists, "On its side the words are on the card's line, not in a pill")
            picture("card-close-refused-on-its-side")
            // A message the computer refuses goes back in the box and says why on the composer's own line.
            let messageRefusal = "Your computer could not take this message. Try again."
            _ = try await home("refuse-next-change", body: #"{"channel":"inf:converse","words":"\#(messageRefusal)"}"#)
            let input = app.textFields["message-box"]
            let message = "Count the north buoys"
            focusForPhoneTyping(input, in: app); input.typeText(message)
            tapOnPhone(app.buttons["send-message"])
            let messageLine = app.staticTexts["message-problem"]
            XCTAssertTrue(messageLine.waitForPresence(timeout: 10), app.debugDescription)
            XCTAssertEqual(messageLine.label, messageRefusal)
            XCTAssertEqual(input.value as? String, message, "A refused message goes back in the box")
            XCTAssertFalse(notice.exists, "On its side the words are on the composer's line, not in a pill")
            picture("message-refused-on-its-side")
            turnPhone(to: .portrait, in: app, moving: cardHeading(second))
            // Upright, the pill may still show the words until they leave on their own, and the lines stay quiet.
            XCTAssertTrue(notice.waitForAbsence(timeout: 20))
            XCTAssertFalse(messageLine.exists, "Upright, the pill says it instead of the composer's line")
            // The words go back out of the box, so the rest of the journey starts from an empty one.
            focusForPhoneTyping(input, in: app)
            input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: message.count))
            let done = app.navigationBars.buttons["dismiss-phone-keyboard"]
            XCTAssertTrue(done.waitForPresence(timeout: 10), app.debugDescription); tapOnPhone(done)
            XCTAssertTrue(app.keyboards.firstMatch.waitForAbsence(timeout: 10))
            tapOnPhone(app.buttons["put-aside-card"])
            XCTAssertTrue(cardHeading(second).waitForAbsence(timeout: 10), app.debugDescription)
            showCard(note)
        }
        // A close the computer still holds has already taken the card off Home.
        _ = try await home("hold-card-action", body: #"{"channel":"inf:cards:close"}"#)
        tapOnPhone(app.buttons["put-aside-card"])
        _ = try await home("card-action-held")
        XCTAssertTrue(cardHeading(note).waitForAbsence(timeout: 10), "A close shows at the tap, before the computer answers")
        _ = try await home("release-card-action")
        let closed = try await home("card-state", method: "GET")
        XCTAssertNotNil(closed["note"] as? [String: Any])
        XCTAssertEqual(closed["leaks"] as? Int, 0)
        // INF-1060, the captain: "after cards are dismissed, it doesn't extend back". With the last card closed,
        // the message box keeps its place and the column's width at the foot of Home.
        verifyPhoneComposerBounds(app: app)
        picture("cards-answered-and-closed")
        // INF-1059, the captain's "why images couldn't render inline?": a picture card already in the stack when the
        // phone comes back is drawn from the first cards read while the board read is still out, so its picture is asked
        // before the computer is in reach. The phone asks for it once it is in reach, rather than keeping a broken box.
        _ = try await home("offline")
        outOfReach()
        let late = try await home("late-picture-card")
        let lateTitle = try XCTUnwrap(late["title"] as? String)
        _ = try await home("online")
        XCTAssertTrue(cardHeading(lateTitle).waitForPresence(timeout: 20), app.debugDescription)
        XCTAssertTrue(app.webViews.staticTexts[try XCTUnwrap(late["words"] as? String)].waitForPresence(timeout: 10))
        _ = try await home("board-read-held")
        _ = try await home("release-board-read")
        reach("In reach", timeout: 20)
        _ = try await home("late-picture-asked")
        picture("card-picture-after-reaching")
        tapOnPhone(app.buttons["put-aside-card"])
        XCTAssertTrue(cardHeading(lateTitle).waitForAbsence(timeout: 10))
        // The same after view in both themes supplies the release note's native hero pair.
        let hero = try await home("hero-card")
        showCard(try XCTUnwrap(hero["title"] as? String))
        XCTAssertTrue(app.webViews.staticTexts["Chart for daylight sailing"].waitForPresence(timeout: 10))
        verifyPhoneComposerBounds(app: app)
        picture("cards-hero-light")
        _ = try await home("appearance-dark", budget: displayBudget)
        XCTAssertTrue(app.webViews.staticTexts["Chart for night sailing"].waitForPresence(timeout: 10))
        verifyPhoneComposerBounds(app: app)
        picture("cards-hero-dark")
        _ = try await home("appearance-light", budget: displayBudget)
        // INF-944 item 5 with INF-945's pick: the Mac's row, pinned at the card's foot with no scrolling,
        // the default last at the right and every choice keeping a 44-point touch area.
        let keepChoice = app.buttons["card-action-keep"], waitChoice = app.buttons["card-action-wait"]
        XCTAssertTrue(waitForPhonePress(keepChoice), "The choices sit in view without scrolling")
        XCTAssertTrue(waitForPhonePress(waitChoice))
        // The answered count starts the first line, so the row wraps where its choices do not fit beside it.
        if abs(keepChoice.frame.midY - waitChoice.frame.midY) < 1 {
            XCTAssertLessThan(waitChoice.frame.maxX, keepChoice.frame.minX, "The default is drawn last")
        } else {
            XCTAssertGreaterThan(keepChoice.frame.minY, waitChoice.frame.minY, "The default is drawn last")
            XCTAssertEqual(keepChoice.frame.maxX, waitChoice.frame.maxX, accuracy: 1, "Each line sits at the trailing edge")
        }
        // XCUI reports the 44-point area in fractions of a pixel, such as 43.99999999999994.
        XCTAssertGreaterThanOrEqual(keepChoice.frame.height.rounded(), 44)
        XCTAssertLessThan(keepChoice.frame.width, app.scrollViews["card-scroll"].frame.width / 2, "A choice keeps its own width")
        // INF-944 item 3: a card minimized on the computer leaves the phone's stack.
        // INF-1517, the captain's picks: Home keeps no Minimized menu; the card waits in Tasks under Waiting on you,
        // in its own row since it has no task, and a tap brings it back on Home and on the computer.
        let heroTitle = try XCTUnwrap(hero["title"] as? String)
        _ = try await home("minimize-hero")
        XCTAssertTrue(cardHeading(heroTitle).waitForAbsence(timeout: 10), app.debugDescription)
        let pager = app.descendants(matching: .any).matching(identifier: "card-pager").firstMatch
        XCTAssertTrue(pager.waitForAbsence(timeout: 10), "Home shows no Minimized menu")
        tab("Tasks")
        let restore = app.buttons.matching(identifier: "minimized-card").matching(NSPredicate(format: "label == %@", heroTitle)).firstMatch
        XCTAssertTrue(restore.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertLessThan(app.buttons["group-waiting"].frame.minY, restore.frame.minY, "It is listed under Waiting on you")
        picture("tasks-minimized")
        if UIDevice.current.userInterfaceIdiom == .phone {
            // INF-2553: on an iPhone on its side, a bring-back the computer refuses puts the card aside again and says
            // why on the Tasks list's own line, as a refused bring-back did before.
            turnPhone(to: .landscapeLeft, in: app, moving: restore)
            _ = try await home("refuse-next-change", body: #"{"channel":"inf:cards:minimize","words":"\#(refusal)"}"#)
            tapOnPhone(restore)
            tab("Tasks")
            let asideLine = app.staticTexts["tasks-problem"]
            XCTAssertTrue(asideLine.waitForPresence(timeout: 10), app.debugDescription)
            XCTAssertEqual(asideLine.label, refusal)
            XCTAssertTrue(restore.waitForPresence(timeout: 10), "A refused bring-back puts the card aside again")
            XCTAssertFalse(app.buttons["change-notice"].exists, "On its side the words are on the list's line, not in a pill")
            picture("bring-back-refused-on-its-side")
            turnPhone(to: .portrait, in: app, moving: restore)
            XCTAssertTrue(app.buttons["change-notice"].waitForAbsence(timeout: 20))
        }
        tapOnPhone(restore)
        XCTAssertTrue(cardHeading(heroTitle).waitForPresence(timeout: 10), "Its row brings the card back on Home")
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "selected == true"), object: app.buttons["tab-home"], timeout: 10), .completed)
        let restored = try await home("hero-state", method: "GET")
        let restoredCard = try XCTUnwrap(restored["card"] as? [String: Any])
        XCTAssertNil(restoredCard["minimized"], "The phone brings it back on the computer too")
        // INF-209: the native frame remains usable at the largest standard Dynamic Type size.
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL"]
        try await launchPhoneApp(app)
        reach("In reach", timeout: 20)
        showCard(try XCTUnwrap(hero["title"] as? String))
        let largeChoice = app.buttons["card-action-keep"]
        reveal(largeChoice)
        XCTAssertEqual(largeChoice.label, "Use this entrance")
        picture("card-large-type")
    }
}
