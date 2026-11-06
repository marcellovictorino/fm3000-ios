import XCTest

/// The keyboard-pinned part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2568, the captain: "both the main chat input and a card's reply input don't always stay in viewport when ios
    /// keyboard is up. that makes typing very difficult". Data: the hero card, whose head and choices stay pinned around
    /// its body. Completion: with the keyboard up on the message box or the card's reply, upright, on its side and turned
    /// with the keyboard up, at one line and five, the field and the message box stay between the bar and the keyboard
    /// (KeyboardViewportProbe). Platform: either device's simulator with its software keyboard. Resources: this test's
    /// own fresh app and test home; no photo, signing material or real account.
    func testKeyboardOverPinnedCard() async throws {
        try await launchJoined()
        _ = try await home("empty-cards")
        let hero = try await home("hero-card")
        XCTAssertTrue(cardHeading(try XCTUnwrap(hero["title"] as? String)).waitForPresence(timeout: 10), app.debugDescription)
        waitForShownBodyRevealed()
        var failures: [String] = []
        let box = keyboardInput("message-box"), reply = keyboardInput("card-reply")
        focusForPhoneTyping(box, in: app); keyboardViewportProbe("message box, hero card", box, into: &failures)
        try await dismissKeyboardForProbe()
        turnForProbe(.landscapeLeft)
        focusForPhoneTyping(box, in: app); keyboardViewportProbe("message box, hero card, on its side", box, into: &failures)
        try await dismissKeyboardForProbe()
        // On a short stage the whole card scrolls, its reply inside.
        revealForProbe(reply, in: app.scrollViews["card-scroll"].firstMatch)
        focusForPhoneTyping(reply, in: app); keyboardViewportProbe("reply, hero card, on its side", reply, into: &failures)
        try await dismissKeyboardForProbe()
        turnForProbe(.portrait)
        revealForProbe(reply, in: app.scrollViews["card-scroll"].firstMatch)
        focusForPhoneTyping(reply, in: app); keyboardViewportProbe("reply, hero card", reply, into: &failures)
        turnForProbe(.landscapeLeft)
        keyboardViewportProbe("reply, hero card, turned on its side with the keyboard up", reply, into: &failures)
        turnForProbe(.portrait)
        keyboardViewportProbe("reply, hero card, turned upright again", reply, into: &failures)
        reply.typeText("\ntwo\nthree\nfour\nfive")
        keyboardViewportProbe("reply, hero card, five lines", reply, into: &failures)
        try await dismissKeyboardForProbe()
        focusForPhoneTyping(box, in: app); keyboardViewportProbe("message box, hero card, five-line reply draft", box, into: &failures)
        try await dismissKeyboardForProbe()
        finishKeyboardChecks(failures)
    }
}
