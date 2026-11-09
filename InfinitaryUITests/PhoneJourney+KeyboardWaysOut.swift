import XCTest

/// The keyboard-ways-out part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-3106, the report: "replying to a card/thread, the keyboard could not be closed", and the captain's Approve and
    /// build of direction B: a keyboard-down button inside the field beside the send arrow, a pull down anywhere on the
    /// card, its head included, a tap on the card's head and the bar's Done, on an iPhone and an iPad.
    /// Data: the first mate card with two choices and a two-message thread (`flip-card`). Completion: while the keyboard
    /// is up for the card's reply, on its face and its thread, or for the message box, the button shows before send on
    /// send's center line, at one line and two; each way out closes the keyboard and the typed words stay; the button is
    /// gone once the keyboard is down. Platform: either device's simulator with its software keyboard. Resources: this
    /// test's own fresh app and test home; no photo, signing material or real account.
    func testKeyboardWaysOut() async throws {
        try await launchJoined()
        let fixture = try await home("flip-card")
        let title = try XCTUnwrap(fixture["title"] as? String)
        let heading = cardHeading(title)
        XCTAssertTrue(heading.waitForPresence(timeout: 10), app.debugDescription)
        waitForShownBodyRevealed()
        var failures: [String] = []
        let reply = keyboardInput("card-reply"), box = keyboardInput("message-box")
        let hide = app.buttons["hide-keyboard"]
        XCTAssertFalse(hide.exists, "The keyboard-down button shows with the keyboard down")

        // The card's face: the button at one line and at two, a pull from the head, a tap on the head.
        revealForProbe(reply, in: app.scrollViews["card-scroll"].firstMatch)
        focusForPhoneTyping(reply, in: app)
        reply.typeText("Hold the four builds")
        hideButtonBesideSend("face, one line", send: app.buttons["send-reply"], into: &failures)
        picture("1-face-reply-one-line")
        reply.typeText("\nuntil the check ends")
        hideButtonBesideSend("face, two lines", send: app.buttons["send-reply"], into: &failures)
        picture("2-face-reply-two-lines")
        keyboardWayOut("face, the keyboard-down button", reply, keeps: "Hold the four builds", into: &failures) { tapOnPhone(hide) }
        XCTAssertTrue(hide.waitForAbsence(timeout: 5), "The keyboard-down button stays with the keyboard down")
        focusForPhoneTyping(reply, in: app)
        keyboardWayOut("face, a pull down from the head", reply, keeps: "Hold the four builds", into: &failures) { pullDown(from: heading) }
        focusForPhoneTyping(reply, in: app)
        keyboardWayOut("face, a tap on the head", reply, keeps: "Hold the four builds", into: &failures) { tapOnPhone(heading) }

        // The card's thread: the same button, pull and tap on the thread's head.
        let cue = app.buttons["thread-cue"]
        reveal(cue); tapOnPhone(cue)
        let threadTitle = app.staticTexts["thread-title"]
        XCTAssertTrue(threadTitle.waitForPresence(timeout: 10), app.debugDescription)
        focusForPhoneTyping(reply, in: app)
        hideButtonBesideSend("thread", send: app.buttons["send-reply"], into: &failures)
        picture("3-thread-reply")
        keyboardWayOut("thread, the keyboard-down button", reply, keeps: "Hold the four builds", into: &failures) { tapOnPhone(hide) }
        focusForPhoneTyping(reply, in: app)
        keyboardWayOut("thread, a pull down from the head", reply, keeps: "Hold the four builds", into: &failures) { pullDown(from: threadTitle) }
        focusForPhoneTyping(reply, in: app)
        keyboardWayOut("thread, a tap on the head", reply, keeps: "Hold the four builds", into: &failures) { tapOnPhone(threadTitle) }
        focusForPhoneTyping(reply, in: app)
        keyboardWayOut("thread, Done in the bar", reply, keeps: "Hold the four builds", into: &failures) {
            tapOnPhone(app.navigationBars.buttons["dismiss-phone-keyboard"])
        }
        let back = app.buttons["thread-return"]
        reveal(back); tapOnPhone(back)
        XCTAssertTrue(cue.waitForPresence(timeout: 10), app.debugDescription)

        // The message box keeps the same button before its own send.
        focusForPhoneTyping(box, in: app)
        box.typeText("Check the north buoy")
        hideButtonBesideSend("message box", send: app.buttons["send-message"], into: &failures)
        picture("4-message-box")
        keyboardWayOut("message box, the keyboard-down button", box, keeps: "Check the north buoy", into: &failures) { tapOnPhone(hide) }
        finishKeyboardChecks(failures)
    }

    /// The button shows before send, inside the field, on send's own center line.
    private func hideButtonBesideSend(_ situation: String, send: XCUIElement, into failures: inout [String]) {
        let hide = app.buttons["hide-keyboard"]
        guard hide.waitForPresence(timeout: 10), send.exists else {
            failures.append("KEYBOARD BUTTON \(situation): no keyboard-down button before send"); return
        }
        waitForSteadyTarget(hide)
        let line = "KEYBOARD BUTTON \(situation): hide \(hide.frame) send \(send.frame)"
        print(line)
        if abs(hide.frame.midY - send.frame.midY) > 1 || hide.frame.maxX > send.frame.minX + 1 || !hide.isHittable {
            failures.append(line)
        }
    }

    /// Records whether a way out closed the keyboard and kept the field's words.
    private func keyboardWayOut(_ situation: String, _ field: XCUIElement, keeps words: String,
                                into failures: inout [String], close: () -> Void) {
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForPresence(timeout: 10), "\(situation): no keyboard before the way out")
        close()
        let closed = keyboard.waitForAbsence(timeout: 5)
        let kept = (field.value as? String)?.contains(words) == true
        let line = "KEYBOARD WAY OUT \(situation): keyboard " + (closed ? "closed" : "stayed up") + (kept ? "" : ", words lost")
        print(line)
        if !closed || !kept { failures.append(line) }
    }

    /// A slow pull down, as a thumb pulls, starting on the element and ending well below it.
    private func pullDown(from element: XCUIElement) {
        waitForSteadyTarget(element)
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 160)), withVelocity: .slow, thenHoldForDuration: 0.1)
    }
}
