import XCTest

/// The cards-revise part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2565, the captain: "when the card content gets updated, it will automatically flip to the card side, which is
    /// disruptive when the user is reading the chat thread. i don't think we should auto flip. at most we should show an
    /// indicator near the "< card" button to show there's an update".
    /// Data: a first mate card with two choices and a two-message thread, then the first mate's revision of its body,
    /// which carries its answer to the captain's question (INF-2225: a handoff line leaves the question waiting).
    /// Completion: the revision's own thread line and its answer reach the phone; the card still shows its back, Card
    /// carries the update's mark, and Card turns to a face that draws the revised body.
    func testRevisionKeepsTheThreadShowing() async throws {
        try await launchJoined()
        let fixture = try await home("flip-card")
        let title = try XCTUnwrap(fixture["title"] as? String)
        let mate = try XCTUnwrap(fixture["mate"] as? String)
        XCTAssertTrue(cardHeading(title).waitForPresence(timeout: 10), app.debugDescription)
        waitForShownBodyRevealed()
        let cue = app.buttons["thread-cue"]
        XCTAssertTrue(cue.waitForPresence(timeout: 10), app.debugDescription)
        reveal(cue); tapOnPhone(cue)
        let back = app.descendants(matching: .any).matching(identifier: "card-back").firstMatch
        XCTAssertTrue(back.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(back.staticTexts[mate].waitForPresence(timeout: 10), app.debugDescription)
        let count = app.staticTexts["thread-count"]
        XCTAssertEqual(count.label, "THREAD · 2")
        picture("1-thread-open-before-revision")
        let revised = try await home("flip-card-revise")
        let added = try XCTUnwrap(revised["added"] as? String)
        XCTAssertNotEqual(fixture["offerId"] as? String, revised["offerId"] as? String, "The revision kept its offer")
        // The revision has reached the phone once the thread counts its "revised:" line and the answer after it, on
        // whichever side shows.
        let arrived = NSPredicate { _, _ in
            (count.exists && count.label == "THREAD · 4") || (cue.exists && cue.label.hasSuffix("4"))
        }
        XCTAssertEqual(waitForPhonePredicate(arrived, object: nil, timeout: 20), .completed, app.debugDescription)
        picture("2-after-revision")
        XCTAssertTrue(back.exists, "A revision turned the card back to its face while its thread showed\n\(app.debugDescription)")
        let cardButton = app.buttons["thread-return"]
        XCTAssertTrue(cardButton.exists, "The back's Card button is gone after the revision")
        XCTAssertFalse(cue.exists, "The face's latest line shows after the revision, so the card turned to its face")
        XCTAssertEqual(cardButton.value as? String, "updated", "Card carries no mark for the revision behind the thread")
        reveal(cardButton); tapOnPhone(cardButton)
        XCTAssertTrue(app.webViews.staticTexts[added].waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(cue.waitForPresence(timeout: 10), app.debugDescription)
        picture("3-face-after-revision")
    }
}
