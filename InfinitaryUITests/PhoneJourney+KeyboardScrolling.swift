import XCTest

/// The keyboard-scrolling part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2568, the same report and the captain's added ask: "scrolling a card should dismiss the keyboard if keyboard is
    /// up". Data: the merge card, whose facts and required actions make the whole card scroll with its reply inside on
    /// the iPhone; on the iPad it fits whole above the keyboard, so there the flicks check a card that fits (INF-2737).
    /// Completion: a reply growing to three lines stays above the card's lower edge, upright and on its side; a flick of
    /// the card with the keyboard up, from the reply or the message box, closes the keyboard. Platform and resources as testKeyboardOverPinnedCard; the merge fixture runs once per home.
    func testKeyboardOverScrollingCard() async throws {
        try await launchJoined()
        _ = try await home("empty-cards")
        let merge = try await home("merge-card")
        XCTAssertTrue(cardHeading(try XCTUnwrap(merge["title"] as? String)).waitForPresence(timeout: 10), app.debugDescription)
        waitForShownBodyRevealed()
        waitForFactsStripRevealed()
        var failures: [String] = []
        let box = keyboardInput("message-box"), reply = keyboardInput("card-reply")
        let scroll = app.scrollViews["card-scroll"].firstMatch
        revealForProbe(reply, in: scroll)
        focusForPhoneTyping(reply, in: app); keyboardViewportProbe("reply, merge card", reply, into: &failures)
        reply.typeText("one\ntwo\nthree")
        keyboardViewportProbe("reply, merge card, three lines", reply, into: &failures)
        keyboardAfterScroll("reply focused, flick the card up", into: &failures) { flickForProbe(scroll) }
        focusForPhoneTyping(box, in: app)
        keyboardAfterScroll("message box focused, flick the card up", into: &failures) { flickForProbe(scroll) }
        turnForProbe(.landscapeLeft)
        revealForProbe(reply, in: scroll)
        focusForPhoneTyping(reply, in: app); keyboardViewportProbe("reply, merge card, three lines, on its side", reply, into: &failures)
        try await dismissKeyboardForProbe()
        turnForProbe(.portrait)
        finishKeyboardChecks(failures)
    }

    /// INF-3182 / INF-3200: the merge card's fact strip draws in a web view of its own in the card's foot, above the reply,
    /// after the body has drawn. Until it reveals it holds a placeholder height, and its drawn height then pushes the reply
    /// down; on the iPad a tap read the reply's point just before that move and landed above the field, which never began
    /// editing. The strip reveals only once its drawn height is the foot's own geometry (CardWebHost.revealIfShown), so
    /// the reply holds its place from then and its steady check reads where it will stay.
    private func waitForFactsStripRevealed() {
        let facts = app.webViews.matching(identifier: "card-facts").firstMatch
        XCTAssertTrue(facts.waitForPresence(timeout: 20), app.debugDescription)
        let revealed = NSPredicate { _, _ in facts.descendants(matching: .any).firstMatch.exists }
        XCTAssertEqual(waitForPhonePredicate(revealed, object: nil, timeout: 20), .completed, "The merge card's fact strip was never revealed")
    }

    /// The captain's added ask: "scrolling a card should dismiss the keyboard if keyboard is up". Records the scroll that
    /// leaves the keyboard up.
    private func keyboardAfterScroll(_ situation: String, into failures: inout [String], scroll: () -> Void) {
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForPresence(timeout: 10), "\(situation): no keyboard before the scroll")
        scroll()
        let closed = keyboard.waitForAbsence(timeout: 5)
        let line = "KEYBOARD SCROLL \(situation): keyboard " + (closed ? "closed" : "stayed up")
        print(line)
        picture("keyboard scroll " + situation)
        if !closed { failures.append(line) }
    }

    /// One short flick up from the card's lower part, as a person scrolls to read on; it ends above the keyboard.
    private func flickForProbe(_ scroll: XCUIElement) {
        let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        start.press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
    }
}
