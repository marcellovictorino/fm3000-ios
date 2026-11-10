import XCTest

/// INF-209 / INF-230: one real composer keeps the talk journey's unsent text/photo across tabs and rotation.
/// Called by the composed journey after typing its real ask, before sending it to the disposable computer.
@MainActor func verifyPhoneComposerDrafts(
    app: XCUIApplication, words: String, tab: (String) -> Void, picture: (String) -> Void,
    recordKeyboard: (Bool) async throws -> Void
) async throws {
    let input = app.textFields["message-box"]
    verifyPhoneComposerBounds(app: app)
    picture("composed-draft-keyboard")
    try await recordKeyboard(true)
    try await dismissPhoneJourneyKeyboard(app: app)
    XCTAssertEqual(input.value as? String, words)
    XCTAssertEqual(app.buttons.matching(identifier: "photo-chip").count, 1)
    try await recordKeyboard(false)

    // Exercise the removal control as well as Photos and Send, without losing the unsent words.
    tapOnPhone(app.buttons["photo-chip"])
    XCTAssertEqual(app.buttons.matching(identifier: "photo-chip").count, 0)
    XCTAssertEqual(input.value as? String, words)
    addPhoneJourneyPhoto(app: app)
    // INF-944 item 6: the tabs in their order, Activity last. INF-1062: the message box is Home's alone, so Tasks and
    // Activity show none, and the draft waits out of view until Home comes back.
    let column = phoneReadingColumn(app: app)
    for name in ["Tasks", "Activity", "Home"] {
        tab(name)
        let surface = name == "Activity" ? app.scrollViews["activity-list"]
            : name == "Tasks" ? phoneTasksColumn(app) : app.scrollViews["card-scroll"]
        XCTAssertTrue(surface.waitForPresence(timeout: 10), "The requested tab actually opens")
        XCTAssertTrue(waitForPhonePress(surface))
        if name == "Tasks" { verifyPhoneReadingColumn(surface, column: column) }
        if name == "Home" { verifyPhoneCardWidth(surface, app: app) }
        if name == "Home" {
            XCTAssertEqual(input.value as? String, words, "Changing tabs keeps the unsent words")
            XCTAssertEqual(app.buttons.matching(identifier: "photo-chip").count, 1, "Changing tabs keeps the picked photo")
            XCTAssertEqual(app.textFields.matching(identifier: "message-box").count, 1)
            verifyPhoneComposerBounds(app: app)
        } else {
            XCTAssertFalse(input.exists, "\(name) runs to the foot with no message box over it")
            XCTAssertFalse(app.otherElements["phone-composer"].exists)
        }
    }
    picture("draft-after-tabs")
    // INF-1541 piece 1: the message box moves to the foot of the turned screen, so the turn waits for it to settle there.
    turnPhone(to: .landscapeLeft, in: app, moving: input)
    XCTAssertTrue(input.waitForPresence(timeout: 10))
    if UIDevice.current.userInterfaceIdiom == .pad {
        let sidebar = phoneSidebar(app)
        XCTAssertTrue(sidebar.waitForPresence(timeout: 10))
        // INF-1062: the landscape iPad shows the stage and its sidebar, so the bar carries no strip.
        XCTAssertFalse(app.buttons["tab-home"].exists, "Landscape columns have no strip above them")
        XCTAssertLessThanOrEqual(sidebar.frame.maxX, input.frame.minX,
            "The landscape composer belongs to the stage beside the sidebar")
        verifyPhoneCardWidth(app.scrollViews["card-scroll"], app: app, after: sidebar)
        tapOnPhone(phoneSidebarRail("Tasks", in: sidebar))
        // The search waits above the list until it is pulled down (INF-589 item 9), so the list's column stands for Tasks.
        let tasks = phoneTasksColumn(sidebar)
        XCTAssertTrue(tasks.waitForPresence(timeout: 10), "The Tasks rail shows Tasks in the landscape sidebar")
        XCTAssertTrue(waitForPhonePress(tasks))
    }
    XCTAssertEqual(input.value as? String, words, "Rotating keeps the unsent words")
    XCTAssertTrue(waitForPhonePress(input), "The composer remains visible at the stage's foot")
    XCTAssertGreaterThan(input.frame.minY, app.frame.midY)
    XCTAssertEqual(app.buttons.matching(identifier: "photo-chip").count, 1)
    XCTAssertEqual(app.textFields.matching(identifier: "message-box").count, 1)
    verifyPhoneComposerBounds(app: app)
    // INF-82: draft retention alone missed a card reduced to a thin attribution strip.
    // Read the complete native heading, then scroll actual body text and an action into view.
    if UIDevice.current.userInterfaceIdiom == .phone {
        // INF-944 items 1 and 2: the card's frame holds its head and choices; its body scrolls inside it.
        // A short card scrolls whole, its frame then being its scroller.
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'card-frame' OR identifier == 'card-scroll'")).firstMatch
        let title = app.staticTexts["card-title"]
        XCTAssertTrue(phoneCardReadingBounds(card, app: app).contains(phoneAccessibilityBounds(title.frame)),
            "Landscape leaves room to read the full card heading, not just its attribution")
        XCTAssertTrue(waitForPhonePress(title))
        picture("draft-landscape")
        let body = app.webViews.staticTexts.firstMatch
        let action = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'card-action-'")).firstMatch
        // The body reads inside its scroller; a choice may be pinned at the frame's foot or scroll with a short card's body.
        for (element, region) in [(body, app.scrollViews["card-scroll"]), (action, card)] {
            revealPhoneCardReading(element, in: region, app: app)
            XCTAssertTrue(waitForPhonePress(element), "The landscape card can be read and used")
            XCTAssertTrue(phoneCardReadingBounds(region, app: app).contains(phoneAccessibilityBounds(element.frame)),
                "Landscape shows the complete reading \(element.frame) inside \(phoneCardReadingBounds(region, app: app)), not a clipped sliver")
            picture(element.elementType == .button ? "draft-landscape-card-action" : "draft-landscape-card-body")
        }
        revealPhoneCardReading(title, in: card, app: app)
        XCTAssertTrue(phoneCardReadingBounds(card, app: app).contains(phoneAccessibilityBounds(title.frame)))
        XCTAssertEqual(input.value as? String, words, "Reading the card leaves the draft alone")
        XCTAssertEqual(app.buttons.matching(identifier: "photo-chip").count, 1)
    } else { picture("draft-landscape") }
    if UIDevice.current.userInterfaceIdiom == .pad {
        let sidebar = phoneSidebar(app)
        tapOnPhone(phoneSidebarRail("Activity", in: sidebar))
        XCTAssertTrue(sidebar.staticTexts.matching(identifier: "activity-text").firstMatch.waitForPresence(timeout: 10))
    }
    turnPhone(to: .portrait, in: app, moving: input)
    XCTAssertTrue(phoneSidebar(app).waitForAbsence(timeout: 10))
    XCTAssertTrue(input.waitForPresence(timeout: 10))
    XCTAssertEqual(input.value as? String, words)
    XCTAssertEqual(app.buttons.matching(identifier: "photo-chip").count, 1)
    verifyPhoneComposerBounds(app: app)
    picture("draft-returned-to-portrait")
    tapOnPhone(input)
    try await dismissPhoneJourneyKeyboard(app: app, usingKey: true)
    XCTAssertEqual(input.value as? String, words, "The keyboard command does not type into the draft")
    XCTAssertEqual(app.buttons.matching(identifier: "photo-chip").count, 1)
    // The full journey has relaunched before this point: sibling app commands must still work too.
    try await pressPhoneKey("i", modifiers: .command, in: app)
    let closeDetails = app.buttons["close-computer-details"]
    XCTAssertTrue(closeDetails.waitForPresence(timeout: 10))
    // INF-499 #8: one real press must not send the retained text/photo behind a native sheet.
    try await pressPhoneKey(XCUIKeyboardKey.return.rawValue, modifiers: .command, in: app)
    picture("sheet-after-command-return")
    tapOnPhone(closeDetails)
    XCTAssertTrue(closeDetails.waitForAbsence(timeout: 10))
    picture("draft-after-sheet-command-return")
    XCTAssertEqual(input.value as? String, words)
    XCTAssertEqual(app.buttons.matching(identifier: "photo-chip").count, 1)
}

/// The native scroll view extends behind translucent navigation chrome; that covered area is not readable.
@MainActor func phoneCardReadingBounds(_ card: XCUIElement, app: XCUIApplication) -> CGRect {
    let frame = phoneAccessibilityBounds(card.frame.intersection(app.frame))
    let top = max(frame.minY, phoneAccessibilityBounds(app.navigationBars.firstMatch.frame).maxY)
    return CGRect(x: frame.minX, y: top, width: frame.width, height: max(0, frame.maxY - top))
}

/// A short viewport needs a measured drag, not an inertial whole-view swipe that skips a paragraph.
/// Keep the same complete-containment assertion, and scroll toward the actual element in either direction.
@MainActor func revealPhoneCardReading(_ element: XCUIElement, in card: XCUIElement, app: XCUIApplication) {
    let scroller = app.scrollViews["card-scroll"]
    for _ in 0..<8 {
        let frame = phoneAccessibilityBounds(element.frame)
        // XCTest cannot resolve a hit point for an entirely offscreen native label.
        // Geometry decides whether to scroll first; hittability is still required once it is visible.
        if phoneCardReadingBounds(card, app: app).contains(frame) && element.isHittable { return }
        // Drag inside the body's own scroller, which the frame's pinned head and choices do not scroll.
        let visible = phoneCardReadingBounds(scroller, app: app)
        let distance = min(visible.height * 0.6, abs(frame.midY - visible.midY))
        let direction: CGFloat = frame.midY > visible.midY ? 1 : -1
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let start = origin.withOffset(CGVector(dx: visible.midX, dy: visible.midY + direction * distance / 2))
        let end = origin.withOffset(CGVector(dx: visible.midX, dy: visible.midY - direction * distance / 2))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }
}

/// INF-1832: selection and a visible preview outrank a settled grid; absence alone proves nothing.
enum PhonePhotoOutcome: String { case selected, preview, settled }

enum PhonePhotoRecoveryFailure: String {
    case unresolved = "The photo picker neither selected a photo, showed a preview nor settled"
    case previewAfterClose = "The photo picker showed another preview after its one closing tap"
}

struct PhonePhotoObservation {
    private var steady = PhoneSteadyReading<PhoneTargetReading>()

    mutating func read(selected: Bool, preview: Bool, target: PhoneTargetReading?) -> PhonePhotoOutcome? {
        if selected { _ = steady.read(nil); return .selected }
        if preview { _ = steady.read(nil); return .preview }
        // Offscreen targets have no pixels. Missing/unreadable targets reset the consecutive-reading proof.
        return steady.read(target?.drawn == nil ? nil : target) ? .settled : nil
    }
}

/// Called only after the picker's positive press-and-hold proof and before the one allowed additional photo tap.
/// The closures also let the native regression replay real picker readings without sending another touch.
@MainActor func recoverPhonePhoto(
    selected: @escaping () -> Bool, preview: @escaping () -> Bool,
    target: @escaping () -> PhoneTargetReading?, closedPreview: inout Bool,
    timeout: TimeInterval = 10, failure: (PhonePhotoRecoveryFailure) -> Void = { XCTFail($0.rawValue) },
    close: () -> Void
) -> PhonePhotoOutcome? {
    let started = ProcessInfo.processInfo.systemUptime
    var observation = PhonePhotoObservation()
    var outcome: PhonePhotoOutcome?
    while true {
        let result = waitForPhonePredicate(NSPredicate { _, _ in
            let chosen = selected(), shown = preview()
            outcome = observation.read(selected: chosen, preview: shown, target: chosen || shown ? nil : target())
            return outcome != nil
        }, object: nil, timeout: timeout)
        guard result == .completed, let observed = outcome else {
            failure(.unresolved)
            return nil
        }
        print("Photo picker readiness: \(observed.rawValue), elapsed=\(ProcessInfo.processInfo.systemUptime - started)s")
        if observed == .selected || selected() { return .selected }
        // Recheck immediately before authorizing another tap: a preview can arrive after the grid's second reading.
        if observed == .preview || preview() {
            guard !closedPreview else {
                failure(.previewAfterClose)
                return nil
            }
            closedPreview = true
            close()
            guard !PhoneFailures.recorded else { return nil }
            observation = PhonePhotoObservation()
            continue
        }
        return .settled
    }
}

/// INF-1477 (the captain's choice "Allow one more photo tap"): a photo tap the iPhone delivered can reach the picker as a
/// press-and-hold when its lift arrives late, as in phone run 40486884004, and the picker then previews the photo and
/// chooses nothing. Only the picker's own line for that press (the test home's picker-preview) sends one more tap, once the
/// photo holds still again and is still not chosen: the iPad's picker in the same run logged that line and chose the photo.
/// The preview stays open after the lift and hides the photo from the accessibility tree, as a 1.8 second press showed on
/// the iPhone, so a tap on the dimmed screen below it closes it first (closePhonePickerPreview; the captain's choice
/// "Allow the closing tap").
@MainActor private func pickPhoneJourneyPhoto(_ photo: XCUIElement, add: XCUIElement, in app: XCUIApplication) {
    // iOS 26 exposes the real asset frame, but not a hittable AX point; never guess a screen coordinate.
    let point = photo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let chosen = NSPredicate { _, _ in add.exists && add.isEnabled }
    var held: [String] = []
    var closedPreview = false
    for _ in 0..<2 {
        let since = Date().timeIntervalSince1970 * 1000
        tapOnPhone(point)
        guard !PhoneFailures.recorded else { return }
        let answer: [String: Any]
        do {
            let reading = try askPhoneHome("picker-preview", since: since)
            _ = waitForPhonePredicate(NSPredicate { _, _ in reading.value != nil || chosen.evaluate(with: nil) },
                                      object: nil, timeout: 40)
            if reading.value == nil, chosen.evaluate(with: nil) { return }
            answer = try reading.answer()
        } catch {
            XCTFail("The photo picker's reading of the photo tap was not read: \(error)")
            return
        }
        guard answer["previewed"] as? Bool == true, let proof = answer["proof"] as? String else {
            if !chosen.evaluate(with: nil) { XCTFail("The picker chose no photo and logged no press-and-hold: \(answer)") }
            return
        }
        print("Photo picker press-and-hold: \(proof)")
        held.append(proof)
        if chosen.evaluate(with: nil) { return }
        guard held.count < 2 else { break }
        let preview = app.otherElements["Preview"]
        let recovered = recoverPhonePhoto(
            selected: { chosen.evaluate(with: nil) }, preview: { preview.exists },
            target: { readPhoneTarget(photo) }, closedPreview: &closedPreview,
            close: { closePhonePickerPreview(preview, in: app) })
        guard !PhoneFailures.recorded, recovered != nil else { return }
        if recovered == .selected { return }
    }
    XCTFail("The photo picker read both photo taps as a press-and-hold: \(held)")
}

/// The preview's dimmed screen closes it on a tap outside the preview; below it lies only the photo grid.
@MainActor func closePhonePickerPreview(_ preview: XCUIElement, in app: XCUIApplication) {
    let window = app.windows.firstMatch
    waitForSteadyTarget(preview)
    let screen = window.frame, shown = preview.frame
    tapOnPhone(window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: (shown.maxY + screen.maxY) / 2 / screen.height)))
    XCTAssertTrue(preview.waitForAbsence(timeout: 10), "The photo picker's preview stayed open: \(app.debugDescription)")
}

/// The single native picker reader for the composed-draft and send journey.
@MainActor func addPhoneJourneyPhoto(app: XCUIApplication) {
    let photos = app.buttons["add-photos"]
    XCTAssertTrue(waitForPhonePress(photos)); tapOnPhone(photos)
    // INF-1576: a library photo's cell reads its kind, a comma and its date ("Photo, October 27, 12:04 AM"); the iPad
    // picker's sidebar comes first with an icon read "Photo on a rectangle", and pressing it picks nothing.
    let photo = app.images.matching(NSPredicate(format: "label BEGINSWITH 'Photo, ' OR label BEGINSWITH 'Screenshot, '")).firstMatch
    XCTAssertTrue(photo.waitForPresence(timeout: 10), app.debugDescription)
    let add = app.buttons.matching(NSPredicate(format: "label == 'Done' OR label == 'Add'")).firstMatch
    pickPhoneJourneyPhoto(photo, add: add, in: app)
    XCTAssertTrue(add.waitForPresence(timeout: 10)); XCTAssertTrue(add.isEnabled); tapOnPhone(add)
    // INF-662 piece 2: with other simulators beside this one, Photos has taken just over 10 seconds
    // to hand the picked photo's bytes over; the chip appears once they have loaded.
    XCTAssertTrue(app.buttons["photo-chip"].waitForPresence(timeout: 30), app.debugDescription)
}

/// INF-230: the actual footer contains every visible row and does not overlap the keyboard; INF-1062: it sits in Home's
/// own column with no bar under it.
@MainActor func verifyPhoneComposerBounds(app: XCUIApplication) {
    let footer = app.otherElements["phone-composer"].firstMatch
    XCTAssertTrue(footer.waitForPresence(timeout: 10))
    let controls = [app.textFields["message-box"], app.buttons["add-photos"], app.buttons["send-message"],
                    app.buttons["photo-chip"], app.staticTexts["last-turn-you"],
                    app.descendants(matching: .any).matching(identifier: "last-turn-reply").firstMatch,
                    app.staticTexts["connection-refusal"], app.staticTexts["message-problem"]]
    for control in controls where control.exists {
        XCTAssertTrue(phoneAccessibilityBounds(footer.frame).contains(phoneAccessibilityBounds(control.frame)),
            "The footer clips \(control.identifier): \(control.frame) outside \(footer.frame)")
        if control.elementType == .button && control.isEnabled {
            // INF-1541 piece 1: XCTest no longer waits out the stage's change, so a press's check waits, as a tap does, for
            // its target to hold still. Right after the last card closed on the iPad, the reply line had no tap point yet.
            waitForSteadyTarget(control)
            XCTAssertTrue(control.isHittable, "The footer control \(control.identifier) can be pressed")
        }
    }
    XCTAssertTrue(app.frame.contains(footer.frame), "The footer fits inside the window")
    // INF-230 review: the card's pager belongs between its scrollable body and the composer,
    // including the iPad's top-tab and landscape layouts, not underneath the overlay.
    let card = app.scrollViews["card-scroll"]
    if card.exists {
        let pager = app.descendants(matching: .any).matching(identifier: "card-pager").firstMatch
        XCTAssertTrue(pager.waitForPresence(timeout: 10))
        waitForSteadyTarget(pager)
        XCTAssertTrue(pager.isHittable, "The card pager is not covered by the composer")
        for id in ["previous-card", "card-pager", "next-card"] {
            let control = app.descendants(matching: .any).matching(identifier: id).firstMatch
            if !control.exists { continue }
            let frame = phoneAccessibilityBounds(control.frame)
            XCTAssertTrue(phoneAccessibilityBounds(app.frame).contains(frame), "The entire \(id) stays on screen")
            XCTAssertLessThanOrEqual(frame.maxY, phoneAccessibilityBounds(footer.frame).minY,
                "\(id) \(control.frame) belongs above the composer \(footer.frame)")
            XCTAssertLessThanOrEqual(phoneAccessibilityBounds(card.frame).maxY, frame.minY,
                "The card scroll area stays above \(id), rather than extending behind it")
            if control.isEnabled {
                waitForSteadyTarget(control)
                XCTAssertTrue(control.isHittable, "\(id) remains usable above the composer")
            }
        }
    }
    let keyboard = app.keyboards.firstMatch
    if keyboard.exists {
        XCTAssertLessThanOrEqual(footer.frame.maxY, keyboard.frame.minY, "The composer stays above the keyboard")
    } else {
        // INF-1062: with no bar under it, the message box sits at the foot of the window, above only the home indicator.
        XCTAssertLessThan(app.frame.maxY - footer.frame.maxY, 60, "The composer \(footer.frame) sits at the foot of \(app.frame)")
    }
}

/// AX containers use Float coordinates while their children can expose Double coordinates.
/// Compare at the container's precision, rather than mistaking floating-point noise for a clipped pixel.
@MainActor func phoneAccessibilityBounds(_ frame: CGRect) -> CGRect {
    let x = CGFloat(Float(frame.minX)), y = CGFloat(Float(frame.minY))
    return CGRect(x: x, y: y, width: CGFloat(Float(frame.maxX)) - x, height: CGFloat(Float(frame.maxY)) - y)
}

/// Done and the native Hide keyboard command leave the actual component-owned draft untouched.
@MainActor private func dismissPhoneJourneyKeyboard(app: XCUIApplication, usingKey: Bool = false) async throws {
    let done = app.navigationBars.buttons["dismiss-phone-keyboard"]
    XCTAssertTrue(done.waitForPresence(timeout: 10))
    XCTAssertTrue(waitForPhonePress(done))
    if usingKey { try await pressPhoneKey("k", modifiers: [.command, .shift], in: app) } else { tapOnPhone(done) }
    XCTAssertTrue(app.keyboards.firstMatch.waitForAbsence(timeout: 10))
}

/// INF-589 item 15: the reading column, read from the message box on Home, where it is (INF-1062).
@MainActor func phoneReadingColumn(app: XCUIApplication) -> ClosedRange<CGFloat> {
    let left = phoneAccessibilityBounds(app.buttons["add-photos"].frame).minX
    let right = phoneAccessibilityBounds(app.buttons["send-message"].frame).maxX
    return left...right
}

/// INF-3110, the captain's "widen the card only": the card takes its stage's whole width less the stage's 16-point
/// gutters (`PhoneTheme.space4`), so on an iPad it is wider than the message box and the next card shows only its edge.
/// The stage starts after the landscape iPad's sidebar and the 1-point line beside it.
@MainActor func verifyPhoneCardWidth(_ card: XCUIElement, app: XCUIApplication, after sidebar: XCUIElement? = nil) {
    let gutter: CGFloat = 16
    let frame = phoneAccessibilityBounds(card.frame), window = phoneAccessibilityBounds(app.frame)
    let start = sidebar.map { phoneAccessibilityBounds($0.frame).maxX + 1 } ?? window.minX
    XCTAssertEqual(frame.minX, start + gutter, accuracy: 1, "The card \(card.frame) starts one gutter into its stage")
    XCTAssertEqual(frame.maxX, window.maxX - gutter, accuracy: 1, "The card \(card.frame) ends one gutter before the window's edge")
}

/// INF-589 item 15: the Tasks list and the message box share one centred reading column on any width.
@MainActor func verifyPhoneReadingColumn(_ surface: XCUIElement, column: ClosedRange<CGFloat>) {
    let frame = phoneAccessibilityBounds(surface.frame)
    XCTAssertEqual(frame.minX, column.lowerBound, accuracy: 1, "\(surface.identifier) \(surface.frame) starts where the message box does")
    XCTAssertEqual(frame.maxX, column.upperBound, accuracy: 1, "\(surface.identifier) \(surface.frame) ends where the message box does")
}

/// The iPad's landscape sidebar, a container holding its Activity and Tasks pair.
@MainActor func phoneSidebar(_ app: XCUIApplication) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: "phone-sidebar").firstMatch
}

/// INF-2928 piece 1: the Tasks list's reading column, which stands for Tasks whichever groups have rows: only those show.
@MainActor func phoneTasksColumn(_ root: XCUIElement) -> XCUIElement {
    root.descendants(matching: .any).matching(identifier: "tasks-column").firstMatch
}

/// INF-209: read the sidebar's own Activity or Tasks segment, never the identically named tab.
@MainActor func phoneSidebarRail(_ name: String, in sidebar: XCUIElement) -> XCUIElement {
    sidebar.buttons[name]
}
