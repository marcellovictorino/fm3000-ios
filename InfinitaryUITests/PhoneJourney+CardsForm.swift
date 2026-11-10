import XCTest

/// The cards-form part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2125 direction C, the second cards test: the form's boundary, its stalls and retries, paging, a pick and a choice.
    func testCardForm() async throws {
        app.launchEnvironment["INFINITARY_TEST_RETRIED_CARD_LAG"] = "3"
        try await launchJoined()
        try await verifyCardForm()
    }

    /// The frames of a body and its first text with this label, from the first snapshot that holds the text.
    private func firstShown(_ label: String, in body: XCUIElement) -> (body: CGRect, text: CGRect) {
        var found: (body: CGRect, text: CGRect)?
        let read = NSPredicate { _, _ in
            guard let shot = try? body.snapshot() else { return false }
            var stack: [XCUIElementSnapshot] = [shot]
            while let next = stack.popLast() {
                if next.elementType == .staticText && next.label == label { found = (shot.frame, next.frame); return true }
                stack.append(contentsOf: next.children)
            }
            return false
        }
        XCTAssertEqual(waitForPhonePredicate(read, object: nil, timeout: 10), .completed, app.debugDescription)
        return found ?? (.null, .zero)
    }

    /// INF-3400: a swipe has turned the row once the pager has moved and the only card title left is the one it brought;
    /// while the row moves, the card beside the shown one is built and its title matches too.
    private func settleOn(_ title: String, leaving place: String, pager: XCUIElement) {
        let titles = app.staticTexts.matching(identifier: "card-title")
        let settled = NSPredicate { _, _ in
            pager.label != place && titles.count == 1 && titles.firstMatch.label == title
        }
        XCTAssertEqual(waitForPhonePredicate(settled, object: nil, timeout: 10), .completed,
                       "The row never settled on \(title) from \(place): pager \(pager.label)\n\(app.debugDescription)")
    }

    private func verifyCardForm() async throws {
        let fixture = try await home("cards-fixture")
        let choice = try XCTUnwrap(fixture["choice"] as? String)
        let chart = try XCTUnwrap(fixture["conversation"] as? String)
        showCard(choice)
        let boundary = "effect refused · network refused · parent refused · native refused"
        XCTAssertTrue(app.webViews.staticTexts[boundary].waitForPresence(timeout: 20), app.debugDescription)
        // INF-209's native card chrome promises 44-point touch targets, not padding outside a tiny button.
        for id in ["put-aside-card", "previous-card", "next-card", "card-pager"] {
            let control = app.descendants(matching: .any).matching(identifier: id).firstMatch
            // Accessibility geometry can represent 44 as 43.999999999999986.
            XCTAssertGreaterThanOrEqual(control.frame.width + 0.001, 44, id)
            XCTAssertGreaterThanOrEqual(control.frame.height + 0.001, 44, id)
        }
        picture("card-form-before-answer")
        _ = try await home("appearance-dark", budget: displayBudget)
        XCTAssertTrue(app.webViews.staticTexts["Night chart"].waitForPresence(timeout: 10))
        picture("card-form-dark")
        _ = try await home("appearance-light", budget: displayBudget)
        XCTAssertTrue(app.webViews.staticTexts["Day chart"].waitForPresence(timeout: 10))
        let before = try await home("card-state", method: "GET")
        XCTAssertEqual(before["leaks"] as? Int, 0)
        let beforeCalls = try XCTUnwrap(before["calls"] as? [[String: Any]])
        XCTAssertTrue(beforeCalls.contains { $0["channel"] as? String == "inf:cards:seen-update" })
        let leaveFrame = app.webViews.buttons["Try to leave the card"]
        reveal(leaveFrame); tapOnPhone(leaveFrame)
        // A loaded child cannot navigate away or contact the loopback endpoint; the form journey still works below.
        XCTAssertTrue(app.webViews.staticTexts[boundary].waitForPresence(timeout: 10))
        let afterNavigation = try await home("card-state", method: "GET")
        XCTAssertEqual(afterNavigation["leaks"] as? Int, 0)
        XCTAssertFalse(beforeCalls.contains { $0["channel"] as? String == "inf:cards:act" })
        let stall = app.webViews.buttons["Stall the card"]
        reveal(stall); tapOnPhone(stall)
        XCTAssertTrue(app.buttons["retry-card"].waitForPresence(timeout: 20), app.debugDescription)
        picture("card-recovery")
        tapOnPhone(app.buttons["retry-card"])
        XCTAssertTrue(app.webViews.staticTexts[boundary].waitForPresence(timeout: 20), app.debugDescription)

        let choose = app.buttons["card-action-choose"]
        // INF-1070 / INF-1574: the retried card takes taps only once its body is revealed at its drawn height, which
        // enables its footer; its text exists sooner.
        waitUntilEnabled(choose)
        let stalledAnswer = app.webViews.buttons["Stall the next answer"]
        reveal(stalledAnswer); tapOnPhone(stalledAnswer)
        reveal(choose); tapOnPhone(choose)
        XCTAssertTrue(app.staticTexts["This card did not answer. Your choice was not sent."].waitForPresence(timeout: 10))
        XCTAssertTrue(app.buttons["retry-card"].waitForPresence(timeout: 15))
        XCTAssertTrue(app.buttons["put-aside-card"].isEnabled, "A stalled form cannot keep native chrome busy")
        tapOnPhone(app.buttons["retry-card"])
        XCTAssertTrue(app.webViews.staticTexts[boundary].waitForPresence(timeout: 20))
        waitUntilEnabled(choose)
        reveal(choose); tapOnPhone(choose)
        XCTAssertTrue(app.staticTexts["Answer each required question first."].waitForPresence(timeout: 10))
        let refused = try await home("card-state", method: "GET")
        XCTAssertNil(refused["choice"] as? [String: Any])
        showCard(chart); showCard(choice)
        // INF-3110: a sideways swipe anywhere on the card changes cards, the head's and the body's alike; swiping left
        // brings the next card and right the one before.
        let pager = app.descendants(matching: .any).matching(identifier: "card-pager").firstMatch
        let first = pager.label
        app.staticTexts["card-title"].swipeLeft()
        settleOn(chart, leaving: first, pager: pager)
        waitForShownBodyRevealed()
        // The swipe starts inside the body, near its top, which shows under the head whatever the body's length.
        // INF-3400: it travels to the body's far side, a share of the card's own width, so it slides on by distance on an
        // iPad's full-width card as on an iPhone's, never only by a flick a busy runner may measure as slow.
        let body = app.webViews.matching(identifier: "card-body").firstMatch
        let inBody = body.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0)).withOffset(CGVector(dx: 0, dy: 24))
        let farSide = body.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0)).withOffset(CGVector(dx: 0, dy: 24))
        let second = pager.label
        inBody.press(forDuration: 0.05, thenDragTo: farSide, withVelocity: .fast, thenHoldForDuration: 0)
        settleOn(choice, leaving: second, pager: pager)
        waitForShownBodyRevealed()
        picture("card-row")
        let place = pager.label
        // A drag that starts on the body's own slider moves the slider and never the card.
        // The swipe back builds the card it brings anew, and its body's controls reach accessibility after its first words.
        let depth = app.webViews.sliders["Chart depth"]
        XCTAssertTrue(depth.waitForPresence(timeout: 10), app.debugDescription)
        reveal(depth)
        let thumb = depth.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        thumb.press(forDuration: 0.05, thenDragTo: depth.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)),
                    withVelocity: .slow, thenHoldForDuration: 0.2)
        let moved = NSPredicate { [app] _, _ in
            app.webViews.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Chart depth' AND label != 'Chart depth 8'")).firstMatch.exists
        }
        XCTAssertEqual(waitForPhonePredicate(moved, object: nil, timeout: 10), .completed, app.debugDescription)
        XCTAssertTrue(cardHeading(choice).exists, "A drag on the body's slider changed cards")
        // A mostly upward drag scrolls the card and never changes cards.
        let scroll = app.scrollViews["card-scroll"]
        let middle = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        middle.press(forDuration: 0.05, thenDragTo: middle.withOffset(CGVector(dx: -30, dy: -160)), withVelocity: .slow, thenHoldForDuration: 0.2)
        XCTAssertTrue(cardHeading(choice).exists, "An upward drag on the card changed cards")
        XCTAssertEqual(pager.label, place)
        // INF-1263: the paged-back body offers its text only where a tap reaches it. Read the body and the text in one
        // snapshot the moment the text appears; before the fix it appeared while the body was its 48-point placeholder.
        // INF-1651: iOS 27.0 first reports the text's frame relative to the web view, so where the text sits is read
        // once it settles.
        let shown = firstShown("North Basin", in: body)
        let north = app.webViews.staticTexts["North Basin"].firstMatch
        let settled = NSPredicate { _, _ in body.frame.contains(north.frame) }
        XCTAssertEqual(waitForPhonePredicate(settled, object: nil, timeout: 10), .completed,
                       "North Basin \(north.frame) lies outside the card body \(body.frame)")
        XCTAssertEqual(shown.body.height, body.frame.height, accuracy: 0.5,
                       "North Basin appeared before the card body held its drawn height")
        reveal(north); tapOnPhone(north)
        let marker = app.webViews.buttons["Move the marker"]
        reveal(marker)
        _ = try await home("capture-card-start")
        tapOnPhone(marker)
        XCTAssertTrue(app.webViews.staticTexts["Marker inside the harbour"].waitForPresence(timeout: 10))
        // The native draft owner must have observed the required pick before paging can remount the document.
        waitForAnsweredPhoneForm(in: app)
        picture("card-form-picked")
        _ = try await home("capture-stop")
        _ = try await home("capture-page-start")
        tapOnPhone(app.buttons["next-card"])
        XCTAssertTrue(cardHeading(chart).waitForPresence(timeout: 10))
        tapOnPhone(app.buttons["previous-card"])
        XCTAssertTrue(cardHeading(choice).waitForPresence(timeout: 10))
        _ = try await home("capture-stop")
        // Paging remounts the document; the named answers and staged value still leave together.
        // INF-1086 / INF-1574: the remounted card's footer stays disabled until its body is revealed at its drawn height.
        let settings = app.buttons["card-action-settings"]
        waitUntilEnabled(settings)
        reveal(settings); tapOnPhone(settings)
        XCTAssertTrue(app.staticTexts["Do this on Test Mac mini."].waitForPresence(timeout: 10))
        let unsent = try await home("card-state", method: "GET")
        XCTAssertFalse((unsent["calls"] as? [[String: Any]] ?? []).contains { $0["channel"] as? String == "inf:cards:act" })
        // INF-1122: a drawn footer is not proof the remounted form restored its required answer.
        // Wait on the native form reading, then the actual action gate, never on a quiet interval.
        waitForAnsweredPhoneForm(in: app)
        waitUntilEnabled(choose)
        reveal(choose); tapOnPhone(choose)
        let dismissed = cardHeading(choice).waitForAbsence(timeout: 10)
        if !dismissed {
            do {
                let state = try await home("card-state", method: "GET")
                print("Card dismissal failure state: \(state)")
                let attachment = XCTAttachment(string: String(describing: state))
                attachment.name = "card-dismissal-state"; attachment.lifetime = .keepAlways; add(attachment)
            } catch { print("Card dismissal state could not be read: \(error)") }
        }
        XCTAssertTrue(dismissed, app.debugDescription)
        let answered = try await home("card-state", method: "GET")
        let past = try XCTUnwrap(answered["choice"] as? [String: Any])
        let answers = try XCTUnwrap(past["answers"] as? [[String: Any]])
        XCTAssertEqual(answers.first { $0["name"] as? String == "harbour" }?["values"] as? [String], ["north"])
        let chartValue = try XCTUnwrap((answers.first { $0["name"] as? String == "chart" }?["values"] as? [String])?.first)
        let chartData = try XCTUnwrap(chartValue.data(using: .utf8))
        XCTAssertEqual((try JSONSerialization.jsonObject(with: chartData) as? [String: Int])?["zoom"], 2)
        XCTAssertEqual((past["ending"] as? [String: Any])?["actionId"] as? String, "choose")
        _ = try await home("show-past")
        XCTAssertTrue(app.staticTexts["Past"].waitForPresence(timeout: 10))
        XCTAssertFalse(app.buttons["card-action-choose"].isEnabled)
        XCTAssertFalse(app.textFields["card-reply"].exists)
        picture("past-card")
        tapOnPhone(app.buttons["put-aside-card"])
        _ = try await home("show-past")
        // INF-589 item 7: an answered card opened from its notice shows as a past card.
        XCTAssertTrue(app.staticTexts["Past"].waitForPresence(timeout: 10))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "card-pager").firstMatch.label, "Past card")
        tapOnPhone(app.buttons["put-aside-card"])
    }
}
