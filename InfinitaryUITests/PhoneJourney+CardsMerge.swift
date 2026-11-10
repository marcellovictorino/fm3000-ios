import XCTest

/// The cards-merge part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2125 direction C, the first of the cards tests split from testCards: the merge card, the asked line and readiness.
    /// INF-1574: every cards test keeps testCards' late retried body, so each check reads the same card timing it did.
    func testMergeCard() async throws {
        // INF-1574: a retried body's drawn height reaches its native frame three seconds late, as on a loaded computer,
        // so the stalled-answer check sees a body that is drawn but still clipped by its placeholder.
        app.launchEnvironment["INFINITARY_TEST_RETRIED_CARD_LAG"] = "3"
        try await launchJoined()
        try await verifyMergeCard()
        try await verifyAnswerDone()
        try await verifyQuestionDismiss()
        try await verifyDeferredStep()
        try await verifyAskedLine()
        try await verifyCardReadiness()
        try await verifySharedSeen()
        try await verifyEndedCard()
        try await verifyNextAfterClose()
    }

    /// INF-3155, the captain: "when all the cards are already read, dismissing the current card should reveal the next
    /// one, not going back to the first. this should behave consistently on both desktop and ios". With every card read,
    /// a closed card gives way to the card after it, and the last card to the one before it, as on the Mac.
    private func verifyNextAfterClose() async throws {
        let fixture = try await home("next-card-fixture")
        let titles = try XCTUnwrap(fixture["titles"] as? [String])
        XCTAssertEqual(titles.count, 4)
        for title in titles {
            showCard(title)
            _ = try await home("seen-wait", body: title)
        }
        showCard(titles[1])
        _ = try await home("close-titled", body: titles[1])
        XCTAssertTrue(cardHeading(titles[1]).waitForAbsence(timeout: 10), app.debugDescription)
        XCTAssertTrue(cardHeading(titles[2]).waitForPresence(timeout: 10), "A middle close brings up the card after it")
        XCTAssertEqual(app.buttons["card-pager"].label, "2 of 3")
        picture("next-after-middle-close")
        showCard(titles[3])
        _ = try await home("close-titled", body: titles[3])
        XCTAssertTrue(cardHeading(titles[3]).waitForAbsence(timeout: 10), app.debugDescription)
        XCTAssertTrue(cardHeading(titles[2]).waitForPresence(timeout: 10), "Closing the last card brings up the one before it")
        XCTAssertEqual(app.buttons["card-pager"].label, "2 of 2")
        picture("next-after-last-close")
    }

    /// INF-1610: a card about the captain's message names it under its title, as on the Mac.
    /// INF-1963: the captain asked to remove Show all and expand on the bubble's own click.
    /// Tapping the bubble opens the paragraphs and tapping again folds them; no separate link remains.
    private func verifyAskedLine() async throws {
        let asked = try await home("asked-card")
        let title = try XCTUnwrap(asked["title"] as? String)
        showCard(title)
        let line = app.otherElements["card-asked"]
        XCTAssertTrue(line.waitForPresence(timeout: 10), app.debugDescription)
        let label = app.staticTexts["card-asked-label"]
        XCTAssertTrue(label.label.hasPrefix("You asked · "), label.label)
        let toggle = app.buttons["card-asked-toggle"]
        XCTAssertTrue(toggle.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertFalse(app.buttons["Show all"].exists, "The bubble replaces the separate link")
        let folded = line.frame.height
        picture("card-asked-folded")
        tapOnPhone(toggle)
        let expanded = NSPredicate { _, _ in line.frame.height > folded * 2 }
        XCTAssertEqual(waitForPhonePredicate(expanded, object: nil, timeout: 10), .completed, app.debugDescription)
        XCTAssertGreaterThan(line.frame.height, folded * 2, "The bubble opens the whole message")
        XCTAssertFalse(app.buttons["Show less"].exists, "The open bubble has no separate fold link")
        picture("card-asked-open")
        tapOnPhone(toggle)
        let refolded = NSPredicate { _, _ in abs(line.frame.height - folded) < 1 }
        XCTAssertEqual(waitForPhonePredicate(refolded, object: nil, timeout: 10), .completed, app.debugDescription)
        tapOnPhone(app.buttons["put-aside-card"])
        XCTAssertTrue(cardHeading(title).waitForAbsence(timeout: 10), app.debugDescription)
    }

    /// INF-1558 / INF-1557: only cards on the desktop stage reach the phone's stage and pager.
    /// The real home sends the reproduced held/released fields; a ready sibling witnesses the new snapshot.
    private func verifyCardReadiness() async throws {
        let fixture = try await home("held-card-fixture")
        let held = try XCTUnwrap(fixture["held"] as? String)
        let ready = try XCTUnwrap(fixture["ready"] as? String)
        showCard(ready)
        let pager = app.descendants(matching: .any).matching(identifier: "card-pager").firstMatch
        picture("card-readiness-waiting-with-ready-sibling")
        XCTAssertEqual(pager.label, "1 of 1", "A held card is neither a page nor an unread offer")
        tapOnPhone(pager)
        XCTAssertFalse(app.buttons[held].exists, "The held card cannot be chosen from the pager")
        tapOnPhone(app.buttons[ready].firstMatch)
        tapOnPhone(app.buttons["put-aside-card"])
        XCTAssertTrue(app.otherElements["phone-character"].waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertFalse(pager.exists, "Only the waiting card remains, so the stage and pager are empty")
        picture("card-readiness-waiting")

        _ = try await home("release-held-card")
        XCTAssertTrue(cardHeading(held).waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(app.webViews.staticTexts["The harbour survey is ready for your choice."].waitForPresence(timeout: 10))
        XCTAssertEqual(pager.label, "1 of 1")
        picture("card-readiness-released")
        // A reply leaves its card on the stage while the author answers; awaiting alone is not enough to hide it.
        _ = try await home("replied-under-card")
        XCTAssertTrue(app.webViews.staticTexts["The surveyor is answering your harbour question."].waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(cardHeading(held).exists)
        XCTAssertEqual(pager.label, "1 of 1")
        picture("card-readiness-replied-under")
        _ = try await home("release-held-card")
        XCTAssertTrue(app.webViews.staticTexts["The harbour survey is ready for your choice."].waitForPresence(timeout: 10), app.debugDescription)
        tapOnPhone(app.buttons["card-action-keep"])
        XCTAssertTrue(cardHeading(held).waitForAbsence(timeout: 10), app.debugDescription)
        XCTAssertFalse(app.staticTexts["card-error"].exists)
        let state = try await home("readiness-state", method: "GET")
        let card = try XCTUnwrap(state["card"] as? [String: Any])
        let ending = try XCTUnwrap(card["ending"] as? [String: Any])
        XCTAssertEqual(ending["actionId"] as? String, "keep", "The home accepted the released card's choice")
    }

    /// INF-1524, the captain: "ios app's cards don't have minimize button. also the merge card doesn't have the radar chart."
    /// Data: a crewmate's merge card with its task, model, place, risk, the host's fact strip, an action to take after
    /// merging, a revision and a thread with a line another task's crewmate wrote (INF-2225). Completion: the phone draws
    /// the Mac's head and foot, names that line's true writer, puts the card aside on the computer, preserves typed
    /// words without a warning, counts a new card beside the pager and sends the words with a choice.
    private func verifyMergeCard() async throws {
        let fixture = try await home("merge-card")
        let title = try XCTUnwrap(fixture["title"] as? String)
        let words = try XCTUnwrap(fixture["words"] as? String)
        // INF-2928 piece 1: a tap on a task whose card is ready shows that card on Home, as a click on the Mac's row does,
        // instead of opening the task's record.
        tab("Tasks")
        let row = app.buttons["task-phone-merge"]
        XCTAssertTrue(row.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertLessThan(app.staticTexts["group-waiting"].frame.minY, row.frame.minY, "Its task waits on you")
        picture("tasks-ready-card")
        tapOnPhone(row)
        XCTAssertTrue(cardHeading(title).waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(app.buttons["tab-home"].isSelected, "The ready card shows on Home")
        XCTAssertFalse(app.staticTexts["task-record-title"].exists, "The row brings its card forward, not its record")
        showCard(title)
        XCTAssertTrue(cardHeading(title).waitForPresence(timeout: 10), app.debugDescription)
        // The head: the task's key, the model and where it runs, the risk and the revised line.
        XCTAssertEqual(app.buttons["card-task-key"].label, try XCTUnwrap(fixture["key"] as? String))
        XCTAssertTrue(app.staticTexts["card-model"].exists)
        XCTAssertTrue(app.staticTexts["card-place"].exists)
        XCTAssertTrue(app.staticTexts["card-revised"].exists)
        XCTAssertTrue(app.buttons["put-aside-card"].exists)
        // The foot: the host's fact strip stays with the choices.
        XCTAssertTrue(app.webViews["card-facts"].staticTexts.firstMatch.waitForPresence(timeout: 20), app.debugDescription)
        // INF-3149: what happens after the merge leads the body, the captain's actions before the crew's steps.
        let required = app.staticTexts[try XCTUnwrap(fixture["requiredLead"] as? String)]
        let crew = app.staticTexts[try XCTUnwrap(fixture["crewLead"] as? String)]
        XCTAssertTrue(required.exists, app.debugDescription)
        XCTAssertTrue(crew.exists, app.debugDescription)
        XCTAssertLessThan(required.frame.minY, crew.frame.minY, "The captain's actions come first")
        waitUntilEnabled(app.buttons["card-action-merge"])
        // Both appearances of the merge card supply the release note's hero pair.
        try await appearances("merge-card", showing: cardHeading(title))
        // The risk: seven dots that open each dimension's words and the crewmate's why.
        reveal(app.buttons["card-risk"]); tapOnPhone(app.buttons["card-risk"])
        let blast = app.descendants(matching: .any).matching(identifier: "risk-blast").firstMatch
        XCTAssertTrue(blast.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(blast.label.hasPrefix(try XCTUnwrap(fixture["blast"] as? String)), blast.label)
        picture("merge-risk")
        tapOnPhone(app.buttons["Done"])
        XCTAssertTrue(blast.waitForAbsence(timeout: 10))
        // The thread names who wrote each message in the Mac's words, on the card's back (INF-1919): its latest line
        // turns the card over, and Card turns it back to the face, which leaves the back undrawn.
        let cue = app.buttons["thread-cue"]
        reveal(cue); tapOnPhone(cue)
        XCTAssertTrue(app.staticTexts[try XCTUnwrap(fixture["threadCrew"] as? String)].waitForPresence(timeout: 10), app.debugDescription)
        // INF-2225: a line another task's crewmate wrote on this card names its true writer in the Mac's words.
        let contributor = app.staticTexts["thread-contributor"]
        XCTAssertTrue(contributor.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(contributor.label, try XCTUnwrap(fixture["threadContributor"] as? String))
        picture("merge-thread")
        tapOnPhone(app.buttons["thread-return"])
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "card-back").firstMatch.waitForAbsence(timeout: 10),
                      app.debugDescription)
        // Typed words are not lost to a close without a question.
        // On iPhone the merge card's head and foot outgrow its stage, so the whole card scrolls between them.
        let reply = app.textFields["card-reply"]
        reveal(reply); focusForPhoneTyping(reply, in: app); reply.typeText(words)
        // The focused field holds the scroll while the keyboard is up, so Done hides it, keeping the words, before the head is reached.
        if app.keyboards.firstMatch.exists {
            let done = app.buttons["dismiss-phone-keyboard"]
            XCTAssertTrue(done.waitForPresence(timeout: 10), app.debugDescription); tapOnPhone(done)
            XCTAssertTrue(app.keyboards.firstMatch.waitForAbsence(timeout: 10), app.debugDescription)
        }
        // INF-1879: the one minus retains typed words without a warning or an ending.
        XCTAssertFalse(app.buttons["close-card"].exists)
        let putAside = app.buttons["put-aside-card"]
        reveal(putAside); tapOnPhone(putAside)
        XCTAssertTrue(cardHeading(title).waitForAbsence(timeout: 10), app.debugDescription)
        let aside = try await home("card-state", method: "GET")
        XCTAssertEqual((aside["mergeCard"] as? [String: Any])?["minimized"] as? Bool, true, "Put aside minimizes the card on the computer")
        // The join note takes the stage and draws its body after its heading; a Tasks press while it still drew read
        // Home on a busy iPad, as INF-1735's did after a relaunch, so the press waits for the note's drawn body.
        let note = app.webViews.staticTexts["This card belongs to the disposable test home."].firstMatch
        XCTAssertTrue(note.waitForPresence(timeout: 10), app.debugDescription)
        _ = waitForRedraw(app.scrollViews["card-scroll"].firstMatch, from: nil)
        tab("Tasks")
        let restore = app.buttons.matching(identifier: "task-\(try XCTUnwrap(fixture["taskId"] as? String))").firstMatch
        XCTAssertTrue(restore.waitForPresence(timeout: 10), app.debugDescription)
        tapOnPhone(restore)
        XCTAssertTrue(cardHeading(title).waitForPresence(timeout: 10), app.debugDescription)
        // A card that arrives while this one is read is counted beside the pager, not in a pill over the stage.
        // The first mate's new card replaces its earlier note, so the count is read as a count, not as a number.
        let news = try await home("merge-news")
        let fresh = app.buttons["card-new"]
        XCTAssertTrue(fresh.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertNotNil(fresh.label.wholeMatch(of: /[1-9][0-9]* new/), fresh.label)
        XCTAssertFalse(app.buttons["phone-notice"].exists, "Home counts the new card instead of a pill")
        picture("merge-new-beside-pager")
        // The words in the field go with a choice.
        let later = app.buttons["card-action-later"]
        waitUntilEnabled(later)
        reveal(later); tapOnPhone(later)
        XCTAssertTrue(cardHeading(title).waitForAbsence(timeout: 10), app.debugDescription)
        let chosen = try await home("card-state", method: "GET")
        let past = try XCTUnwrap(chosen["merge"] as? [String: Any])
        let answers = try XCTUnwrap(past["answers"] as? [[String: Any]])
        XCTAssertEqual(answers.first { $0["name"] as? String == fixture["anythingElse"] as? String }?["written"] as? String, words)
        _ = try await home("show-merge-past")
        let sent = app.staticTexts["past-sent-words"]
        XCTAssertTrue(sent.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(sent.label, "\(try XCTUnwrap(fixture["sentLead"] as? String)) \(words)")
        XCTAssertEqual(app.buttons["card-action-later"].value as? String, "Chosen")
        picture("merge-past")
        reveal(app.buttons["put-aside-card"]); tapOnPhone(app.buttons["put-aside-card"])
        let newsTitle = try XCTUnwrap(news["title"] as? String)
        showCard(newsTitle)
        reveal(app.buttons["put-aside-card"]); tapOnPhone(app.buttons["put-aside-card"])
        XCTAssertTrue(cardHeading(newsTitle).waitForAbsence(timeout: 10))
    }

    /// INF-2022: owner sightings clear native news without selection changes, and phone readings persist at the owner.
    private func verifySharedSeen() async throws {
        let fixture = try await home("shared-seen-fixture")
        let leader = try XCTUnwrap(fixture["leader"] as? String)
        let target = try XCTUnwrap(fixture["target"] as? String)
        showCard(leader)
        XCTAssertTrue(app.buttons["card-new"].waitForPresence(timeout: 10), app.debugDescription)
        picture("shared-seen-new")
        _ = try await home("shared-seen-mark")
        XCTAssertTrue(app.buttons["card-new"].waitForAbsence(timeout: 10), app.debugDescription)
        XCTAssertTrue(cardHeading(leader).exists, "Reading elsewhere never moves this phone's selection")
        picture("shared-seen-read-elsewhere")
        _ = try await home("shared-seen-answer")
        XCTAssertTrue(app.buttons["card-new"].waitForPresence(timeout: 10), app.debugDescription)
        showCard(target)
        let read = try await home("shared-seen-wait")
        let card = try XCTUnwrap(read["card"] as? [String: Any])
        XCTAssertEqual(card["currentUpdateSeen"] as? Bool, true)
        XCTAssertEqual(app.buttons["card-pager"].label, "2 of 2")
        picture("shared-seen-phone-read")
        app.terminate(); app.launch()
        showCard(leader)
        XCTAssertTrue(app.buttons["card-new"].waitForAbsence(timeout: 10), app.debugDescription)
        picture("shared-seen-relaunched")
    }

    /// INF-3071: a card its author ended after the captain saw it stays, as on the Mac, crewmates and the first mate
    /// alike: its chip reads Ended, its thread ends with the computer's line, and its one Close takes it away.
    private func verifyEndedCard() async throws {
        let fixture = try await home("ended-card-fixture")
        let id = try XCTUnwrap(fixture["id"] as? String)
        let title = try XCTUnwrap(fixture["title"] as? String)
        showCard(title)
        XCTAssertTrue(app.staticTexts[try XCTUnwrap(fixture["chip"] as? String)].waitForPresence(timeout: 10), app.debugDescription)
        let close = app.buttons["note-done"]
        XCTAssertTrue(close.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(close.label, try XCTUnwrap(fixture["close"] as? String))
        XCTAssertFalse(app.buttons["card-action-build"].exists, "An ended card keeps none of its choices")
        let cue = app.buttons["thread-cue"]
        reveal(cue); tapOnPhone(cue)
        let back = app.descendants(matching: .any).matching(identifier: "card-back").firstMatch
        XCTAssertTrue(back.staticTexts[try XCTUnwrap(fixture["line"] as? String)].waitForPresence(timeout: 10), app.debugDescription)
        picture("ended-card-thread")
        tapOnPhone(app.buttons["thread-return"])
        XCTAssertTrue(back.waitForAbsence(timeout: 10), app.debugDescription)
        picture("ended-card")
        reveal(close); tapOnPhone(close)
        XCTAssertTrue(cardHeading(title).waitForAbsence(timeout: 10), app.debugDescription)
        let state = try await home("ended-card-state", body: "{\"id\":\"\(id)\"}")
        XCTAssertEqual(state["ended"] as? Bool, false, "Close took the ended card off the stack")
        XCTAssertEqual(state["open"] as? Bool, false)
    }

    /// INF-1879: putting an answer aside never completes it; Done remains available on its record.
    private func verifyAnswerDone() async throws {
        let fixture = try await home("answer-note-fixture")
        let title = try XCTUnwrap(fixture["title"] as? String)
        let taskID = try XCTUnwrap(fixture["taskId"] as? String)
        showCard(title)
        // INF-2794: the answer note's one Done sits in its pinned row; the minus only puts it aside.
        let noteDone = app.buttons["note-done"]
        XCTAssertTrue(noteDone.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(noteDone.label, "Done")
        XCTAssertTrue(app.webViews.staticTexts[try XCTUnwrap(fixture["answerText"] as? String)].waitForPresence(timeout: 10), app.debugDescription)
        reveal(noteDone)
        try await appearances("answer-note-done", showing: cardHeading(title))
        tapOnPhone(app.buttons["put-aside-card"])
        XCTAssertTrue(cardHeading(title).waitForAbsence(timeout: 10), app.debugDescription)
        // INF-2794: the minus only puts the answer aside; the card stays open and its task waits on the captain.
        let read = try await home("answer-note-state", body: "{\"taskId\":\"\(taskID)\"}")
        XCTAssertEqual(read["status"] as? String, "active")
        XCTAssertEqual(read["cardOpen"] as? Bool, true)
        XCTAssertEqual(read["ready"] as? Bool, true)
        tab("Tasks")
        let row = app.buttons.matching(identifier: "task-\(taskID)").firstMatch
        tapOnPhone(row)
        // The row brings the put-aside note back with its Done; its task key opens the record.
        XCTAssertTrue(cardHeading(title).waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(noteDone.waitForPresence(timeout: 10), app.debugDescription)
        let taskKey = app.buttons["card-task-key"]
        XCTAssertTrue(taskKey.waitForPresence(timeout: 10), app.debugDescription)
        tapOnPhone(taskKey)
        let done = app.buttons["record-answer-done"]
        XCTAssertTrue(done.waitForPresence(timeout: 10), app.debugDescription)
        try await appearances("answer-record-done", showing: app.staticTexts["task-record-title"])
        XCTAssertTrue(done.isHittable, app.debugDescription)
        let hide = app.buttons["close-record"]
        XCTAssertEqual(hide.label, try XCTUnwrap(fixture["hideLabel"] as? String))
        tapOnPhone(hide)
        XCTAssertTrue(hide.waitForAbsence(timeout: 10), app.debugDescription)
        let hidden = try await home("answer-note-state", body: "{\"taskId\":\"\(taskID)\"}")
        XCTAssertEqual(hidden["status"] as? String, "active", "Hiding the record never answers its task")
        XCTAssertEqual(hidden["ready"] as? Bool, true)
        tab("Tasks")
        try await appearances("saved-answer-in-tasks", showing: row)
        tapOnPhone(row)
        XCTAssertTrue(done.waitForPresence(timeout: 10), app.debugDescription)
        tapOnPhone(done)
        XCTAssertTrue(done.waitForAbsence(timeout: 10), app.debugDescription)
        let completed = try await home("answer-note-state", body: "{\"taskId\":\"\(taskID)\",\"expectedStatus\":\"done\"}")
        XCTAssertEqual(completed["status"] as? String, "done")
        XCTAssertEqual(completed["reason"] as? String, "answered")
        XCTAssertEqual(completed["ready"] as? Bool, false)
        // The task record is a sheet; dismiss it before using the tab strip behind it.
        tapOnPhone(app.buttons["close-record"])
        XCTAssertTrue(app.buttons["close-record"].waitForAbsence(timeout: 10), app.debugDescription)
        tab("Home")
        // The note's own Done, the button in its pinned row (INF-2794), closes the task as answered, even before
        // the computer answers.
        let next = try await home("answer-note-fixture")
        let nextTaskID = try XCTUnwrap(next["taskId"] as? String)
        let nextTitle = try XCTUnwrap(next["title"] as? String)
        showCard(nextTitle)
        XCTAssertTrue(noteDone.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(noteDone.label, "Done")
        XCTAssertFalse(app.buttons["answer-done"].exists, "The note draws one Done, in its pinned row")
        reveal(noteDone)
        _ = try await home("hold-card-action", body: #"{"channel":"inf:cards:note-done"}"#)
        tapOnPhone(noteDone)
        _ = try await home("card-action-held")
        XCTAssertTrue(cardHeading(nextTitle).waitForAbsence(timeout: 10), "Done puts the answer away at the tap")
        let pending = try await home("answer-note-state", body: "{\"taskId\":\"\(nextTaskID)\"}")
        XCTAssertEqual(pending["status"] as? String, "active", "The prediction is not a saved answer receipt")
        XCTAssertEqual(pending["ready"] as? Bool, true)
        _ = try await home("release-card-action")
        let answered = try await home("answer-note-state", body: "{\"taskId\":\"\(nextTaskID)\",\"expectedStatus\":\"done\"}")
        XCTAssertEqual(answered["status"] as? String, "done")
        XCTAssertEqual(answered["reason"] as? String, "answered")
        XCTAssertEqual(answered["ready"] as? Bool, false)
    }

    /// INF-1879: the record's minus hides a real filed question; only its explicit ending ends it.
    /// INF-3108: that ending is Decline, the captain's answer no to every choice, so the question closes as answered.
    /// The device gate runs this with cards-merge, on fresh disposable homes on both devices in all three rounds.
    private func verifyQuestionDismiss() async throws {
        let fixture = try await home("question-record-fixture")
        let taskID = try XCTUnwrap(fixture["taskId"] as? String)
        let cardID = try XCTUnwrap(fixture["cardId"] as? String)
        let stateBody = "{\"taskId\":\"\(taskID)\",\"cardId\":\"\(cardID)\"}"
        tab("Tasks")
        let row = app.buttons.matching(identifier: "task-\(taskID)").firstMatch
        XCTAssertTrue(row.waitForPresence(timeout: 10), app.debugDescription)
        // INF-2928 piece 1, the captain's pick: a first mate question's card shows no task key, so its row opens the
        // record rather than showing the card on Home.
        tapOnPhone(row)
        let dismiss = app.buttons["dismiss-question"]
        XCTAssertTrue(dismiss.waitForPresence(timeout: 10), app.debugDescription)
        let hide = app.buttons["close-record"]
        XCTAssertEqual(hide.label, try XCTUnwrap(fixture["hideLabel"] as? String))
        try await appearances("question-record-dismiss", showing: app.staticTexts["task-record-title"])
        tapOnPhone(hide)
        XCTAssertTrue(hide.waitForAbsence(timeout: 10), app.debugDescription)
        let hidden = try await home("question-record-state", body: stateBody)
        XCTAssertEqual(hidden["status"] as? String, "open", "Hiding the record never ends its question")
        XCTAssertNil(hidden["reason"] as? String)
        XCTAssertEqual(hidden["cardOnStack"] as? Bool, true)
        XCTAssertEqual((hidden["runs"] as? [Any])?.count, 0)
        tapOnPhone(row)
        XCTAssertTrue(dismiss.waitForPresence(timeout: 10), app.debugDescription)
        _ = try await home("hold-card-action", body: #"{"channel":"inf:task:run"}"#)
        tapOnPhone(dismiss)
        _ = try await home("card-action-held")
        XCTAssertTrue(dismiss.waitForAbsence(timeout: 10), "Decline shows at the tap, before the computer answers")
        let pending = try await home("question-record-state", body: stateBody)
        XCTAssertEqual(pending["status"] as? String, "open", "A prediction is not the computer's recorded ending")
        picture("question-dismiss-at-tap")
        _ = try await home("release-card-action")
        let ended = try await home("question-record-state",
            body: "{\"taskId\":\"\(taskID)\",\"cardId\":\"\(cardID)\",\"expectedStatus\":\"done\"}")
        XCTAssertEqual(ended["status"] as? String, "done")
        XCTAssertEqual(ended["reason"] as? String, "answered")
        XCTAssertEqual(ended["cardOnStack"] as? Bool, false)
        let runs = try XCTUnwrap(ended["runs"] as? [[String: Any]])
        XCTAssertEqual(runs.count, 1)
        XCTAssertEqual(runs.first?["move"] as? String, "dismiss-question")
        let actor = try XCTUnwrap(runs.first?["actor"] as? [String: Any])
        XCTAssertEqual(actor["kind"] as? String, "captain")
        tapOnPhone(hide)
        XCTAssertTrue(hide.waitForAbsence(timeout: 10), app.debugDescription)
        tab("Home")
    }

    /// INF-2928 piece 1, spec item 7's third check: a tap on the row of a required step put off with Not now shows its
    /// card again on Home through the Mac's show-card move, as a click on the Mac's row does, rather than the record.
    private func verifyDeferredStep() async throws {
        let fixture = try await home("deferred-step-fixture")
        let taskID = try XCTUnwrap(fixture["taskId"] as? String)
        let title = try XCTUnwrap(fixture["title"] as? String)
        tab("Tasks")
        let row = app.buttons.matching(identifier: "task-\(taskID)").firstMatch
        XCTAssertTrue(row.waitForPresence(timeout: 10), app.debugDescription)
        tapOnPhone(row)
        XCTAssertTrue(cardHeading(title).waitForPresence(timeout: 20), app.debugDescription)
        XCTAssertTrue(app.buttons["tab-home"].isSelected, "The put-off step's card shows on Home")
        XCTAssertFalse(app.staticTexts["task-record-title"].exists, "The row shows its card again, not its record")
        picture("deferred-step-card")
        let state = try await home("deferred-step-state", body: "{\"taskId\":\"\(taskID)\"}")
        let runs = try XCTUnwrap(state["runs"] as? [[String: Any]])
        XCTAssertEqual(runs.map { $0["move"] as? String }, ["show-card"], "One show-card move, the Mac's")
        XCTAssertEqual((runs.first?["actor"] as? [String: Any])?["kind"] as? String, "captain")
        tapOnPhone(app.buttons["put-aside-card"])
        XCTAssertTrue(cardHeading(title).waitForAbsence(timeout: 10), app.debugDescription)
    }
}
