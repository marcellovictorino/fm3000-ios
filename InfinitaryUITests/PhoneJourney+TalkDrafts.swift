import XCTest

/// The talk-drafts part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2125 direction C, the third talk test: a draft kept out of reach, a lost reply, homes of other versions,
    /// paging keys after a relaunch and Command-Return.
    func testDraftsAcrossHomes() async throws {
        let fixture = try await launchWithLastTurn()
        try await draftsAcrossHomes(try XCTUnwrap(fixture["text"] as? String))
    }

    private func draftsAcrossHomes(_ words: String) async throws {
        let input = app.textFields["message-box"]
        // The talk part's writes before its draft: every write is the captain's, as the steered task's were.
        let talkState = try await home("talk-state", method: "GET")
        let allWrites = try XCTUnwrap(talkState["writes"] as? [[String: Any]])
        for write in allWrites { XCTAssertEqual((write["actor"] as? [String: Any])?["kind"] as? String, "captain") }
        focusForPhoneTyping(input, in: app); input.typeText("Keep this unsent draft")
        _ = try await home("offline")
        outOfReach()
        XCTAssertFalse(app.buttons["send-message"].isEnabled)
        verifyPhoneComposerBounds(app: app)
        picture("offline-draft")
        _ = try await home("online")
        reach("In reach", timeout: 20)
        let after = try await home("talk-state", method: "GET")
        XCTAssertEqual((after["writes"] as? [Any])?.count, allWrites.count, "Reconnecting never sends the retained draft")
        XCTAssertEqual(input.value as? String, "Keep this unsent draft")
        // INF-2553 (the captain: "the box clears and the message shows as the last turn marked sending", and a lost
        // answer stays shown "until the next snapshot after reconnecting says otherwise"): the connection drops
        // before the computer takes this message, so it stays marked sending while out of reach, and the first last
        // turn read after reconnecting takes it back with the unconfirmed words and the draft.
        let lastYou = app.staticTexts["last-turn-you"]
        _ = try await home("lose-reply", body: #"{"before":true}"#)
        tapOnPhone(app.buttons["send-message"])
        outOfReach(app.debugDescription)
        XCTAssertTrue(app.staticTexts["last-turn-sending"].exists, "A message whose answer was lost stays marked sending")
        XCTAssertEqual(lastYou.label, "Keep this unsent draft")
        XCTAssertNotEqual(input.value as? String, "Keep this unsent draft", "The box stays clear while the answer is unknown")
        verifyPhoneComposerBounds(app: app)
        picture("unconfirmed-send")
        _ = try await home("online")
        reach("In reach", timeout: 20)
        let unconfirmed = app.buttons["change-notice"]
        XCTAssertTrue(unconfirmed.waitForPresence(timeout: 20), app.debugDescription)
        XCTAssertEqual(unconfirmed.label, "Could not confirm the change. Check your computer before sending it again.")
        XCTAssertFalse(app.staticTexts["last-turn-sending"].exists, "The snapshot after reconnecting takes the message back")
        XCTAssertEqual(input.value as? String, "Keep this unsent draft", "A message taken back returns to the box")
        picture("unconfirmed-send-taken-back")
        tapOnPhone(unconfirmed)
        XCTAssertTrue(unconfirmed.waitForAbsence(timeout: 10))
        let lostBefore = try await home("talk-state", method: "GET")
        XCTAssertEqual((lostBefore["writes"] as? [Any])?.count, allWrites.count, "The computer never took the lost message")
        // This time the computer takes the message before the connection drops, so the first last turn read after
        // reconnecting keeps it, quietly.
        _ = try await home("lose-reply")
        tapOnPhone(app.buttons["send-message"])
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value != %@", "Keep this unsent draft"), object: input, timeout: 10), .completed,
                       "The box clears at the tap")
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "label == %@", "Keep this unsent draft"), object: lastYou, timeout: 10), .completed,
                       app.debugDescription)
        verifyPhoneComposerBounds(app: app)
        picture("lost-answer-kept")
        _ = try await home("online")
        reach("In reach", timeout: 20)
        XCTAssertTrue(app.staticTexts["last-turn-sending"].waitForAbsence(timeout: 20), "The snapshot after reconnecting settles the message")
        XCTAssertEqual(lastYou.label, "Keep this unsent draft", "The message the computer holds stays the last turn")
        XCTAssertFalse(app.buttons["change-notice"].exists, "A change the computer holds is never taken back")
        let once = try await home("talk-state", method: "GET")
        XCTAssertEqual((once["writes"] as? [Any])?.count, allWrites.count + 1, "A lost reply never repeats the mutation")
        // The draft the next sections carry across homes, typed again.
        focusForPhoneTyping(input, in: app); input.typeText("Keep this unsent draft")
        _ = try await home("read-only")
        reach("In reach", timeout: 20)
        XCTAssertFalse(app.buttons["send-message"].isEnabled, "A version-mismatched view can read but cannot act")
        // INF-1649: the line names the side to update; a home past the phone's floor means this phone.
        XCTAssertEqual(app.staticTexts["connection-refusal"].label, "Update Infinitary on this phone to make changes.")
        verifyPhoneComposerBounds(app: app)
        picture("read-only-draft")
        // INF-1649, the captain's direction A: a newer home whose major kept views answers this phone in full.
        _ = try await home("within-floor")
        reach("In reach", timeout: 20)
        XCTAssertTrue(app.staticTexts["connection-refusal"].waitForAbsence(timeout: 20), "Within the floor nothing refuses a change")
        // INF-2755: while the phone redials, its words still say In reach and the refusal line is already gone (INF-2668),
        // but changes wait for contact with full access, so the send button is waited for rather than read once.
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "enabled == true"), object: app.buttons["send-message"], timeout: 20),
                       .completed, "A view within the home's floor can act")
        XCTAssertEqual(input.value as? String, "Keep this unsent draft")
        picture("within-floor-draft")
        // INF-1649 review R8: a change across majors reaches the newer home: the kept draft sends once.
        tapOnPhone(app.buttons["send-message"])
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value != %@", "Keep this unsent draft"), object: input, timeout: 20), .completed)
        let olderView = try await home("talk-state", method: "GET")
        let olderViewWrites = try XCTUnwrap(olderView["writes"] as? [[String: Any]])
        XCTAssertEqual(olderViewWrites.count, try XCTUnwrap(once["writes"] as? [Any]).count + 1, "A view within the floor changes things on a newer home")
        XCTAssertEqual(olderViewWrites.last?["channel"] as? String, "inf:converse")
        XCTAssertEqual((olderViewWrites.last?["args"] as? [[String: Any]])?.first?["text"] as? String, "Keep this unsent draft")
        // A home older than this phone's floor: the line names the computer, and the draft waits.
        focusForPhoneTyping(input, in: app); input.typeText("Sent to an older computer")
        _ = try await home("older-home")
        reach("In reach", timeout: 20)
        XCTAssertTrue(app.staticTexts["connection-refusal"].waitForPresence(timeout: 20))
        XCTAssertEqual(app.staticTexts["connection-refusal"].label, "Update Infinitary on your computer to make changes.")
        XCTAssertFalse(app.buttons["send-message"].isEnabled, "A view newer than the home's reach can read but cannot act")
        picture("older-home-draft")
        // A home at this phone's floor answers it in full, and the draft sends there.
        _ = try await home("older-home-within")
        reach("In reach", timeout: 20)
        XCTAssertTrue(app.staticTexts["connection-refusal"].waitForAbsence(timeout: 20), "On a home its floor reaches nothing refuses a change")
        // INF-2755: the same redial as within the floor, so the send button is waited for before the tap.
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "enabled == true"), object: app.buttons["send-message"], timeout: 20),
                       .completed, "A view its home's floor reaches can act")
        XCTAssertEqual(input.value as? String, "Sent to an older computer")
        tapOnPhone(app.buttons["send-message"])
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value != %@", "Sent to an older computer"), object: input, timeout: 20), .completed)
        let newerView = try await home("talk-state", method: "GET")
        let newerViewWrites = try XCTUnwrap(newerView["writes"] as? [[String: Any]])
        XCTAssertEqual(newerViewWrites.count, olderViewWrites.count + 1, "A newer view changes things on an older home its floor reaches")
        XCTAssertEqual((newerViewWrites.last?["args"] as? [[String: Any]])?.first?["text"] as? String, "Sent to an older computer")

        // INF-355: exercise first-after-relaunch paging and Send after the original journey.
        // Earlier relaunches here would erase that journey's in-session past-card prerequisite.
        // Keep all original button-based Send, photo, card and refusal checks unchanged.
        app.terminate()
        _ = try await home("offline")
        _ = try await home("online")
        let keyCards = try await home("cards-fixture")
        let choice = try XCTUnwrap(keyCards["choice"] as? String)
        let chart = try XCTUnwrap(keyCards["conversation"] as? String)
        try await launchPhoneApp(app)
        XCTAssertTrue(app.scrollViews["card-scroll"].waitForPresence(timeout: 20))
        showCard(choice)
        XCTAssertTrue(app.buttons["next-card"].isEnabled)
        computerDetails()
        try await pressPhoneKey("]", modifiers: [.command, .shift], in: app)
        tapOnPhone(app.buttons["close-computer-details"])
        XCTAssertTrue(cardHeading(choice).waitForPresence(timeout: 10), "A sheet keeps its pager shortcut from the stage behind it")
        try await pressPhoneKey("]", modifiers: [.command, .shift], in: app)
        XCTAssertTrue(cardHeading(chart).waitForPresence(timeout: 10))
        app.terminate(); try await launchPhoneApp(app)
        XCTAssertTrue(app.scrollViews["card-scroll"].waitForPresence(timeout: 20))
        showCard(chart)
        XCTAssertTrue(app.buttons["previous-card"].isEnabled)
        try await pressPhoneKey("[", modifiers: [.command, .shift], in: app)
        XCTAssertTrue(cardHeading(choice).waitForPresence(timeout: 10))

        // INF-82: Command-Return sends the complete multiline ask once, not merely hides a keyboard.
        app.terminate(); try await launchPhoneApp(app)
        reach("In reach", timeout: 20)
        XCTAssertTrue(input.waitForPresence(timeout: 10))
        // A multiline field exposes its empty value differently from placeholderValue.
        // Read that state before typing, then require Send to restore it.
        let emptyDraft = try XCTUnwrap(input.value as? String)
        let keyboardWords = words + "\nUse the photo from my earlier message."
        focusForPhoneTyping(input, in: app); input.typeText(keyboardWords)
        XCTAssertEqual(input.value as? String, keyboardWords)
        XCTAssertTrue(app.buttons["send-message"].isEnabled)
        try await pressPhoneKey(XCUIKeyboardKey.return.rawValue, modifiers: .command, in: app)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value == %@", emptyDraft), object: input, timeout: 20), .completed)
        let keySent = try await home("talk-state", method: "GET")
        let keyWrites = try XCTUnwrap(keySent["writes"] as? [[String: Any]])
        XCTAssertEqual(keyWrites.count, newerViewWrites.count + 1)
        let keyMessage = try XCTUnwrap(keyWrites.last)
        XCTAssertEqual(keyMessage["channel"] as? String, "inf:converse")
        XCTAssertEqual((keyMessage["actor"] as? [String: Any])?["kind"] as? String, "captain")
        let keyPayload = try XCTUnwrap((keyMessage["args"] as? [[String: Any]])?.first)
        XCTAssertEqual(keyPayload["text"] as? String, keyboardWords)
        XCTAssertEqual((keyPayload["images"] as? [Any])?.count, 0)
        picture("sent-by-keyboard")
    }
}
