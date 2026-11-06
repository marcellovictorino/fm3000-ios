import XCTest

/// The join-away part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2125 direction C, the third join test: short and long trips away, Leave, Forget, Removed and a damaged record.
    /// Data: changes the home makes while the app is away, its removal of the phone and a truncated saved record.
    /// Completion: the phone returns in reach with what changed, leaves and forgets on request, and rejoins after each.
    func testAwayLeaveAndRemoved() async throws {
        try await launchJoined()
        // INF-1528, the captain: "the moment i minimize the ios app, it seems it immediately disconnects.
        // reopening the app even only after a short while needs to wait for reconnection."
        // A short trip away keeps the same connection: the app comes back in reach, with what changed meanwhile.
        let stateBeforeTrip = try await home("state", method: "GET")
        let beforeTrip = try XCTUnwrap(stateBeforeTrip["readings"] as? [String: Int])
        // INF-2131: testJoinAndRecover left for this trip long after the shown card had drawn; this test starts at the
        // join, so it waits for that drawing too rather than leaving while WebKit still starts the card's page.
        waitForShownBodyRevealed()
        XCUIDevice.shared.press(.home)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate { _, _ in self.app.state != .runningForeground }, object: nil, timeout: 10), .completed, "Home leaves the app")
        let whileShortlyAway = try await home("change")
        app.activate()
        XCTAssertEqual(app.buttons["computer-details"].value as? String, "In reach", "The app reopens in reach, not reconnecting")
        XCTAssertFalse(app.otherElements["reach-line"].exists, "No out-of-reach line shows on the return")
        let stateAfterTrip = try await home("state", method: "GET")
        let afterTrip = try XCTUnwrap(stateAfterTrip["readings"] as? [String: Int])
        XCTAssertEqual(afterTrip["connections"], beforeTrip["connections"], "The short trip made no new connection")
        let shortTripChange = try XCTUnwrap(whileShortlyAway["title"] as? String)
        showCard(shortTripChange)
        XCTAssertTrue(app.staticTexts[shortTripChange].waitForPresence(timeout: 10))
        _ = try await home("seen-wait", body: shortTripChange) // Read before the long trip, as the replayed card below.

        // A longer absence, past the time iOS gives the app in the background, closes the connection;
        // the return keeps the home's epoch and exercises replay, not a reload.
        try await background()
        let whileAway = try await home("change")
        app.activate()
        reach("In reach", timeout: 20)
        let replayed = try XCTUnwrap(whileAway["title"] as? String)
        showCard(replayed)
        XCTAssertTrue(app.staticTexts[replayed].waitForPresence(timeout: 10))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", replayed)).count, 1)
        // INF-2202 run 41590230179: the title shows before the card's page draws, and only a drawn page marks it read.
        // Leave can come first under load; that card then stays unread, and each later rejoin opens on it rather than
        // on the first card. The home's own mark of this card closes that race before the phone leaves.
        _ = try await home("seen-wait", body: replayed)

        // INF-2157, the captain: "often when i reopen my ios app, it takes a long time before the app would attempt
        // to reconnect." A reopen dials every saved address together, so one that never answers holds nothing up:
        // this connection's welcome names a stalled address ahead of the home's own, and the next reopen reaches the
        // home while that stalled attempt is still open, with one connection.
        _ = try await home("routing-stalled-first")
        try await background()
        app.activate()
        reach("In reach", timeout: 20)
        try await background()
        let beforeReopenState = try await home("state", method: "GET")
        let beforeReopen = try XCTUnwrap(beforeReopenState["readings"] as? [String: Int])
        _ = try await home("capture-reopen-start")
        app.activate()
        reach("In reach", timeout: 20)
        _ = try await home("capture-stop")
        let afterReopenState = try await home("state", method: "GET")
        let afterReopen = try XCTUnwrap(afterReopenState["readings"] as? [String: Int])
        func reopened(_ reading: String) throws -> Int { try XCTUnwrap(afterReopen[reading]) - XCTUnwrap(beforeReopen[reading]) }
        XCTAssertEqual(try reopened("stalledConnections"), 1,
            "The reopen dialed the stalled address too: before \(beforeReopen), after \(afterReopen)")
        XCTAssertEqual(afterReopen["stalledCutsAtHomeAttempt"], beforeReopen["stalledCuts"],
            "The reopen reached the home before giving up on the stalled address: before \(beforeReopen), after \(afterReopen)")
        XCTAssertEqual(try reopened("connections"), 1, "One welcomed connection per reopen")
        _ = try await home("routing-reset")

        computerDetails()
        tapOnPhone(app.buttons["leave"])
        // INF-589 item 4: Keep it stays in view beside Leave.
        XCTAssertTrue(app.alerts.buttons["Keep it"].firstMatch.waitForPresence(timeout: 10))
        waitUntilHittable(app.alerts.buttons["Keep it"].firstMatch)
        tapOnPhone(app.buttons["confirm-leave"].firstMatch)
        XCTAssertTrue(app.buttons["paste-link"].waitForPresence(timeout: 20), app.debugDescription)
        let afterLeave = try await home("state", method: "GET")
        XCTAssertEqual((afterLeave["devices"] as? [Any])?.count, 0)
        try await join()
        // INF-136 #4: a Mac that cannot answer must not keep the phone joined forever.
        _ = try await home("offline")
        outOfReach()
        computerDetails()
        tapOnPhone(app.buttons["forget-mac"])
        XCTAssertTrue(app.alerts.buttons["Keep it"].firstMatch.waitForPresence(timeout: 10))
        waitUntilHittable(app.alerts.buttons["Keep it"].firstMatch)
        picture("forget-confirmation")
        tapOnPhone(app.buttons["confirm-forget"].firstMatch)
        XCTAssertTrue(app.buttons["paste-link"].waitForPresence(timeout: 10))
        app.terminate(); try await launchPhoneApp(app)
        XCTAssertTrue(app.buttons["paste-link"].waitForPresence(timeout: 10))
        picture("forgotten")
        let afterForget = try await home("state", method: "GET")
        XCTAssertEqual((afterForget["devices"] as? [Any])?.count, 1, "Forgetting locally does not claim the Mac removed the phone")
        _ = try await home("online")
        try await join() // Fresh-link recovery reuses the identity still listed on this Mac.
        _ = try await home("remove")
        XCTAssertTrue(app.staticTexts["Removed from your computer"].waitForPresence(timeout: 20), app.debugDescription)
        try await appearances("removed", showing: app.staticTexts["Removed from your computer"])
        tapOnPhone(app.buttons["join-again"])
        XCTAssertTrue(app.buttons["paste-link"].exists)
        // INF-136 #3: two genuine 401s separated by an unreachable address still prove removal.
        try await submitLink("link-with-unreachable")
        reach("In reach", timeout: 20)
        try await background()
        _ = try await home("link") // Keep the real home listening after its final phone is removed.
        let removed = try await home("remove")
        app.activate()
        XCTAssertTrue(app.staticTexts["Removed from your computer"].waitForPresence(timeout: 20), app.debugDescription)
        picture("removed-after-away")
        let removal = try await home("state", method: "GET")
        let before = try XCTUnwrap(removed["before"] as? [String: Int])
        let after = try XCTUnwrap(removal["readings"] as? [String: Int])
        func since(_ reading: String) throws -> Int { try XCTUnwrap(after[reading]) - XCTUnwrap(before[reading]) }
        let readings = "before removal \(before), after \(after)"
        XCTAssertEqual(try since("refusals"), 2, "Two authenticated refusals, and no more, prove removal: \(readings)")
        // INF-1168, INF-2157: each round dials the home and the stalled address together, and the second refusal
        // ends its round at once. A starved simulator can also outlast the phone's own deadline at the home, which
        // sends no request and adds a round, so the rounds, not the clock, fix the count: one stall per home attempt.
        XCTAssertEqual(try since("stalledConnections"), try since("homeAttempts"),
            "Removal survives a stalled handshake with no HTTP response between authenticated refusals: \(readings)")
        tapOnPhone(app.buttons["join-again"])
        app.terminate(); try await launchPhoneApp(app)
        XCTAssertTrue(app.buttons["paste-link"].waitForPresence(timeout: 10))
        // INF-136 re-review #1: a damaged saved record must not block a fresh confirmed link.
        try await join()
        let beforeDamage = try await home("state", method: "GET")
        let retainedIDs = (beforeDamage["devices"] as? [[String: Any]])?.compactMap { $0["id"] as? String }
        XCTAssertEqual(retainedIDs?.count, 1)
        app.terminate()
        _ = try await home("damage-record")
        try await launchPhoneApp(app)
        XCTAssertTrue(app.buttons["paste-link"].waitForPresence(timeout: 10))
        picture("damaged-record")
        try await join()
        XCTAssertTrue(app.staticTexts["Your phone is reading your Mac"].waitForPresence(timeout: 10))
        let afterDamage = try await home("state", method: "GET")
        XCTAssertEqual((afterDamage["devices"] as? [[String: Any]])?.compactMap { $0["id"] as? String }, retainedIDs)
        picture("rejoined-after-damaged-record")
    }
}
