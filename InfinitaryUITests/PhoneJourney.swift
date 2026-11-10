import CoreImage
import XCTest

/// INF-64 piece 2's requested journey. Real TLS/core, disposable home and simulator; never a provider account.
/// Result: the same phone identity rejoins after launch, reads cards/feed, catches up and leaves/removes.
/// Prerequisites: iOS 18+ simulator, scripts/phone-test-home.ts; no camera, local network or signing material.
/// Each part (scripts/phone-test-plan.ts) has its own file, PhoneJourney+<Part>.swift, with its test and the steps only
/// it takes; this file holds the steps two or more parts share.
@MainActor final class PhoneJourney: XCTestCase {
    let app = XCUIApplication()
    var control: String { ProcessInfo.processInfo.environment["PHONE_TEST_HOME"]! }
    /// INF-1786: a display request waits for SpringBoard's own line, up to its 10-minute cap; a 60-second load budget
    /// ended it first. PHONE_DISPLAY_REQUEST_BUDGET_MS in tests/helpers/phoneKeyboard.ts mirrors it.
    let displayBudget: TimeInterval = 600

    func home(_ command: String, method: String = "POST", body: String? = nil, budget: TimeInterval = 60) async throws -> [String: Any] {
        var request = URLRequest(url: URL(string: control + "/" + command)!, timeoutInterval: budget)
        request.httpMethod = method
        request.httpBody = body.map { Data($0.utf8) }
        let (data, response) = try await phoneTestSession.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200, String(data: data, encoding: .utf8) ?? "")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func picture(_ name: String) {
        picture(name, screenshot: XCUIScreen.main.screenshot())
    }

    private func picture(_ name: String, screenshot: XCUIScreenshot) {
        // Capture the display, not an app-window crop computed before an iPad rotation.
        let image = XCTAttachment(screenshot: screenshot)
        image.name = name; image.lifetime = .keepAlways; add(image)
    }

    /// INF-1537: a successful simulator command or an idle app is not a drawn appearance.
    /// These fixtures have broad light/dark surfaces, including the sheets. Observe every quadrant,
    /// so a dark card alone cannot pass for a dark screen, and retain the exact frame we observed.
    /// This is a fixture check, not a theme detector for arbitrary pictures or other apps.
    private func appearancePicture(_ name: String, dark: Bool) throws -> XCUIScreenshot {
        let context = CIContext()
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        var observed: XCUIScreenshot?
        var last: XCUIScreenshot?
        var settled = false
        var brightness: [Double] = []
        let result = waitForPhonePredicate(NSPredicate { _, _ in
            let screenshot = XCUIScreen.main.screenshot()
            last = screenshot
            guard self.app.state == .runningForeground, let pixels = screenshot.image.cgImage else { return false }
            let image = CIImage(cgImage: pixels)
            let halfWidth = image.extent.width / 2, halfHeight = image.extent.height / 2
            brightness = []
            for y in [0.0, halfHeight] {
                for x in [0.0, halfWidth] {
                    let bounds = CGRect(x: x, y: y, width: halfWidth, height: halfHeight)
                    let average = image.applyingFilter("CIAreaAverage", parameters: [kCIInputExtentKey: CIVector(cgRect: bounds)])
                    var rgba = [UInt8](repeating: 0, count: 4)
                    context.render(average, toBitmap: &rgba, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                                   format: .RGBA8, colorSpace: colorSpace)
                    brightness.append(rgba.prefix(3).reduce(0.0) { $0 + Double($1) } / (3 * Double(UInt8.max)))
                }
            }
            // The midpoint separates these fixtures' near-white and near-black surfaces, not a pixel golden.
            guard brightness.allSatisfy({ dark ? $0 < 0.5 : $0 > 0.5 }) else { return false }
            // Only now is the requested appearance actually drawing. The screen inside the caller's still element has
            // settled (waitForRedraw), and XCTest no longer waits out animations, so observe again; the first dark frame
            // can lack chrome.
            if !settled {
                settled = true
                self.app.activate()
                return false
            }
            observed = screenshot
            return true
        }, object: nil, timeout: 10)
        print("Appearance picture \(name): expected \(dark ? "dark" : "light"), quadrant brightness \(brightness), result \(result)")
        if result != .completed, let last { picture(name + "-unconfirmed", screenshot: last) }
        return try XCTUnwrap(observed, "The app never drew \(dark ? "dark" : "light") for \(name); quadrant brightness \(brightness)")
    }

    /// INF-1541 piece 1: XCTest no longer waits out the display's change, so each picture waits until `shown`, a part
    /// of the screen that holds still, draws differently than it did before the change, and settles; INF-1537 then
    /// confirms the whole screen draws the requested appearance before the picture is kept. Its first match is read,
    /// since a line such as Activity's can repeat.
    func appearances(_ name: String, showing element: XCUIElement) async throws {
        let shown = element.firstMatch
        let light = waitForRedraw(shown, from: nil)
        picture(name, screenshot: try appearancePicture(name, dark: false))
        _ = try await home("display-dark", budget: displayBudget)
        app.activate()
        let dark = waitForRedraw(shown, from: light)
        picture(name + "-dark", screenshot: try appearancePicture(name + "-dark", dark: true))
        _ = try await home("display-light", budget: displayBudget)
        app.activate()
        _ = waitForRedraw(shown, from: dark)
        _ = try appearancePicture(name + "-restored", dark: false)
    }

    /// The whole screen draws `dark` or light without a change of the simulator's own appearance, as when the app's
    /// own Theme overrides it; the drawn frame is kept as `name`.
    func drawn(_ name: String, dark: Bool) throws {
        picture(name, screenshot: try appearancePicture(name, dark: dark))
    }

    func computerDetails() {
        let details = app.buttons["computer-details"]
        XCTAssertTrue(details.waitForPresence(timeout: 10))
        XCTAssertEqual(details.label, "Your computer")
        tapOnPhone(details)
        XCTAssertTrue(app.buttons["close-computer-details"].waitForPresence(timeout: 10))
    }

    func tab(_ name: String, repeatDiscarded: Bool = true) {
        // INF-1062: the tabs are words in the top bar's strip, the same on iPhone and an upright iPad; the pressed one lights.
        let tab = app.buttons["tab-" + name.lowercased()]
        XCTAssertTrue(tab.waitForPresence(timeout: 10), app.debugDescription); tapOnPhone(tab, repeatDiscarded: repeatDiscarded)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "selected == true"), object: tab, timeout: 10), .completed, "\(name) is the lit tab after its press")
    }

    /// INF-1062: in reach the bar says nothing; the computer button's value carries the reach for VoiceOver,
    /// and a line under the bar says it only while the computer is not in reach.
    /// INF-2668: the line says Out of reach once the computer has been quiet for the captain's 20 s, counted from the
    /// last thing it sent, which a ping every 10 s keeps at most that old; a gone computer is named within 31 s.
    func outOfReach(_ message: @autoclosure () -> String = "") {
        XCTAssertTrue(app.staticTexts["Out of reach"].waitForPresence(timeout: 35), message())
    }

    func reach(_ words: String, timeout: TimeInterval = 20) {
        let button = app.buttons["computer-details"]
        // Reading an absent button's value fails at once, so a join still under way is waited for first.
        XCTAssertTrue(button.waitForPresence(timeout: timeout), app.debugDescription)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value == %@", words), object: button, timeout: timeout), .completed, app.debugDescription)
        if words == "In reach" { XCTAssertFalse(app.otherElements["reach-line"].exists, "In reach, no line under the bar repeats it") }
    }

    /// Away past the app's background time (`INFINITARY_TEST_BACKGROUND_TIME`): the app closes its connection when it ends.
    func background() async throws {
        XCUIDevice.shared.press(.home)
        // The home waits up to a minute for the phone to go; its answer must not be cut first.
        _ = try await home("disconnected", budget: 90)
    }

    func submitLink(_ command: String = "link") async throws {
        let invitation = try await home(command)
        let link = try XCTUnwrap(invitation["link"] as? String)
        tapOnPhone(app.buttons["paste-link"])
        let field = app.textFields["join-link"]
        // A fresh iOS keyboard presents its own typing guide before accepting other taps; the focus owner waits it out.
        focusForPhoneTyping(field, in: app)
        field.typeText(link)
        // INF-1312: Paste and Continue share one row; pictured once, on the first link.
        if command == "wrong-link" { picture("paste-link") }
        tapOnPhone(app.buttons["read-link"])
        // iOS 26 exposes a dialog's native button and its SwiftUI label as nested buttons.
        let confirm = app.buttons["confirm-join"].firstMatch
        XCTAssertTrue(confirm.waitForPresence(timeout: 10))
        // INF-589 item 4: the cancel choice stays in view beside Join, where a popover would hide it.
        waitUntilHittable(app.alerts.buttons["Cancel"].firstMatch)
        tapOnPhone(confirm)
    }

    func join() async throws {
        try await submitLink()
        reach("In reach", timeout: 20)
    }

    // INF-662 piece 2 (the captain's "Both at once, journey in parts"): the journey's parts are tests, each run from
    // its own fresh home and a clean app (scripts/phone-test-plan.ts). INF-2125 direction C (the captain's "Shared fixes,
    // then short parts", so each pull request's phone check finishes quickly): the join, cards, talk and relaunch parts
    // are each split into shorter tests. Every check the single journey made stays, in the test it belongs to; each test
    // first reaches, from its own fresh home, the state its checks read.
    func launchFresh() async throws {
        continueAfterFailure = false
        PhoneFailures.watch()
        // INF-1541 piece 1: before the first action, so no wait in the part asks for the app's animation reply.
        try skipPhoneAnimationWait()
        app.launchEnvironment["INFINITARY_ISOLATED_PHONE_TEST"] = "1"
        // INF-1528: the simulator never ends the app's background time, so the app ends it after this long.
        app.launchEnvironment["INFINITARY_TEST_BACKGROUND_TIME"] = "15"
        XCUIDevice.shared.orientation = .portrait
        try await launchPhoneApp(app)
        XCTAssertTrue(app.buttons["paste-link"].waitForPresence(timeout: 10), app.debugDescription)
    }

    func launchJoined() async throws {
        try await launchFresh()
        try await join()
        XCTAssertTrue(cardHeading("Your phone is reading your Mac").waitForPresence(timeout: 10), app.debugDescription)
    }

    /// INF-2568's KeyboardViewportProbe, for the captain's report: "both the main chat input and a card's reply input don't
    /// always stay in viewport when ios keyboard is up. that makes typing very difficult". With the keyboard up on one
    /// field, it records each way that field is not wholly between the top bar's foot and the keyboard's drawn top: a
    /// card's scroller clipping it, the message box or the pager covering it, or the message box itself behind the
    /// keyboard. Every situation is checked before the test fails, so one run reports each one that leaves the room.
    /// Platform: the gate's pinned simulators (scripts/phone-pin.json), whose keyboard INF-2568 measured.
    func keyboardViewportProbe(_ situation: String, _ field: XCUIElement, into failures: inout [String]) {
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForPresence(timeout: 10), "\(situation): no keyboard")
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "hasKeyboardFocus == true"), object: field, timeout: 10),
                       .completed, "\(situation): the field lost the keyboard's focus")
        let any = { (id: String) in self.app.descendants(matching: .any).matching(identifier: id).firstMatch }
        let composer = any("phone-composer")
        // The keyboard and the layout animate in: read once the keyboard, the field and the message box each hold still.
        var steady = PhoneSteadyReading<[CGRect]>()
        let still = NSPredicate { _, _ in
            steady.read(keyboard.exists && field.exists ? [keyboard.frame, field.frame, composer.exists ? composer.frame : .null] : nil)
        }
        XCTAssertEqual(waitForPhonePredicate(still, object: nil, timeout: 10), .completed, "\(situation): the keyboard and the field never held still")
        // XCUITest's keyboard frame leaves out the suggestion row drawn above the keys. INF-2568's screenshots on the pinned
        // iOS 27.0 simulators put the drawn top 44 pt above that frame on the iPhone 16 and 55 pt above it on the iPad Pro
        // 11-inch (M4), upright and on its side.
        let suggestionRow: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 55 : 44
        let f = field.frame, keyTop = keyboard.frame.minY - suggestionRow
        let bar = app.navigationBars.firstMatch
        let barFoot = bar.exists ? bar.frame.maxY : app.windows.firstMatch.frame.minY
        var problems: [String] = []
        if f.maxY > keyTop + 0.5 { problems.append(String(format: "its foot is %.0f pt behind the keyboard", f.maxY - keyTop)) }
        if f.minY < barFoot - 0.5 { problems.append(String(format: "its top is %.0f pt above the bar's foot", barFoot - f.minY)) }
        if field.identifier == "card-reply" {
            // A reply inside the scroller of a card whose whole frame scrolls is clipped at the scroller's foot.
            let scroll = app.scrollViews["card-scroll"].firstMatch
            if scroll.exists, !any("card-frame").exists, !any("card-back").exists, f.maxY > scroll.frame.maxY + 0.5 {
                problems.append(String(format: "its foot is %.0f pt past the card's lower edge", f.maxY - scroll.frame.maxY))
            }
            for cover in [composer, any("card-pager")] where cover.exists && cover.frame.intersects(f) {
                problems.append("\(cover.identifier) covers it at \(cover.frame)")
            }
        }
        // INF-2568: only on an iPhone on its side, while a card's reply holds the keyboard, does the message box step
        // aside, undrawn and under its own name; anywhere else it stays in view.
        let window = app.windows.firstMatch.frame
        let phoneOnItsSide = UIDevice.current.userInterfaceIdiom == .phone && window.width > window.height
        if any("phone-composer-aside").exists, !(phoneOnItsSide && field.identifier == "card-reply") {
            problems.append("the message box stepped aside")
        }
        // The captain named both fields: whichever one holds the keyboard, the message box stays above it too.
        if composer.exists, composer.frame.maxY > keyTop + 0.5 {
            problems.append(String(format: "the message box is %.0f pt behind the keyboard", composer.frame.maxY - keyTop))
        }
        let frame = { (id: String) in any(id).exists ? "\(any(id).frame)" : "absent" }
        let line = "KEYBOARD VIEWPORT \(situation): field \(f) keyboard \(keyboard.frame) drawn-top \(keyTop) bar-foot \(barFoot)"
            + " card-frame \(frame("card-frame")) card-scroll \(frame("card-scroll")) card-back \(frame("card-back"))"
            + " pager \(frame("card-pager")) composer \(any("phone-composer-aside").exists ? "aside" : frame("phone-composer")) -> "
            + (problems.isEmpty ? "in view" : problems.joined(separator: "; "))
        print(line)
        picture("keyboard " + situation)
        if !problems.isEmpty { failures.append(line) }
    }

    /// Fails the test with every situation the keyboard checks recorded.
    func finishKeyboardChecks(_ failures: [String]) {
        if !failures.isEmpty { XCTFail("\(failures.count) keyboard situations failed:\n" + failures.joined(separator: "\n")) }
    }

    /// The field reads as a text field or, once it holds lines, a text view.
    func keyboardInput(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@ AND (elementType == %d OR elementType == %d)",
            id, XCUIElement.ElementType.textField.rawValue, XCUIElement.ElementType.textView.rawValue)).firstMatch
    }

    /// Turns the device and waits until the bar's computer button has moved with it and holds still.
    func turnForProbe(_ orientation: UIDeviceOrientation) {
        turnPhone(to: orientation, in: app, moving: app.buttons["computer-details"])
    }

    func dismissKeyboardForProbe() async throws {
        let done = app.navigationBars.buttons["dismiss-phone-keyboard"]
        XCTAssertTrue(done.waitForPresence(timeout: 10), app.debugDescription)
        tapOnPhone(done)
        XCTAssertTrue(app.keyboards.firstMatch.waitForAbsence(timeout: 10), app.debugDescription)
    }

    /// The whole merge card scrolls, so its reply may start below the stage's foot: swipe the card until it can be pressed.
    func revealForProbe(_ element: XCUIElement, in scroll: XCUIElement) {
        for _ in 0..<6 where !element.isHittable { scroll.swipeUp(); waitForSteadyTarget(scroll) }
        XCTAssertTrue(waitForPhonePress(element), "\(element) never came into view: \(app.debugDescription)")
    }

    /// Data shared by the talk, tasks and relaunch tests: the hero card on the stage after a relaunch, the on-request
    /// harbour task and a sent captain ask, so each launch restores a last turn. Answers the talk fixture.
    func launchWithLastTurn() async throws -> [String: Any] {
        try await launchJoined()
        _ = try await home("empty-cards")
        let hero = try await home("hero-card")
        XCTAssertTrue(cardHeading(try XCTUnwrap(hero["title"] as? String)).waitForPresence(timeout: 10), app.debugDescription)
        let fixture = try await home("talk-fixture")
        let input = app.textFields["message-box"]
        focusForPhoneTyping(input, in: app); input.typeText(try XCTUnwrap(fixture["text"] as? String))
        tapOnPhone(app.buttons["send-message"])
        let sent = try await home("talk-sent")
        XCTAssertEqual((sent["lastTurn"] as? [String: Any])?["you"] as? String, fixture["text"] as? String)
        XCTAssertTrue(app.staticTexts["last-turn-you"].waitForPresence(timeout: 10))
        return fixture
    }

    /// INF-2582 direction A (the captain's "wait once and trim the soak"): the gate names how many pairs each relaunch
    /// part runs in the test plan (scripts/test-phone.ts). A request on a branch runs 1, so 2 of the 20; the release check
    /// and a run with no count run all ten.
    var soakPairs: Int {
        let named = Int(ProcessInfo.processInfo.environment["INFINITARY_PHONE_RELAUNCH_PAIRS"] ?? "") ?? 10
        return min(max(named, 1), 10)
    }

    /// INF-1735: reach and the restored last turn can precede the requested appearance's drawn chrome.
    /// Use the same observed-appearance owner as appearances(), not a raw hero screenshot followed by a press.
    /// Each round is a fresh dark/light relaunch pair with exactly one Tasks press; a miss fails immediately.
    /// Tasks stays shown after the last round. `pictured` keeps the first round's hero pictures.
    func relaunchPairs(_ rounds: Int, pictured: Bool = false) async throws {
        for round in 1...rounds {
            print("INF-1735 relaunch pair \(round)")
            for (command, dark) in [("appearance-dark", true), ("appearance-light", false)] {
                _ = try await home(command, budget: displayBudget)
                app.terminate(); try await launchPhoneApp(app)
                reach("In reach", timeout: 20)
                XCTAssertTrue(app.staticTexts["last-turn-you"].waitForPresence(timeout: 10))
                let name = dark ? "talk-hero-dark" : "talk-hero-light"
                let screenshot = try appearancePicture(name, dark: dark)
                if pictured && round == 1 { picture(name, screenshot: screenshot) }
            }
            tab("Tasks", repeatDiscarded: false)
            XCTAssertTrue(app.buttons["group-backlog"].waitForPresence(timeout: 10), "Tasks shows its list after relaunch pair \(round)")
            if round < rounds { tab("Home", repeatDiscarded: false) }
        }
    }

    /// INF-64 piece 4: a phone answers at the real home, not a local stand-in; opaque scripts cannot gain native effects.
    /// The cards part owns its simulator/home, no shared account or signed build.
    func cardHeading(_ title: String) -> XCUIElement {
        // INF-64 piece 4: departure means leaving the stage, not erasing INF-82's foreground notice.
        app.staticTexts.matching(identifier: "card-title").matching(NSPredicate(format: "label == %@", title)).firstMatch
    }

    func showCard(_ title: String) {
        if app.staticTexts["card-title"].label == title { return }
        // INF-1651: a pick made while the shown card finishes drawing is lost with the menu still open, so the pager
        // opens once the shown body is revealed: until then it is one closed element with nothing inside.
        waitForShownBodyRevealed()
        // SwiftUI Menu is a popup on current iOS; use its own stable identity rather than a legacy button type.
        let pager = app.descendants(matching: .any).matching(identifier: "card-pager").firstMatch
        XCTAssertTrue(pager.waitForPresence(timeout: 10), app.debugDescription); tapOnPhone(pager)
        let item = app.buttons[title].firstMatch
        XCTAssertTrue(item.waitForPresence(timeout: 10), app.debugDescription); tapOnPhone(item)
        XCTAssertTrue(cardHeading(title).waitForPresence(timeout: 10))
    }

    /// INF-1651: the shown card's body, once present, opens as one closed element; it is revealed once something inside shows.
    func waitForShownBodyRevealed() {
        let body = app.webViews.matching(identifier: "card-body").firstMatch
        if body.exists {
            let revealed = NSPredicate { _, _ in body.descendants(matching: .any).firstMatch.exists }
            XCTAssertEqual(waitForPhonePredicate(revealed, object: nil, timeout: 10), .completed, "The shown card body was never revealed")
        }
    }

    func reveal(_ element: XCUIElement) {
        let scroll = app.scrollViews["card-scroll"]
        let body = app.webViews.matching(identifier: "card-body").firstMatch
        for _ in 0..<8 {
            // INF-1651: after the card moves, iOS 27.0 reports a body element's frame one layout behind, partly outside
            // the body, until the card scrolls. A control's own frame can overhang the body by a point.
            let stale = body.exists && body.frame.intersects(element.frame)
                && !body.frame.insetBy(dx: -2, dy: -2).contains(element.frame)
            // A body element reads hittable even where the card's scroller clips it, as under the pinned footer, whose reply
            // field a press there focused on iPhone. So a body element is first moved inside the scroller.
            let view = scroll.exists ? scroll.frame : .null
            if !view.isNull, element.exists, !stale, body.exists, body.frame.insetBy(dx: -2, dy: -2).contains(element.frame),
               element.frame.height < view.height,
               element.frame.minY < view.minY - 1 || element.frame.maxY > view.maxY + 1 {
                let dy = max(-view.height * 0.4, min(view.height * 0.4, view.midY - element.frame.midY))
                let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: dy)), withVelocity: .slow, thenHoldForDuration: 0.3)
                continue
            }
            if element.isHittable && !stale { return }
            // Use the card's actual viewport: a whole-screen swipe hits the keyboard while replying.
            if stale || (element.exists && element.frame.maxY < scroll.frame.minY) { scroll.swipeDown() }
            else { scroll.swipeUp() }
        }
        XCTAssertTrue(element.isHittable, app.debugDescription)
    }

    func waitUntilEnabled(_ element: XCUIElement) {
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "enabled == true"), object: element, timeout: 10), .completed, app.debugDescription)
    }

    /// INF-1541 piece 1: XCTest no longer waits out a dialog's entrance, so its button is read once it takes a touch.
    func waitUntilHittable(_ element: XCUIElement) {
        XCTAssertTrue(waitForPhonePress(element), app.debugDescription)
    }
    /// INF-1109's phone approvals (docs/secrets.md, "Remote decisions"), built by INF-1202. Result: this phone offers its
    /// own approval key from Settings, the computer's card shows the same code and only a click there enrolls it, one
    /// Allow here, confirmed by Face ID, runs exactly the use waiting on the computer, and Deny needs no key. Data: the
    /// real Secrets controller over disposable custody and an invented calendar token; the computer's own confirmation
    /// and the calendar are the test home's stand-ins. Completion: the computer's Secrets history reads each use's end.
    /// Prerequisites: the owned simulator's Face ID, which the test home enrolls. It runs alone or in the rest part,
    /// installs its own native wait and failure hooks, and joins only when the phone has not.
    /// INF-1109's decision on a damaged record ends it: Settings says so, and only Set up approvals again replaces
    /// the record, whose new key the computer enrolls only after its own confirmation, beside the earlier one.
    func testSecretsApprovals() async throws {
        continueAfterFailure = false
        // INF-1109 / INF-2092: this test must run alone, without launchFresh installing its prerequisites first.
        PhoneFailures.watch()
        try skipPhoneAnimationWait()
        app.launchEnvironment["INFINITARY_ISOLATED_PHONE_TEST"] = "1"
        XCUIDevice.shared.orientation = .portrait
        try await launchPhoneApp(app)
        let start = app.buttons.matching(NSPredicate(format: "identifier IN %@", ["paste-link", "computer-details"])).firstMatch
        XCTAssertTrue(start.waitForPresence(timeout: 10), app.debugDescription)
        if app.buttons["paste-link"].exists { try await join() } else { reach("In reach", timeout: 20) }
        _ = try await home("empty-cards")
        _ = try await home("biometry-enroll")
        let ready = try await home("secrets-ready")
        XCTAssertEqual(ready["availability"] as? String, "available")
        let confirmWords = try XCTUnwrap(ready["confirm"] as? String)

        // INF-1109: after the old sheet disappears, UIKit can still ignore a press on the Settings control.
        // The touch owner waits for the drawn target and records delivery, without repeating the press.
        func openSettings() {
            let settings = app.buttons["phone-settings"]
            tapOnPhone(settings, repeatDiscarded: false)
        }

        // INF-1109: an enrolled label can appear before Settings finishes entering, while UIKit still ignores
        // interaction. Every close waits for its own drawn target, sends one press and keeps the absence check.
        func closeSettings() {
            let close = app.buttons["close-phone-settings"]
            tapOnPhone(close, repeatDiscarded: false)
            XCTAssertTrue(close.waitForAbsence(timeout: 10))
        }

        // Settings offers this phone's key; the computer raises its card with the code this phone shows.
        openSettings()
        let setUp = app.buttons["approval-set-up"]
        XCTAssertTrue(setUp.waitForPresence(timeout: 20), app.debugDescription)
        XCTAssertEqual(setUp.label, "Set up approvals")
        // INF-1109: UIKit dropped the setup press while Settings was still sliding in, so it is pressed once Settings
        // holds still. The touch owner records delivery but is forbidden to repeat this press.
        waitForSteadyTarget(setUp)
        picture("secrets-settings")
        tapOnPhone(setUp, repeatDiscarded: false)
        let code = app.staticTexts["approval-code"]
        XCTAssertTrue(code.waitForPresence(timeout: 20), app.debugDescription)
        let shown = code.label.replacingOccurrences(of: "Code ", with: "")
        XCTAssertNotNil(shown.range(of: #"^\d{4} \d{4}$"#, options: .regularExpression), shown)
        picture("secrets-settings-code")
        closeSettings()

        // The enrollment is the computer's to confirm: on this phone its Confirm only says so, and nothing changes.
        let offered = try await home("secrets-state", method: "GET")
        let enrollment = try XCTUnwrap((offered["cards"] as? [[String: Any]])?.first?["title"] as? String)
        XCTAssertTrue(enrollment.contains(UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"), enrollment)
        showCard(enrollment)
        let confirmHere = app.buttons.matching(NSPredicate(format: "label == %@", confirmWords)).firstMatch
        XCTAssertTrue(confirmHere.waitForPresence(timeout: 10), app.debugDescription)
        // Like every card's choices (INF-1083), Confirm takes a press only once the body reports drawn; a press
        // before then is refused and the phone never says where to confirm.
        waitUntilEnabled(confirmHere)
        picture("secrets-enrollment-card")
        reveal(confirmHere); tapOnPhone(confirmHere, repeatDiscarded: false)
        XCTAssertTrue(app.staticTexts["Do this on Test Mac mini."].waitForPresence(timeout: 10))
        let unconfirmed = try await home("secrets-state", method: "GET")
        XCTAssertEqual((unconfirmed["devices"] as? [Any])?.count, 0)
        let confirmed = try await home("secrets-confirm")
        XCTAssertEqual(confirmed["title"] as? String, enrollment)
        XCTAssertEqual(confirmed["code"] as? String, shown, "The computer's card shows the code this phone shows")
        XCTAssertEqual(confirmed["confirmed"] as? Int, 1, "Enrolling asked for this computer's own confirmation once")
        let devices = try XCTUnwrap(confirmed["devices"] as? [[String: Any]])
        XCTAssertEqual(devices.count, 1); XCTAssertEqual(devices.first?["code"] as? String, shown)
        XCTAssertTrue(cardHeading(enrollment).waitForAbsence(timeout: 20), app.debugDescription)
        openSettings()
        XCTAssertTrue(app.staticTexts["approval-enrolled"].waitForPresence(timeout: 20), app.debugDescription)
        picture("secrets-settings-enrolled")
        closeSettings()

        // One use waits on the computer; this phone allows it once, with Face ID.
        let first = try await home("secrets-request")
        XCTAssertEqual(first["state"] as? String, "waiting")
        let title = try XCTUnwrap(first["title"] as? String)
        showCard(title)
        let allow = app.buttons["approval-allow"]
        XCTAssertTrue(allow.waitForPresence(timeout: 20), app.debugDescription)
        XCTAssertEqual(allow.label, "Allow once")
        XCTAssertTrue(app.staticTexts["approval-note"].label.hasPrefix("Each Allow here asks for Face ID"), app.staticTexts["approval-note"].label)
        // The computer's own approval body names the same secret, its prepared environment and saved version.
        func body(_ words: String) -> XCUIElement {
            app.webViews.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", words)).firstMatch
        }
        for words in ["Planning calendar", "Personal", "Saved version 1"] {
            XCTAssertTrue(body(words).waitForPresence(timeout: 20), app.debugDescription)
        }
        // INF-1109: the shared body says confirmation comes before sharing without naming a device, and that
        // temporary access is only the computer's; no Allow here offers it.
        XCTAssertTrue(body("after you confirm").exists, app.debugDescription)
        XCTAssertFalse(body("Your computer asks you to confirm").exists, app.debugDescription)
        let temporary = body("Temporary access is available only on your computer")
        XCTAssertTrue(temporary.exists, app.debugDescription)
        // INF-1109: the foot names the requested secret by name, environment, reference and version, beside
        // choices that stay in the card's frame rather than scrolling away with its body.
        let named = app.staticTexts["approval-secret-calendar"]
        XCTAssertTrue(named.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(named.label, "Planning calendar (Personal, calendar, version 1)")
        XCTAssertTrue(app.descendants(matching: .any)["card-frame"].exists, "The choices stay pinned: \(app.debugDescription)")
        // The choices take a press once the computer's body is revealed at its drawn height, as every card's do.
        waitUntilEnabled(allow)
        XCTAssertTrue(allow.isHittable, app.debugDescription)
        picture("secrets-use")
        // The scope lies below an iPhone's fold; the body scrolls to it while the pinned choices stay.
        let reading = app.scrollViews["card-scroll"]
        revealPhoneCardReading(temporary, in: reading, app: app)
        XCTAssertTrue(phoneCardReadingBounds(reading, app: app).contains(phoneAccessibilityBounds(temporary.frame)),
            "The scope reads whole \(temporary.frame) inside \(phoneCardReadingBounds(reading, app: app))")
        XCTAssertTrue(allow.isHittable, app.debugDescription)
        picture("secrets-use-scope")
        let waiting = try await home("secrets-state", method: "GET")
        let asked = try XCTUnwrap(waiting["confirmed"] as? Int)
        // perform() puts a failed approval in the card's error foot, not the body's informational notice.
        let confirmationError = app.staticTexts["card-error"]
        XCTAssertFalse(confirmationError.exists, app.debugDescription)
        var confirmationProblem: String?
        func confirmationRefused() -> Bool {
            if confirmationProblem != nil { return true }
            guard confirmationError.exists else { return false }
            confirmationProblem = confirmationError.label
            return true
        }
        func requireConfirmationNotRefused() async throws {
            guard confirmationRefused() else { return }
            picture("secrets-confirmation-refused")
            let refused = try await home("secrets-state", method: "GET")
            let pending = try XCTUnwrap((refused["uses"] as? [[String: Any]])?.first {
                $0["request"] as? String == first["request"] as? String
            })
            XCTAssertEqual(pending["state"] as? String, "waiting", "A failed confirmation leaves the same use waiting")
            XCTAssertEqual(refused["sent"] as? [Bool], [], "An unconfirmed Allow sends nothing")
            XCTAssertEqual(refused["confirmed"] as? Int, asked, "A failed phone confirmation does not ask on the computer")
            throw NSError(domain: "PhoneSecretsConfirmation", code: 1, userInfo: [NSLocalizedDescriptionKey:
                "The phone did not confirm the use: \(confirmationProblem ?? "No confirmation result")"])
        }
        reveal(allow); tapOnPhone(allow, repeatDiscarded: false)
        // INF-1109: the system can fail to start Face ID. That is a terminal refusal, not an optional permission
        // alert still to come. Observe the card's error too, keep the no-send proof, and never retry Allow.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let permitted = springboard.alerts.buttons["OK"]
        _ = waitForPhonePredicate(NSPredicate { _, _ in confirmationRefused() || permitted.exists }, object: nil, timeout: 10)
        try await requireConfirmationNotRefused()
        if permitted.exists { picture("secrets-face-id-permission"); tapOnPhone(permitted, repeatDiscarded: false) }
        picture("secrets-face-id")
        _ = try await home("face-in-view")
        let confirmationEnded = waitForPhonePredicate(NSPredicate { _, _ in
            confirmationRefused() || !self.cardHeading(title).exists
        }, object: nil, timeout: 30)
        // Stop the owned simulator's face before an assertion can end this test, including a late refusal.
        _ = try await home("face-away")
        try await requireConfirmationNotRefused()
        guard confirmationEnded == .completed else {
            throw NSError(domain: "PhoneSecretsConfirmation", code: 2, userInfo: [NSLocalizedDescriptionKey:
                "The phone did not finish its confirmation: \(app.debugDescription)"])
        }
        XCTAssertTrue(cardHeading(title).waitForAbsence(timeout: 30), app.debugDescription)
        picture("secrets-allowed")
        var state = try await home("secrets-state", method: "GET")
        let enrolled = try XCTUnwrap(devices.first?["device"] as? String)
        let allowed = try XCTUnwrap((state["history"] as? [[String: Any]])?.first { $0["request"] as? String == first["request"] as? String })
        XCTAssertEqual(allowed["state"] as? String, "completed")
        XCTAssertEqual(allowed["approval"] as? String, "remote")
        XCTAssertEqual(allowed["device"] as? String, enrolled)
        XCTAssertEqual(state["sent"] as? [Bool], [true], "The calendar received the entry once")
        XCTAssertEqual(state["confirmed"] as? Int, asked, "An Allow from this phone asks for no confirmation on the computer")

        // Deny needs no Face ID and runs nothing.
        let second = try await home("secrets-request")
        showCard(title)
        let deny = app.buttons["approval-deny"]
        XCTAssertTrue(deny.waitForPresence(timeout: 20), app.debugDescription)
        // A press while the body still lays out could land beside a moving choice; it waits for the reveal gate.
        waitUntilEnabled(deny)
        reveal(deny); tapOnPhone(deny, repeatDiscarded: false)
        XCTAssertTrue(cardHeading(title).waitForAbsence(timeout: 20), app.debugDescription)
        state = try await home("secrets-state", method: "GET")
        let denied = try XCTUnwrap((state["history"] as? [[String: Any]])?.first { $0["request"] as? String == second["request"] as? String })
        XCTAssertEqual(denied["state"] as? String, "denied")
        XCTAssertEqual(state["sent"] as? [Bool], [true], "A refusal sends nothing")
        XCTAssertEqual((state["cards"] as? [Any])?.count, 0)

        // The phone's record is damaged by the next launch: Settings says so, and Set up approvals offers nothing.
        app.launchEnvironment["INFINITARY_DAMAGED_APPROVAL"] = "1"
        try await launchPhoneApp(app)
        app.launchEnvironment.removeValue(forKey: "INFINITARY_DAMAGED_APPROVAL")
        reach("In reach", timeout: 20)
        openSettings()
        let again = app.buttons["approval-set-up"]
        XCTAssertTrue(again.waitForPresence(timeout: 20), app.debugDescription)
        // The same setup control must finish entering in its damaged-record state too; presence is not readiness.
        waitForSteadyTarget(again)
        picture("secrets-settings-damaged")
        XCTAssertEqual(again.label, "Set up approvals again")
        XCTAssertTrue(again.isHittable, "The choice shows at the sheet's medium height, with no scrolling")
        XCTAssertTrue(app.staticTexts["approval-damaged"].exists, app.debugDescription)
        XCTAssertFalse(app.staticTexts["approval-problem"].exists, "A damaged record does not ask to unlock the phone")
        tapOnPhone(again, repeatDiscarded: false)
        let replaced = app.staticTexts["approval-code"]
        XCTAssertTrue(replaced.waitForPresence(timeout: 20), app.debugDescription)
        let newCode = replaced.label.replacingOccurrences(of: "Code ", with: "")
        XCTAssertNotEqual(newCode, shown, "Set up approvals again offers a new key")
        picture("secrets-settings-damaged-code")
        closeSettings()

        // Only the computer's own confirmation enrolls the new key, and the earlier enrollment stays there.
        let reoffered = try await home("secrets-state", method: "GET")
        XCTAssertEqual((reoffered["devices"] as? [[String: Any]])?.map { $0["device"] as? String }, [enrolled])
        let reconfirmed = try await home("secrets-confirm")
        XCTAssertEqual(reconfirmed["code"] as? String, newCode, "The computer's card shows the new code this phone shows")
        XCTAssertEqual(reconfirmed["confirmed"] as? Int, 1)
        let both = try XCTUnwrap(reconfirmed["devices"] as? [[String: Any]])
        XCTAssertEqual(Set(both.compactMap { $0["code"] as? String }), [shown, newCode])
        XCTAssertFalse(both.contains { $0["code"] as? String == newCode && $0["device"] as? String == enrolled },
                       "The new key is enrolled under a new device name")
        openSettings()
        XCTAssertTrue(app.staticTexts["approval-enrolled"].waitForPresence(timeout: 20), app.debugDescription)
        picture("secrets-settings-damaged-enrolled")
        closeSettings()
    }


}
