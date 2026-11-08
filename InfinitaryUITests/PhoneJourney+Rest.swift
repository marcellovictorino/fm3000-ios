import XCTest

/// The rest part (scripts/phone-test-plan.ts), which also runs every test no other part names: its tests and the steps
/// only they take.
extension PhoneJourney {
    /// Part 4, the character and past choices: a real held turn, saved-sign-in and saved-answer choices, past-card context.
    func testCharacterAndPastChoices() async throws {
        try await launchJoined()
        try await verifyConversationCharacter()
        try await verifyNativeCrewScene()
        try await verifyReviewedCardChoices()
        try await verifyPastMessageContext()
        try await verifyPhotoReadinessRecovery()
    }

    /// INF-1832: the accepted photo-wait plan ends on positive readiness, never on missing preview alone.
    /// Fixture: this device's actual library photo, read through the same sampler as recovery.
    /// Completion: ordered observations authorize selection, one preview close, or the settled grid only.
    /// Resources: the rest part's disposable simulator/home and imported photo; no real account or signing.
    private func verifyPhotoReadinessRecovery() async throws {
        tab("Home")
        let photos = app.buttons["add-photos"]
        XCTAssertTrue(waitForPhonePress(photos)); tapOnPhone(photos)
        let photo = app.images.matching(NSPredicate(format: "label BEGINSWITH 'Photo, ' OR label BEGINSWITH 'Screenshot, '")).firstMatch
        XCTAssertTrue(photo.waitForPresence(timeout: 10))
        waitForSteadyTarget(photo)
        let reading = try XCTUnwrap(readPhoneTarget(photo))
        XCTAssertNotNil(reading.drawn)
        print("Photo readiness fixture: frame=\(reading.frame), bytes=\(reading.drawn?.count ?? 0)")
        var observation = PhonePhotoObservation()
        XCTAssertNil(observation.read(selected: false, preview: false, target: reading))
        XCTAssertEqual(observation.read(selected: false, preview: false, target: reading), .settled)
        XCTAssertEqual(observation.read(selected: true, preview: true, target: reading), .selected)
        XCTAssertEqual(observation.read(selected: false, preview: true, target: reading), .preview)
        XCTAssertNil(observation.read(selected: false, preview: false, target: reading), "A preview resets steadiness")
        for absent in [nil, PhoneTargetReading(frame: reading.frame, drawn: nil)] {
            XCTAssertNil(observation.read(selected: false, preview: false, target: absent))
            XCTAssertNil(observation.read(selected: false, preview: false, target: absent))
            XCTAssertNil(observation.read(selected: false, preview: false, target: reading), "Missing pixels reset steadiness")
        }
        // Replay a changed frame using this real photo's other observed frame, not invented screen pixels.
        let other = try XCTUnwrap(readPhoneTarget(app.buttons.matching(NSPredicate(format: "label == 'Done' OR label == 'Add'")).firstMatch))
        XCTAssertNotEqual(other.frame, reading.frame)
        XCTAssertNil(observation.read(selected: false, preview: false, target: other))
        XCTAssertNil(observation.read(selected: false, preview: false, target: reading))
        XCTAssertEqual(observation.read(selected: false, preview: false, target: reading), .settled)
        // Hold the captured frame fixed while replaying the two real native pixel captures: geometry alone is insufficient.
        XCTAssertNotEqual(other.drawn, reading.drawn)
        let repainted = PhoneTargetReading(frame: reading.frame, drawn: other.drawn)
        XCTAssertNil(observation.read(selected: false, preview: false, target: repainted))
        XCTAssertEqual(observation.read(selected: false, preview: false, target: repainted), .settled)

        var closed = false
        XCTAssertEqual(recoverPhonePhoto(selected: { true }, preview: { true }, target: { nil },
            closedPreview: &closed, close: { XCTFail("A selected photo needs no closing tap") }), .selected)
        XCTAssertFalse(closed)
        var reads = 0
        var closes = 0
        XCTAssertEqual(recoverPhonePhoto(selected: { false }, preview: {
            reads += 1
            // The delayed preview arrives only at the final pre-tap recheck, after two matching grid readings.
            return reads >= 3 && closes == 0
        }, target: { reading }, closedPreview: &closed, close: { closes += 1 }), .settled)
        XCTAssertEqual(closes, 1, "A late preview takes the closing path before another photo tap")
        XCTAssertTrue(closed)
        closed = false; closes = 0
        XCTAssertEqual(recoverPhonePhoto(selected: { false }, preview: { closes == 0 }, target: { reading },
            closedPreview: &closed, close: { closes += 1 }), .settled)
        XCTAssertEqual(closes, 1, "An already-open preview closes once")
        closed = false
        XCTAssertEqual(recoverPhonePhoto(selected: { false }, preview: { false }, target: { reading },
            closedPreview: &closed, close: { XCTFail("A settled grid needs no closing tap") }), .settled)
        XCTAssertFalse(closed)
        // Reproduce the picker’s real press-and-hold too; the iPad can select instead of opening Preview.
        let since = Date().timeIntervalSince1970 * 1000
        photo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 1.8)
        let proof = try askPhoneHome("picker-preview", since: since)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate { _, _ in proof.value != nil }, object: nil, timeout: 40), .completed)
        XCTAssertEqual(try proof.answer()["previewed"] as? Bool, true)
        let add = app.buttons.matching(NSPredicate(format: "label == 'Done' OR label == 'Add'")).firstMatch
        let preview = app.otherElements["Preview"]
        closed = false
        let live = recoverPhonePhoto(selected: { add.exists && add.isEnabled }, preview: { preview.exists },
            target: { readPhoneTarget(photo) }, closedPreview: &closed,
            close: { closePhonePickerPreview(preview, in: self.app) })
        XCTAssertNotNil(live)
        print("Photo readiness live press-and-hold: outcome=\(live?.rawValue ?? "unresolved"), closedPreview=\(closed)")
        closed = false
        // Capture typed failure reports, rather than XCTest's fail-fast issue: every negative branch must run.
        var failures: [PhonePhotoRecoveryFailure] = []
        XCTAssertNil(recoverPhonePhoto(selected: { false }, preview: { false }, target: { nil },
            closedPreview: &closed, timeout: 0.01, failure: { failures.append($0) },
            close: { XCTFail("No preview exists") }))
        XCTAssertEqual(failures, [.unresolved])
        closed = true
        XCTAssertNil(recoverPhonePhoto(selected: { false }, preview: { true }, target: { nil },
            closedPreview: &closed, failure: { failures.append($0) },
            close: { XCTFail("Only one closing tap is allowed") }))
        XCTAssertEqual(failures, [.unresolved, .previewAfterClose])
        print("Photo readiness negative branches: \(failures.map { $0.rawValue })")
    }

    /// INF-82: a real Mac conversation, not focus, task traffic or a fabricated listening state, drives the character.
    /// The existing mock holds a genuine first-mate turn; its completion signal returns the empty stage to idle.
    private func verifyConversationCharacter() async throws {
        let fixture = try await home("character-fixture")
        let character = app.otherElements["phone-character"]
        XCTAssertTrue(character.waitForPresence(timeout: 10))
        XCTAssertEqual(character.value as? String, "idle")
        // Start before the real typing and Send journey, not immediately before releasing the held turn.
        // The simulator's first recorded frame otherwise arrives after the working state has finished.
        _ = try await home("capture-conversation-start")
        let input = app.textFields["message-box"]
        focusForPhoneTyping(input, in: app); input.typeText(try XCTUnwrap(fixture["text"] as? String))
        XCTAssertEqual(character.value as? String, "idle", "Typing is not evidence of dictation or listening")
        tapOnPhone(app.buttons["send-message"])
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value == 'working'"), object: character, timeout: 20), .completed)
        picture("character-working")
        _ = try await home("capture-stop")
        try await verifySceneContact()
        let finished = try await home("character-finished")
        XCTAssertEqual(finished["busy"] as? Bool, false)
        XCTAssertEqual(finished["held"] as? Int, 0)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value == 'idle'"), object: character, timeout: 20), .completed)
        picture("character-finished")
        _ = try await home("capture-stop")
        try await background()
        _ = try await home("scene-current-home")
        app.activate()
        reach("In reach", timeout: 20)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value == 'idle'"), object: character, timeout: 20), .completed)
    }

    /// INF-1066: an already-running real turn survives a relaunch via its initial snapshot;
    /// an older home sends no unsupported reads and reports unknown until a real activity event.
    private func verifySceneContact() async throws {
        app.terminate()
        try await launchPhoneApp(app)
        reach("In reach", timeout: 20)
        let character = app.otherElements["phone-character"]
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value == 'working'"), object: character, timeout: 20), .completed)
        picture("native-scene-initial-busy")

        try await background()
        _ = try await home("scene-older-home")
        app.activate()
        reach("In reach", timeout: 20)
        XCTAssertEqual(character.value as? String, "Activity unknown")
        let legacy = try await home("scene-observations")
        XCTAssertEqual(legacy["reads"] as? Int, 0, "An older home receives neither new read")
        picture("native-scene-older-home-unknown")
        // The caller finishes this same real held turn and verifies its live idle event before restoring the current home.
    }

    /// INF-1066: actual task records and a paired absent helper supply the desktop-sized scene.
    /// The journey pans by touch, reads richer previews and opens the existing record; both simulator sizes run it.
    /// Its home, model stand-in and recording are disposable. No real sign-in, signing or device is used.
    private func verifyNativeCrewScene() async throws {
        let fixture = try await home("scene-fixture")
        let scene = app.scrollViews["crew-scene"]
        XCTAssertTrue(scene.waitForPresence(timeout: 10))
        let firstID = try XCTUnwrap((fixture["ordinary"] as? [String])?.first)
        let remoteID = try XCTUnwrap(fixture["remote"] as? String)
        let local = app.buttons["crew-task-" + firstID], remote = app.buttons["crew-task-" + remoteID]
        XCTAssertTrue(local.waitForPresence(timeout: 10))
        // INF-1477: the fixture's crew reach the phone one push at a time. On the iPad the home's ring fits the screen,
        // so only the other computer's formation gives Right somewhere to pan, and a Right pressed before it arrives
        // pans nowhere. The scene is whole once it draws that formation and the reviewer, the fixture's last crewmate.
        let reviewer = app.buttons["crew-task-" + (try XCTUnwrap(fixture["review"] as? String))]
        XCTAssertTrue(remote.waitForPresence(timeout: 10), "The other computer's crewmate must reach the scene")
        XCTAssertTrue(reviewer.waitForPresence(timeout: 10), "The fixture's last crewmate must reach the scene")
        let character = app.otherElements["phone-character"]
        let centered = NSPredicate { _, _ in
            abs(character.frame.midX - scene.frame.midX) < 1 && abs(character.frame.midY - scene.frame.midY) < 1
        }
        XCTAssertEqual(waitForPhonePredicate(centered, object: nil, timeout: 10), .completed)
        picture("native-scene-crew-home")
        try await verifyCrewKeyboard(scene, character: character)
        let summaries = try XCTUnwrap(fixture["summaries"] as? [String: [String: Any]])
        let pace = PhoneOrbitPace(planes: try XCTUnwrap(fixture["orbitPlanes"] as? [[String: Double]]).map {
            .init(speedDegPerSec: try XCTUnwrap($0["speedDegPerSec"]), inclination: try XCTUnwrap($0["inclination"]), node: try XCTUnwrap($0["node"]))
        })
        let orbiting = Set(try XCTUnwrap(fixture["orbiting"] as? [String]).map { "crew-task-" + $0 })
        _ = try await home("capture-scene-start")
        revealCrew(local, in: scene)
        tapOrbitingCrew(local, in: scene, orbiting: orbiting, pace: pace)
        XCTAssertTrue(app.otherElements["crew-preview"].waitForPresence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Check harbour marker 1"].exists)
        try await verifyCrewSummary(try XCTUnwrap(summaries[firstID]), picture: "native-scene-task-preview")
        closeCrewSummary()
        // INF-1926: a working crewmate waiting on its checks, and one waiting on the captain, each in the desktop's words.
        for (id, name) in [(try XCTUnwrap(fixture["checks"] as? String), "native-scene-working-preview"),
                           (try XCTUnwrap(fixture["waiting"] as? String), "native-scene-waiting-preview")] {
            let crewmate = app.buttons["crew-task-" + id]
            revealCrew(crewmate, in: scene)
            tapOrbitingCrew(crewmate, in: scene, orbiting: orbiting, pace: pace)
            // The working summary is the change's hero picture, so it is kept in both appearances.
            try await verifyCrewSummary(try XCTUnwrap(summaries[id]), picture: name, themes: name == "native-scene-working-preview")
            if name == "native-scene-working-preview" {
                try verifyRecordDetails(try XCTUnwrap(summaries[id]), picture: "native-scene-working-record")
            } else {
                closeCrewSummary()
            }
        }
        // A different computer remains a formation beside home, never a pager or a smaller version of every glyph.
        revealCrew(remote, in: scene)
        XCTAssertEqual(remote.value as? String, "Activity unknown")
        picture("native-scene-remote-formation")
        _ = try await home("capture-stop")
        tapOnPhone(remote)
        XCTAssertTrue(app.staticTexts["Read the offshore chart"].waitForPresence(timeout: 10))
        // The Project row names the other computer the task runs on, as the desktop's does.
        try await verifyCrewSummary(try XCTUnwrap(summaries[remoteID]), picture: "native-scene-remote-preview")
        tapOnPhone(app.buttons["open-crew-task"])
        XCTAssertTrue(app.staticTexts["task-record-title"].waitForPresence(timeout: 10))
        XCTAssertEqual(app.staticTexts["task-record-title"].label, "Read the offshore chart")
        picture("native-scene-existing-task-record")
        tapOnPhone(app.buttons["close-record"])
        verifyTapAfterDrag(from: remote, to: app.buttons["crew-task-" + (try XCTUnwrap(fixture["remotePart"] as? String))], in: scene)
        let computerID = try XCTUnwrap(fixture["computer"] as? String), programID = try XCTUnwrap(fixture["program"] as? String)
        let mark = app.buttons["crew-task-" + computerID + ":" + programID]
        revealCrew(mark, in: scene)
        // INF-1066: the whole 44-point square answers touch, so a tap near its corner, outside the drawn circle, opens it.
        XCTAssertGreaterThanOrEqual(mark.frame.width + 0.001, 44); XCTAssertGreaterThanOrEqual(mark.frame.height + 0.001, 44)
        tapOnPhone(mark.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)))
        XCTAssertTrue(app.staticTexts["crew-program-counts"].waitForPresence(timeout: 10))
        XCTAssertEqual(app.staticTexts["crew-program-counts"].label, try XCTUnwrap(fixture["programWords"] as? String))
        try await verifyCrewSummary(try XCTUnwrap(summaries[programID]), picture: "native-scene-program-preview")
        // A running part's key shows that part in the same sheet: here the part another part blocks.
        let secondID = try XCTUnwrap(fixture["second"] as? String), blocked = try XCTUnwrap(summaries[secondID])
        let part = app.otherElements["crew-preview"].buttons[try XCTUnwrap(blocked["key"] as? String)]
        XCTAssertTrue(part.waitForPresence(timeout: 10), "The program's Running row lists the blocked part")
        tapOnPhone(part)
        try await verifyCrewSummary(blocked, picture: "native-scene-blocked-preview")
        try verifyRecordDetails(blocked, picture: "native-scene-blocked-record")
        _ = try await home("scene-stage-finished")
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value == 'Program, 0 running parts'"), object: mark, timeout: 10), .completed, app.debugDescription)
        picture("native-scene-between-program-stages")
        _ = try await home("scene-cleanup")
        XCTAssertTrue(remote.waitForAbsence(timeout: 10), "A departed task must leave the scene and its touch targets")
    }

    /// INF-1066 and the project's keyboard rule: browse the same live scene without touching it.
    /// The two simulator sizes own their home and keyboard; success is visible displacement and a real preview.
    private func verifyCrewKeyboard(_ scene: XCUIElement, character: XCUIElement) async throws {
        _ = try await home("capture-scene-keyboard-start")
        // INF-1066: the captain chose visible-result proof for these unmodified keys.
        // Command-Shift-C still needs BackBoard's exact-chord/current-process witness.
        func pressBrowsingKey(_ key: String) throws {
            guard waitForPhonePredicate(NSPredicate(format: "value == 'Browsing crew'"), object: scene, timeout: 10) == .completed else {
                XCTFail("The browsing key was not sent: the scene is not browsing")
                throw NSError(domain: "PhoneKeyboard", code: 4, userInfo: [NSLocalizedDescriptionKey: "Crew browsing is not active"])
            }
            // One actual input, no registration wait, native-focus assumption or retry.
            app.typeKey(key == XCUIKeyboardKey.tab.rawValue ? "\t" : key, modifierFlags: [])
        }
        try await pressPhoneKey("c", modifiers: [.command, .shift], in: app)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value == 'Browsing crew'"), object: scene, timeout: 10), .completed,
                       "Browse crew enters the app's browsing mode")
        let originalX = character.frame.midX
        try pressBrowsingKey(XCUIKeyboardKey.rightArrow.rawValue)
        let panResult = waitForPhonePredicate(NSPredicate { _, _ in character.frame.midX < originalX - 1 }, object: nil, timeout: 10)
        XCTAssertEqual(panResult, .completed, "Right pans the actual scene: it reads \(scene.value ?? "no value"), "
                       + "and the first mate moved from x \(originalX) to x \(character.frame.midX)")
        picture("native-scene-keyboard-pan")
        try pressBrowsingKey(XCUIKeyboardKey.leftArrow.rawValue)
        let returnResult = waitForPhonePredicate(NSPredicate { _, _ in abs(character.frame.midX - originalX) < 1 }, object: nil, timeout: 10)
        XCTAssertEqual(returnResult, .completed, "Left returns to the same world point")
        try pressBrowsingKey(XCUIKeyboardKey.tab.rawValue)
        let selectedCrew = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'crew-task-' AND value BEGINSWITH 'Selected, '")).firstMatch
        XCTAssertTrue(selectedCrew.waitForPresence(timeout: 10), "Tab reaches a real crewmate")
        XCTAssertTrue(selectedCrew.isHittable, "The selected crewmate is visible in the panned scene")
        let selectedWords = selectedCrew.label.components(separatedBy: ", ")
        let selectedKey = try XCTUnwrap(selectedWords.first)
        let selectedTitle = selectedWords.dropFirst().joined(separator: ", ")
        picture("native-scene-keyboard-crew-selection")
        try pressBrowsingKey(" ")
        let preview = app.otherElements["crew-preview"]
        XCTAssertTrue(preview.waitForPresence(timeout: 10), "Space opens that crewmate's preview")
        XCTAssertTrue(preview.staticTexts[selectedKey].exists)
        XCTAssertTrue(preview.staticTexts[selectedTitle].exists, "The preview belongs to the crewmate selected by Tab")
        picture("native-scene-keyboard-preview")
        _ = try await home("capture-stop")
        closeCrewSummary()
    }

    /// INF-1926: the open summary says what the desktop's summary says for the same task, the fixture's `summaries`
    /// (tests/helpers/phoneScene.ts). The record's read fills Now; until it answers the row is held open, blank.
    private func verifyCrewSummary(_ want: [String: Any], picture name: String, themes: Bool = false) async throws {
        let preview = app.otherElements["crew-preview"]
        XCTAssertTrue(preview.waitForPresence(timeout: 10), "\(name): the summary sheet opens")
        let task = preview.staticTexts["crew-summary-task"]
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "label == %@", try XCTUnwrap(want["task"] as? String)), object: task, timeout: 10),
                       .completed, "\(name): the sheet shows the chosen task, not \(task.label)")
        if let now = want["now"] as? String {
            let shown = preview.staticTexts["crew-summary-now"]
            XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "label == %@", now), object: shown, timeout: 10), .completed,
                           "\(name): Now reads \(shown.label), the desktop reads \(now)")
        }
        for (field, id) in [("status", "crew-summary-status"), ("project", "crew-summary-project"), ("plan", "crew-summary-plan"),
                            ("model", "crew-summary-model"), ("change", "crew-summary-change"), ("review", "crew-summary-review")] {
            let shown = preview.staticTexts[id]
            if let words = want[field] as? String, !words.isEmpty {
                XCTAssertEqual(shown.label, words, "\(name): \(field) as the desktop says it")
            } else {
                XCTAssertFalse(shown.exists, "\(name): the desktop shows no \(field)")
            }
        }
        // INF-2528, the captain's direction B: the summary stays short; reasoning, its footnote and the check counts
        // are the task record's.
        for id in ["crew-summary-reasoning", "crew-summary-reason"] {
            XCTAssertFalse(preview.staticTexts[id].exists, "\(name): the summary shows no \(id)")
        }
        // The checks' one state is followed by how long they have run, which moves with the clock.
        if let checks = want["checks"] as? String {
            let shown = preview.staticTexts["crew-summary-checks"].label
            XCTAssertTrue(shown.hasPrefix(checks), "\(name): checks read \(shown), the desktop reads \(checks)")
        } else {
            XCTAssertFalse(preview.staticTexts["crew-summary-checks"].exists, "\(name): the desktop shows no checks")
        }
        for key in want["blocked"] as? [String] ?? [] {
            XCTAssertTrue(preview.otherElements["crew-summary-blocked"].descendants(matching: .any)[key].exists,
                          "\(name): Blocked by names \(key)")
        }
        // INF-2528: Blocked by names keys only; when each wait was recorded is the task record's.
        let blockedWords = preview.otherElements["crew-summary-blocked"].staticTexts.allElementsBoundByIndex.map(\.label)
        XCTAssertFalse(blockedWords.contains { $0.contains("recorded") }, "\(name): Blocked by reads \(blockedWords)")
        if themes { try await appearances(name, showing: task) } else { picture(name) }
    }

    /// INF-2528, the captain's "more details should be shown in the task card, not in the preview": Open task shows
    /// what the summary leaves out - the check counts, the reasoning level and each task it waits on - in the desktop's
    /// words for the same task (`record` and `blocked` in tests/helpers/phoneScene.ts), then the record closes.
    private func verifyRecordDetails(_ want: [String: Any], picture name: String) throws {
        let record = try XCTUnwrap(want["record"] as? [String: Any])
        tapOnPhone(app.buttons["open-crew-task"])
        XCTAssertTrue(app.staticTexts["task-record-title"].waitForPresence(timeout: 10), "\(name): Open task shows the record")
        let checks = app.staticTexts["task-record-checks"], reasoning = app.staticTexts["task-record-reasoning"]
        if let words = record["checks"] as? String {
            XCTAssertTrue(checks.waitForPresence(timeout: 10), "\(name): the record shows the checks")
            XCTAssertTrue(checks.label.contains(words), "\(name): the record's checks read \(checks.label), the desktop reads \(words)")
        } else {
            XCTAssertFalse(checks.exists, "\(name): the desktop's record shows no checks")
        }
        if let words = record["reasoning"] as? String {
            XCTAssertTrue(reasoning.waitForPresence(timeout: 10), "\(name): the record shows the reasoning")
            XCTAssertTrue(reasoning.label.hasPrefix(words), "\(name): the record's reasoning reads \(reasoning.label), the desktop reads \(words)")
        } else {
            XCTAssertFalse(reasoning.exists, "\(name): the desktop's record shows no reasoning")
        }
        // INF-2935, the captain's direction A: the record lists each task it waits on by its key under Waits on, as the
        // Mac's record does.
        for key in want["blocked"] as? [String] ?? [] {
            let waitsOn = app.descendants(matching: .any).matching(identifier: "task-record-waits-on").firstMatch
            XCTAssertTrue(waitsOn.waitForPresence(timeout: 10), "\(name): the record shows what it waits on")
            XCTAssertTrue(waitsOn.descendants(matching: .any).matching(NSPredicate(format: "label == %@", key)).firstMatch.exists,
                          "\(name): Waits on lists \(key)")
        }
        picture(name)
        tapOnPhone(app.buttons["close-record"])
        XCTAssertTrue(app.staticTexts["task-record-title"].waitForAbsence(timeout: 10), "\(name): the record closes")
    }

    /// INF-1926, the captain's "standard sheet interaction": a tap above the sheet closes it, with no close mark.
    private func closeCrewSummary() {
        let preview = app.otherElements["crew-preview"], window = app.windows.firstMatch
        waitForSteadyTarget(preview)
        let screen = window.frame, top = (screen.minY + max(screen.minY, preview.frame.minY - 48)) / 2
        tapOnPhone(window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: (top - screen.minY) / screen.height)))
        XCTAssertTrue(preview.waitForAbsence(timeout: 10), "The crew summary stayed open: \(app.debugDescription)")
    }

    // INF-1399: isHittable also accepts a sliver of a clipped 44-point target, and a touch XCTest then
    // chooses at the scene's clipping edge opens nothing. The target is ready only once its whole frame
    // lies inside the scene's viewport.
    private func crewReadyToTap(_ hittable: Bool, frame: CGRect, in viewport: CGRect) -> Bool {
        hittable && !frame.isEmpty && viewport.contains(frame)
    }

    /// INF-1399: the touch run 40341452314's iPhone rest part made, at the scene's right edge, with the scene
    /// as it stood with and without the Past cards row; it lay inside both frames, and must drag on, not tap.
    func testCrewRevealRejectsRecordedClippingEdge() {
        let target = CGRect(x: 372.6666666666667, y: 392, width: 44, height: 44)
        let recordedTouch = CGPoint(x: 376.83334350585938, y: 414)
        let withoutPast = CGRect(x: 16, y: 137, width: 361, height: 554.3333333333334)
        let withPast = CGRect(x: 16, y: 193, width: 361, height: withoutPast.height - 56)
        for viewport in [withoutPast, withPast] {
            XCTAssertTrue(viewport.contains(recordedTouch))
            XCTAssertTrue(target.contains(recordedTouch))
            XCTAssertFalse(crewReadyToTap(true, frame: target, in: viewport), "The recorded edge must drag on, not tap")
            let centered = target.offsetBy(dx: viewport.midX - target.midX, dy: viewport.midY - target.midY)
            XCTAssertTrue(crewReadyToTap(true, frame: centered, in: viewport))
            XCTAssertFalse(crewReadyToTap(false, frame: centered, in: viewport))
        }
    }

    /// INF-1066: each touch drag moves the scene by the target's current distance from the viewport's center,
    /// read from both frames before the gesture, then holds so no momentum carries it past the target.
    private func revealCrew(_ element: XCUIElement, in scene: XCUIElement) {
        for _ in 0..<8 {
            let viewport = scene.frame, target = element.frame
            if crewReadyToTap(element.isHittable, frame: target, in: viewport) {
                print("INF-1399 fully revealed crew: scene=\(viewport), target=\(target)")
                return
            }
            // With the scene's center already on the crewmate, the drag would barely move, and a press that never pans
            // lands as a tap on whatever crewmate is under the center. In phone run 42179127070 a warp carried the waiting
            // crewmate off the center between its frame read and the press, and the press opened another crewmate's sheet.
            // So a centered crewmate is waited for instead, and the next pass drags again if it has moved on.
            if target.contains(CGPoint(x: viewport.midX, y: viewport.midY)) {
                _ = waitForPhonePredicate(NSPredicate { _, _ in
                    self.crewReadyToTap(element.isHittable, frame: element.frame, in: scene.frame)
                }, object: nil, timeout: 2)
                continue
            }
            // A finger drags content the opposite way the viewport travels; stay inside the viewport's inner area.
            let reach = CGVector(dx: viewport.width * 0.4, dy: viewport.height * 0.4)
            let dx = max(-reach.dx, min(reach.dx, viewport.midX - target.midX))
            let dy = max(-reach.dy, min(reach.dy, viewport.midY - target.midY))
            let start = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let end = start.withOffset(CGVector(dx: dx, dy: dy))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.3)
        }
        XCTAssertTrue(crewReadyToTap(element.isHittable, frame: element.frame, in: scene.frame), "Continuous panning must bring the whole crewmate inside the scene before tapping")
    }

    /// A tap opens the crewmate under the finger where the tap itself landed, never where a drag before it started.
    /// The other computer is out of reach, so its formation holds still. The drag starts on its crewmate and rests there
    /// past the scroller's touch delay, so the scene hears it land before the scroller takes the touch over; the tap then
    /// goes to that computer's other crewmate. A tap that read the drag's landing opened the held crewmate's sheet, as
    /// taps after panning toward an orbiting crewmate opened another's (phone runs 42091135465 and 42153303451).
    private func verifyTapAfterDrag(from held: XCUIElement, to tapped: XCUIElement, in scene: XCUIElement) {
        revealCrew(held, in: scene)
        waitForSteadyTarget(held)
        let start = held.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let toward: CGFloat = held.frame.midX > scene.frame.midX ? -1 : 1
        start.press(forDuration: 0.5, thenDragTo: start.withOffset(CGVector(dx: toward * 60, dy: 0)), withVelocity: .slow, thenHoldForDuration: 0.3)
        // Another drag would land again, so the tapped crewmate must already be in full view.
        XCTAssertTrue(crewReadyToTap(tapped.isHittable, frame: tapped.frame, in: scene.frame),
                      "\(tapped.identifier) must be in full view after the drag: \(tapped.frame) in \(scene.frame)")
        // Each crewmate's label is its key, then its title.
        let title = tapped.label.components(separatedBy: ", ").dropFirst().joined(separator: ", ")
        tapOnPhone(tapped)
        let preview = app.otherElements["crew-preview"], task = preview.staticTexts["crew-summary-task"]
        XCTAssertTrue(preview.waitForPresence(timeout: 10), "A tap after a drag opens the crewmate under the finger")
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "label == %@", title), object: task, timeout: 10), .completed,
                       "A tap on \(tapped.identifier) after a drag from \(held.identifier) opens \(title), not \(task.label)")
        picture("native-scene-tap-after-drag")
        closeCrewSummary()
    }

    /// INF-2039: the first mate's warp fidget speeds the home crew up five to eleven times, and a crewmate trailing the
    /// target then reaches the point the tap aimed at before the touch lands, and opens its own sheet. So an orbiting
    /// crewmate's tap waits until every orbiting crewmate (`orbiting`, by identifier) rides one of the orbits about the
    /// first mate, their center, no faster than that orbit's own pace, then taps it at once. One snapshot of the scene
    /// reads them all together.
    private func tapOrbitingCrew(_ crewmate: XCUIElement, in scene: XCUIElement, orbiting: Set<String>, pace: PhoneOrbitPace) {
        var crew = PhoneOrbitPace.Crew(pace: pace)
        let atPace = NSPredicate { _, _ in
            guard let snapshot = try? scene.snapshot() else { return false }
            var points: [String: CGPoint] = [:], center: CGPoint?
            var pending = [snapshot]
            while let next = pending.popLast() {
                let mid = CGPoint(x: next.frame.midX, y: next.frame.midY)
                if next.identifier == "phone-character" { center = mid }
                if orbiting.contains(next.identifier) { points[next.identifier] = mid }
                pending += next.children
            }
            guard let center else { return false }
            return crew.read(points, center: center, time: ProcessInfo.processInfo.systemUptime, target: crewmate.identifier)
        }
        // A warp lasts six seconds and lets the crew go home over its release.
        XCTAssertEqual(waitForPhonePredicate(atPace, object: crewmate, timeout: 20), .completed,
                       "The crew never rode their orbits at pace to tap \(crewmate): each orbit's last turn, allowance and drift \(crew.unsteady)")
        print("INF-2039 orbiting tap at pace: \(crewmate.identifier) with \(crew.watches.count) crewmates read")
        tapOnPhone(crewmate, orbiting: true)
    }

    /// INF-499: a saved-sign-in choice reaches the computer; a failed body submits its saved draft honestly.
    private func verifyReviewedCardChoices() async throws {
        let fixture = try await home("review-cards")
        let saved = try XCTUnwrap(fixture["saved"] as? String)
        let fallback = try XCTUnwrap(fixture["fallback"] as? String)
        showCard(saved)
        let useSaved = app.buttons["card-action-saved"]
        reveal(useSaved)
        // INF-621: the failed iPad picture caught the footer before its body drew.
        // A hittable button can still be disabled; wait for the real action gate.
        waitUntilEnabled(useSaved)
        picture("saved-sign-in-choice"); tapOnPhone(useSaved)
        XCTAssertTrue(cardHeading(saved).waitForAbsence(timeout: 10))
        let accepted = try await home("card-state", method: "GET")
        let savedPast = try XCTUnwrap(accepted["saved"] as? [String: Any])
        XCTAssertEqual((savedPast["ending"] as? [String: Any])?["actionId"] as? String, "saved")
        showCard(fallback)
        // A parsed body control can exist before its document's scripts initialize.
        // The native footer's gate is the actual drawn acknowledgement for this page.
        waitUntilEnabled(app.buttons["card-action-keep"])
        let change = app.webViews.buttons["Keep the evening tide"]
        reveal(change); tapOnPhone(change)
        XCTAssertTrue(app.webViews.buttons["Evening tide saved"].waitForPresence(timeout: 10))
        // A completed page away/back witnesses receipt and restoration of the changed native draft.
        _ = try await home("show-saved-past")
        XCTAssertTrue(app.staticTexts["Past"].waitForPresence(timeout: 10)); tapOnPhone(app.buttons["put-aside-card"])
        showCard(fallback)
        let restored = app.webViews.textFields["Harbour note"]
        XCTAssertTrue(restored.waitForPresence(timeout: 10))
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value == %@", "Evening tide"), object: restored, timeout: 10), .completed)
        // The saved fill arrives before script initialization on a remount, just as on the first mount.
        waitUntilEnabled(app.buttons["card-action-keep"])
        let stall = app.webViews.buttons["Stop the chart"]
        reveal(stall); tapOnPhone(stall)
        XCTAssertTrue(app.buttons["retry-card"].waitForPresence(timeout: 20), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Choices use the last saved answers. Retry to read the card again."].exists)
        _ = try await home("capture-review-start")
        picture("saved-answer-recovery")
        let keep = app.buttons["card-action-keep"]
        reveal(keep); tapOnPhone(keep)
        XCTAssertTrue(cardHeading(fallback).waitForAbsence(timeout: 10))
        let result = try await home("card-state", method: "GET")
        let past = try XCTUnwrap(result["fallback"] as? [String: Any])
        let answers = try XCTUnwrap(past["answers"] as? [[String: Any]])
        XCTAssertEqual(answers.first?["values"] as? [String], ["Evening tide"])
        let calls = try XCTUnwrap(result["calls"] as? [[String: Any]])
        let action = try XCTUnwrap(calls.last { $0["channel"] as? String == "inf:cards:act" })
        let args = try XCTUnwrap(action["args"] as? [Any])
        XCTAssertEqual((args[4] as? [String: Any])?["reading"] as? String, "fallback")
        XCTAssertEqual((args[4] as? [String: Any])?["questionsGap"] as? String, "no-fresh-reading")
        _ = try await home("show-fallback-past")
        XCTAssertTrue(app.staticTexts["Past"].waitForPresence(timeout: 10))
        picture("saved-answer-choice")
        _ = try await home("capture-stop")
        tapOnPhone(app.buttons["put-aside-card"])
    }

    /// INF-499 #3: reading a past card gives the message its history hint, never a current-card hint.
    private func verifyPastMessageContext() async throws {
        let fixture = try await home("context-fixture")
        showCard(try XCTUnwrap(fixture["title"] as? String))
        // INF-2794: the note's own Got it reads it into the past; the corner would only put it aside.
        let gotIt = app.buttons["note-done"]
        XCTAssertTrue(gotIt.waitForPresence(timeout: 10), app.debugDescription)
        reveal(gotIt)
        tapOnPhone(gotIt)
        _ = try await home("show-context-past")
        XCTAssertTrue(app.staticTexts["Past"].waitForPresence(timeout: 10))
        let input = app.textFields["message-box"]
        focusForPhoneTyping(input, in: app); input.typeText(try XCTUnwrap(fixture["text"] as? String))
        tapOnPhone(app.buttons["send-message"])
        let sent = try await home("context-sent")
        let writes = try XCTUnwrap(sent["writes"] as? [[String: Any]])
        let payload = try XCTUnwrap((writes.last?["args"] as? [[String: Any]])?.first)
        XCTAssertEqual(payload["pastCardId"] as? String, fixture["id"] as? String)
        XCTAssertNil(payload["visibleCardId"])
        XCTAssertNil(payload["taskId"])
        picture("message-about-past-card")
        tapOnPhone(app.buttons["put-aside-card"])
    }
}
