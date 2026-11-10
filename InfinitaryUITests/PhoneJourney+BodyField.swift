import XCTest

/// INF-3427, the captain's report: "when i tap on a textbox inside of a card body, the keyboard pops up, and the textbox
/// would no longer be in the viewport.. it gets scrolled away. so i can't see what i type". Data: the cards fixture's choice
/// card, whose body holds a labelled text input ("A note", value "Morning tide"), and the phone home's `field-card`, a
/// decision whose text box sits at the end of a longer body. Completion: with the keyboard up on the input, the input lies
/// wholly inside the card's visible scroller, below the bar and above the keyboard's drawn top and the message box, and
/// keeps the keyboard's focus; typed words show in it. On an iPhone on its side, where the room left is shorter than the
/// box, the box fills that room with its middle, where its line types, inside it. It fails when the body's page slides inside its own web view or
/// when the card's scroller leaves the field under its foot, as both did before.
extension PhoneJourney {
    func testCardBodyFieldKeyboard() async throws {
        try await launchJoined()
        let fixture = try await home("cards-fixture")
        let choice = try XCTUnwrap(fixture["choice"] as? String)
        showCard(choice)
        let boundary = "effect refused · network refused · parent refused · native refused"
        XCTAssertTrue(app.webViews.staticTexts[boundary].waitForPresence(timeout: 20), app.debugDescription)
        waitForShownBodyRevealed()
        let note = app.webViews.textFields["A note"].firstMatch
        XCTAssertTrue(note.waitForPresence(timeout: 10), app.debugDescription)
        reveal(note)
        var failures: [String] = []
        let resting = bodyFieldProbe("A as opened, before the tap", note, keyboardExpected: false, into: &failures)
        focusForPhoneTyping(note, in: app)
        bodyFieldProbe("A as opened, focused", note, since: resting, into: &failures)
        note.typeText(" and evening")
        bodyFieldProbe("A as opened, typed", note, since: resting, into: &failures)
        print("BODY FIELD value after typing: \(String(describing: note.value))")
        try await dismissKeyboardForProbe()
        bodyFieldProbe("A after the keyboard closed", note, keyboardExpected: false, into: &failures)
        // B: the card scrolled on so the note sits high in the card's visible scroller, as after reading down past it.
        let scroll = app.scrollViews["card-scroll"].firstMatch
        if scroll.exists, note.exists {
            let target = scroll.frame.minY + 60
            let dy = target - note.frame.midY
            if abs(dy) > 20 {
                let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: dy)), withVelocity: .slow, thenHoldForDuration: 0.3)
                waitForSteadyTarget(scroll)
            }
        }
        let high = bodyFieldProbe("B high in the card, before the tap", note, keyboardExpected: false, into: &failures)
        if note.isHittable {
            focusForPhoneTyping(note, in: app)
            bodyFieldProbe("B high in the card, focused", note, since: high, into: &failures)
            note.typeText(" tide")
            bodyFieldProbe("B high in the card, typed", note, since: high, into: &failures)
            try await dismissKeyboardForProbe()
        } else {
            print("BODY FIELD B skipped: the note is not hittable after the drag")
        }
        // C: a decision whose text box sits at the end of a longer body, upright, then D on its side.
        _ = try await home("empty-cards")
        let fieldCard = try await home("field-card")
        XCTAssertTrue(cardHeading(try XCTUnwrap(fieldCard["title"] as? String)).waitForPresence(timeout: 10), app.debugDescription)
        waitForShownBodyRevealed()
        let crew = app.webViews.textFields["Anything the crew should know"].firstMatch
        XCTAssertTrue(crew.waitForPresence(timeout: 10), app.debugDescription)
        reveal(crew)
        let resting2 = bodyFieldProbe("C long card, before the tap", crew, keyboardExpected: false, into: &failures)
        focusForPhoneTyping(crew, in: app)
        bodyFieldProbe("C long card, focused", crew, since: resting2, into: &failures)
        crew.typeText("Watch the first hour")
        bodyFieldProbe("C long card, typed", crew, since: resting2, into: &failures)
        print("BODY FIELD C value after typing: \(String(describing: crew.value))")
        try await dismissKeyboardForProbe()
        turnForProbe(.landscapeLeft)
        reveal(crew)
        let resting3 = bodyFieldProbe("D long card on its side, before the tap", crew, keyboardExpected: false, into: &failures)
        if crew.isHittable {
            focusForPhoneTyping(crew, in: app)
            bodyFieldProbe("D long card on its side, focused", crew, since: resting3, into: &failures)
            try await dismissKeyboardForProbe()
        } else {
            print("BODY FIELD D skipped: the text box is not hittable on its side")
        }
        turnForProbe(.portrait)
        finishKeyboardChecks(failures)
    }

    struct BodyFieldReading { let field: CGRect; let lead: CGRect; let body: CGRect; let scroll: CGRect }

    /// Records where the body's text input sits against the room it is visible in: the card's scroller, the bar's foot,
    /// the keyboard's drawn top and the message box. With `since`, also how far the body's page moved inside its own web
    /// view (its first paragraph against the web view's top) and how far the web view moved with the card's scroller.
    @discardableResult
    func bodyFieldProbe(_ situation: String, _ field: XCUIElement, keyboardExpected: Bool = true,
                        since: BodyFieldReading? = nil, into failures: inout [String]) -> BodyFieldReading {
        let leadWords = situation.hasPrefix("C") || situation.hasPrefix("D")
            ? "Choose when the next release goes out. Each window trades speed against how closely the crew can watch it."
            : "Your answer stays on your Mac."
        let keyboard = app.keyboards.firstMatch
        if keyboardExpected {
            XCTAssertTrue(keyboard.waitForPresence(timeout: 10), "\(situation): no keyboard")
        }
        let any = { (id: String) in self.app.descendants(matching: .any).matching(identifier: id).firstMatch }
        let scroll = app.scrollViews["card-scroll"].firstMatch
        let body = app.webViews.matching(identifier: "card-body").firstMatch
        let lead = app.webViews.staticTexts[leadWords].firstMatch
        let composer = any("phone-composer")
        var steady = PhoneSteadyReading<[CGRect]>()
        let still = NSPredicate { _, _ in
            steady.read(field.exists ? [keyboard.exists ? keyboard.frame : .null, field.frame, scroll.frame, body.frame,
                                        lead.exists ? lead.frame : .null, composer.exists ? composer.frame : .null] : nil)
        }
        let held = waitForPhonePredicate(still, object: nil, timeout: 10)
        let window = app.windows.firstMatch.frame
        // XCUITest's keyboard frame is its keys alone. The suggestion row and, on an iPhone, WebKit's form bar (previous,
        // next, Done) stand above them in the keyboard's own container, whose top is where the card stops showing.
        let keyTop: CGFloat = {
            guard keyboard.exists else { return window.maxY }
            let tops = app.otherElements.containing(.keyboard, identifier: nil).allElementsBoundByIndex.map(\.frame.minY)
                .filter { $0 > window.minY + 0.5 && $0 < keyboard.frame.minY }
            return tops.max() ?? keyboard.frame.minY
        }()
        let bar = app.navigationBars.firstMatch
        let barFoot = bar.exists ? bar.frame.maxY : window.minY
        let f = field.frame
        let top = max(scroll.exists ? scroll.frame.minY : window.minY, barFoot)
        var foot = min(scroll.exists ? scroll.frame.maxY : window.maxY, keyTop)
        if composer.exists { foot = min(foot, composer.frame.minY) }
        var problems: [String] = []
        if f.height > foot - top {
            // An iPhone on its side leaves less room than the box is tall: the box fills it, its typing line in the middle.
            if f.minY > top + 0.5 || f.maxY < foot - 0.5 || f.midY < top || f.midY > foot {
                problems.append(String(format: "the room is %.0f pt, shorter than the box, and the box does not fill it with its middle inside", foot - top))
            }
        } else {
            if f.minY < top - 0.5 { problems.append(String(format: "its top is %.0f pt above the visible card's top", top - f.minY)) }
            if f.maxY > foot + 0.5 { problems.append(String(format: "its foot is %.0f pt below the visible card's foot", f.maxY - foot)) }
        }
        if f.maxY < top || f.minY > foot { problems.append("it is wholly out of view") }
        if keyboardExpected && field.exists {
            let focused = (field.value(forKey: "hasKeyboardFocus") as? Bool) ?? false
            if !focused { problems.append("it lost the keyboard's focus") }
        }
        let reading = BodyFieldReading(field: f, lead: lead.exists ? lead.frame : .null, body: body.frame, scroll: scroll.frame)
        var moves = ""
        if let since {
            let pageShift = (reading.lead.minY - reading.body.minY) - (since.lead.minY - since.body.minY)
            let viewShift = reading.body.minY - since.body.minY
            moves = String(format: " page-inside-webview moved %.0f pt, webview moved %.0f pt, field moved %.0f pt",
                           pageShift, viewShift, reading.field.minY - since.field.minY)
        }
        let line = "BODY FIELD \(situation): held \(held == .completed) field \(f) visible \(top)...\(foot) keyboard "
            + (keyboard.exists ? "\(keyboard.frame) drawn-top \(keyTop)" : "absent")
            + " bar-foot \(barFoot) card-scroll \(scroll.exists ? "\(scroll.frame)" : "absent") card-body \(body.frame)"
            + " lead \(reading.lead) composer \(composer.exists ? "\(composer.frame)" : "absent") window \(window)" + moves + " -> "
            + (problems.isEmpty ? "in view" : problems.joined(separator: "; "))
        print(line)
        picture("body field " + situation)
        if !problems.isEmpty { failures.append(line) }
        return reading
    }
}
