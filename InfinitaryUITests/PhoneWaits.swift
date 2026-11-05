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
struct PhoneTargetReading: Equatable {
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

/// One sampler owns native target frames and their on-screen pixels, including the photo recovery observation.
@MainActor func readPhoneTarget(_ element: XCUIElement) -> PhoneTargetReading? {
    // The screen's bounds are read again because a turn moves them.
    let screen = XCUIApplication().frame
    return (try? element.snapshot()).flatMap { snapshot in
        // A target off the screen draws nothing there yet; XCTest scrolls it into view as it taps.
        guard snapshot.frame.intersects(screen) else { return PhoneTargetReading(frame: snapshot.frame, drawn: nil) }
        // INF-2101: element.screenshot() checks existence and resolves this same target again. Read the actual
        // display instead and crop at the frame we just read; keep both fresh frame queries and the pixel check.
        guard let drawn = phoneTargetPixels({ XCUIScreen.main.screenshot().image }, frame: snapshot.frame, screen: screen,
                                            scale: UIScreen.main.scale, native: { element.screenshot().pngRepresentation }) else { return nil }
        return PhoneTargetReading(frame: snapshot.frame, drawn: drawn)
    }
}

/// Reads a load-clock tick apart until the target reads the same twice in a row and `settled` accepts it.
@MainActor private func waitForTarget(_ element: XCUIElement, timeout: TimeInterval,
                                      until settled: @escaping (PhoneTargetReading) -> Bool) -> PhoneTargetReading? {
    var steady = PhoneSteadyReading<PhoneTargetReading>()
    var last: PhoneTargetReading?
    let held = NSPredicate { _, _ in
        last = readPhoneTarget(element)
        return steady.read(last) && last.map(settled) == true
    }
    XCTAssertEqual(waitForPhonePredicate(held, object: element, timeout: timeout), .completed,
                   "\(element) did not settle: its last frame read \(last.map { "\($0.frame)" } ?? "nothing")")
    return last
}

/// INF-2101 / INF-2251: XCTest truncates to test parity, retaining the original float when that integer is even.
/// UIKit then allocates from Float, rounded to nearest with ties away. Do not round before testing parity.
func phoneCaptureExtent(_ pixels: CGFloat) -> CGFloat {
    let integer = pixels.rounded(.towardZero)
    let supplied = integer.truncatingRemainder(dividingBy: 2) == 1 ? integer - 1 : pixels
    return CGFloat(Float(supplied).rounded(.toNearestOrAwayFromZero))
}

/// Only pixel-aligned, fully visible frames can be reconstructed by an integer crop of the existing capture.
/// Genuine subpixel origins keep their phase in UIKit's native rendering, so they must use native capture instead.
func phoneTargetCrop(frame: CGRect, screen: CGRect, scale: CGFloat, orientation: UIImage.Orientation,
                     backing: CGSize) -> CGRect? {
    guard scale.isFinite, scale > 0, !screen.isEmpty, !screen.isInfinite, !frame.isEmpty, !frame.isInfinite,
          screen.contains(frame) else { return nil }
    let x = frame.minX - screen.minX, y = frame.minY - screen.minY, w = frame.width, h = frame.height
    let raw: CGRect
    switch orientation {
    case .up: raw = CGRect(x: x, y: y, width: w, height: h)
    case .down: raw = CGRect(x: screen.width - (x + w), y: screen.height - (y + h), width: w, height: h)
    case .left: raw = CGRect(x: screen.height - (y + h), y: x, width: h, height: w)
    case .right: raw = CGRect(x: y, y: screen.width - (x + w), width: h, height: w)
    default: return nil
    }
    let pixelX = raw.minX * scale, pixelY = raw.minY * scale
    // Permit only floating-point representation error around the pixel grid, not a visual tolerance.
    // Sum one ULP for the input coordinates and each intermediate add/subtract, then the scaling operations.
    let pointError = [frame.minX, frame.minY, w, h, screen.minX, screen.minY, screen.width, screen.height,
                      x, y, x + w, y + h, raw.minX, raw.minY].reduce(CGFloat.zero) { $0 + $1.ulp }
    let pixelError = pointError * scale + pixelX.ulp + pixelY.ulp
    guard abs(pixelX - pixelX.rounded()) <= pixelError, abs(pixelY - pixelY.rounded()) <= pixelError else { return nil }
    let crop = CGRect(x: pixelX.rounded(), y: pixelY.rounded(),
                      width: phoneCaptureExtent(raw.width * scale), height: phoneCaptureExtent(raw.height * scale))
    guard !crop.isEmpty, !crop.isInfinite, CGRect(origin: .zero, size: backing).contains(crop) else { return nil }
    return crop
}

/// INF-2101: crop the raw backing before rotating. Its actual size can differ from logical screen points × scale.
/// Unsupported geometry retains XCTest's native pixels; an unreadable supported crop is never a steady blank target.
@MainActor func phoneTargetPixels(_ capture: () -> UIImage, frame: CGRect, screen: CGRect, scale: CGFloat,
                                 native: () -> Data? = { nil }) -> Data? {
    guard frame.intersects(screen) else { return nil }
    // INF-2291: decide from the frame before spending a display capture on a native-fallback target.
    // The capture supplies its orientation later. Conservatively require support in every unmirrored orientation;
    // the same crop owner checks containment and pixel alignment, without duplicating its geometry rules here.
    let upright = CGSize(width: screen.width * scale, height: screen.height * scale)
    let turned = CGSize(width: upright.height, height: upright.width)
    for (orientation, backing) in [(UIImage.Orientation.up, upright), (.down, upright), (.left, turned), (.right, turned)] {
        guard phoneTargetCrop(frame: frame, screen: screen, scale: scale, orientation: orientation,
                              backing: backing) != nil else { return native() }
    }
    let image = capture()
    guard let pixels = image.cgImage else { return nil }
    guard let crop = phoneTargetCrop(frame: frame, screen: screen, scale: image.scale, orientation: image.imageOrientation,
                                    backing: CGSize(width: pixels.width, height: pixels.height)) else { return native() }
    guard let target = pixels.cropping(to: crop) else { return nil }
    let captured = UIImage(cgImage: target, scale: image.scale, orientation: image.imageOrientation)
    if captured.imageOrientation == .up { return captured.pngData() }
    let format = UIGraphicsImageRendererFormat()
    format.scale = captured.scale
    return UIGraphicsImageRenderer(size: captured.size, format: format).image { _ in
        captured.draw(in: CGRect(origin: .zero, size: captured.size))
    }.pngData()
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
