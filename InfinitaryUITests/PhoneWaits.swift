import XCTest

// The load clock, `PhoneWaitDeadline`, lives in PhoneLoadClock/, shared with the app-hosted tests.

/// Test-control requests go only to the disposable home, never the app's transport.
/// Race one request (never a retry) against the same load deadline as native observations.
/// URLSession cancellation joins the request before the caller resumes.
enum phoneTestSession {
    private static let session = URLSession(configuration: .ephemeral)

    static func data(for original: URLRequest) async throws -> (Data, URLResponse) {
        var request = original
        let budget = request.timeoutInterval
        if !gradesBudgets { request.timeoutInterval = phoneRequestBudget(budget) }
        let prepared = request
        return try await withThrowingTaskGroup(of: (Data, URLResponse).self) { group in
            group.addTask { try await session.data(for: prepared) }
            group.addTask {
                var deadline = PhoneWaitDeadline(budget)
                while !deadline.expired() {
                    try await Task.sleep(for: .seconds(PhoneWaitDeadline.tick))
                }
                throw URLError(.timedOut)
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }
}

@MainActor extension XCUIElement {
    func waitForPresence(timeout: TimeInterval) -> Bool {
        waitForPhonePredicate(NSPredicate { _, _ in self.exists }, object: self, timeout: timeout) == .completed
    }

    func waitForAbsence(timeout: TimeInterval) -> Bool {
        waitForPhonePredicate(NSPredicate { _, _ in !self.exists }, object: self, timeout: timeout) == .completed
    }
}

/// INF-975: evaluate the predicate directly, not through short XCTest expectation windows,
/// which can time out before XCTest ever evaluates it. The run loop services native reads.
@MainActor func waitForPhonePredicate(_ predicate: NSPredicate, object: Any?, timeout: TimeInterval) -> XCTWaiter.Result {
    var deadline = PhoneWaitDeadline(timeout)
    if predicate.evaluate(with: object) { return .completed }
    repeat {
        if deadline.expired() {
            print("Phone wait failed: predicate remained unsatisfied; budget \(timeout)s, cap \(gradesBudgets ? timeout : phoneRequestBudget(timeout))s")
            return .timedOut
        }
        RunLoop.current.run(until: Date(timeIntervalSinceNow: PhoneWaitDeadline.tick))
        if deadline.expired() { continue }
        if predicate.evaluate(with: object) { return .completed }
    } while true
}

/// INF-1541 piece 1: a reading is steady once it reads the same twice in a row; a target not found is never steady.
struct PhoneSteadyReading<Reading: Equatable> {
    private var last: Reading?

    mutating func read(_ reading: Reading?) -> Bool {
        defer { last = reading }
        return reading != nil && reading == last
    }
}

/// What a target shows: its frame, and the screen's own pixels inside that frame while it is on the screen.
private struct PhoneTargetReading: Equatable {
    let frame: CGRect
    let drawn: Data?
}

/// INF-1541 piece 1: XCTest no longer waits for the app's animations before a tap (PhoneAnimationWait.swift), so a tap
/// checks its own target. Its frame alone is not enough: UIKit gives a sheet or an alert its final frame as it starts to
/// slide or fade in, and drops a touch until it has arrived. In piece 1's first run the link field's frame read the same
/// from the first read, while the screen inside it changed for half a second, and the tap that fell in that half second
/// never focused the field. So the target holds still once its frame and the screen's pixels inside it read the same
/// twice in a row.
@MainActor func waitForSteadyTarget(_ element: XCUIElement, timeout: TimeInterval = 10) {
    _ = waitForTarget(element, timeout: timeout) { _ in true }
}

/// INF-1477 / INF-1541 piece 1: XCTest no longer waits out a view's entrance either, and a control that has just appeared
/// can read no tap point yet: on a busy iPad the sidebar's first group read none right after it appeared. So a check that
/// a control can be pressed waits on the load clock until XCTest finds its tap point (`isHittable`).
@MainActor func waitForPhonePress(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
    waitForPhonePredicate(NSPredicate { _, _ in element.isHittable }, object: element, timeout: timeout) == .completed
}

/// INF-1541 piece 1: XCTest no longer waits out a display change either, so a reading after one waits until the screen
/// inside `element` draws differently than `before`, read before the change, and holds still. Returns what it drew.
@MainActor func waitForRedraw(_ element: XCUIElement, from before: Data?, timeout: TimeInterval = 10) -> Data? {
    waitForTarget(element, timeout: timeout) { $0.drawn != nil && $0.drawn != before }?.drawn
}

/// INF-1541 piece 1: XCTest no longer waits out the device turning either. Until the app turns, a target holds still
/// where it was; once it turns, the target's frame reads its new place while the screen inside it still moves. So a
/// reading after a turn waits until `moved`, a target the turn carries elsewhere, has left the frame it read before the
/// turn, and its frame and the screen inside it hold still in the new place.
@MainActor func turnPhone(to orientation: UIDeviceOrientation, in app: XCUIApplication, moving moved: XCUIElement) {
    let before = (try? moved.snapshot())?.frame
    XCUIDevice.shared.orientation = orientation
    app.activate()
    _ = waitForTarget(moved, timeout: 10) { $0.frame != before }
}

/// Reads a load-clock tick apart until the target reads the same twice in a row and `settled` accepts it.
@MainActor private func waitForTarget(_ element: XCUIElement, timeout: TimeInterval,
                                      until settled: @escaping (PhoneTargetReading) -> Bool) -> PhoneTargetReading? {
    var steady = PhoneSteadyReading<PhoneTargetReading>()
    var last: PhoneTargetReading?
    let held = NSPredicate { _, _ in
        // The screen's bounds, in the same coordinates as every element's frame, read each time since a turn moves them.
        let screen = XCUIApplication().frame
        last = (try? element.snapshot()).map { snapshot in
            // A target off the screen draws nothing there yet; XCTest scrolls it into view as it taps.
            PhoneTargetReading(frame: snapshot.frame,
                               drawn: snapshot.frame.intersects(screen) ? element.screenshot().pngRepresentation : nil)
        }
        return steady.read(last) && last.map(settled) == true
    }
    XCTAssertEqual(waitForPhonePredicate(held, object: element, timeout: timeout), .completed,
                   "\(element) did not settle: its last frame read \(last.map { "\($0.frame)" } ?? "nothing")")
    return last
}

/// INF-1083 / INF-1122: presence is not keyboard focus. Send one tap, then observe
/// UIKit's actual first-responder state before asking XCTest to synthesize typing.
@MainActor func focusForPhoneTyping(_ input: XCUIElement, in app: XCUIApplication) {
    XCTAssertTrue(input.waitForPresence(timeout: 10), app.debugDescription)
    XCTAssertEqual(waitForPhonePredicate(NSPredicate { _, _ in input.isEnabled && input.isHittable },
        object: input, timeout: 10), .completed, app.debugDescription)
    tapOnPhone(input)
    // INF-1377: the first letter keyboard can show iOS's typing guide. Dismiss that
    // known interruption before observing focus; send no tap beyond tapOnPhone's proven second one, and no priming text.
    // INF-1525: the guide rises with the keyboard, after the tap returns, so look for it only once
    // the keyboard or the guide is up; reading it at once missed it and typing found no focus.
    let guide = app.staticTexts["Speed up your typing by sliding your finger across the letters to compose a word."]
    XCTAssertEqual(waitForPhonePredicate(NSPredicate { _, _ in app.keyboards.firstMatch.exists || guide.exists },
        object: input, timeout: 10), .completed, app.debugDescription)
    if guide.exists {
        tapOnPhone(app.buttons["Continue"])
        XCTAssertTrue(guide.waitForAbsence(timeout: 10), app.debugDescription)
    }
    XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "hasKeyboardFocus == true"),
        object: input, timeout: 10), .completed, app.debugDescription)
}

/// The native count includes every named answer, not only required questions.
/// Match equal, nonzero observed counts rather than inventing a fixture-specific total.
/// INF-1524: a card counts in the Mac's words, "picked" (a preview says "answered"), with "· N changed" once a pick moved.
let phoneAnsweredFormPattern = #"([1-9][0-9]*) of \1 (picked|answered)( · [1-9][0-9]* changed)?"#

@MainActor func waitForAnsweredPhoneForm(in app: XCUIApplication) {
    let complete = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", phoneAnsweredFormPattern)).firstMatch
    XCTAssertTrue(complete.waitForPresence(timeout: 10), app.debugDescription)
}
