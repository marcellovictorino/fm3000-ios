import CoreImage
import XCTest

/// INF-64 piece 2's requested journey. Real TLS/core, disposable home and simulator; never a provider account.
/// Result: the same phone identity rejoins after launch, reads cards/feed, catches up and leaves/removes.
/// Prerequisites: iOS 18+ simulator, scripts/phone-test-home.ts; no camera, local network or signing material.
@MainActor final class PhoneJourney: XCTestCase {
    private let app = XCUIApplication()
    private var control: String { ProcessInfo.processInfo.environment["PHONE_TEST_HOME"]! }
    /// INF-1786: a display request waits for SpringBoard's own line, up to its 10-minute cap; a 60-second load budget
    /// ended it first. PHONE_DISPLAY_REQUEST_BUDGET_MS in tests/helpers/phoneKeyboard.ts mirrors it.
    private let displayBudget: TimeInterval = 600

    private func home(_ command: String, method: String = "POST", body: String? = nil, budget: TimeInterval = 60) async throws -> [String: Any] {
        var request = URLRequest(url: URL(string: control + "/" + command)!, timeoutInterval: budget)
        request.httpMethod = method
        request.httpBody = body.map { Data($0.utf8) }
        let (data, response) = try await phoneTestSession.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200, String(data: data, encoding: .utf8) ?? "")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func picture(_ name: String) {
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
    private func appearances(_ name: String, showing element: XCUIElement) async throws {
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

    private func computerDetails() {
        let details = app.buttons["computer-details"]
        XCTAssertTrue(details.waitForPresence(timeout: 10))
        XCTAssertEqual(details.label, "Your computer")
        tapOnPhone(details)
        XCTAssertTrue(app.buttons["close-computer-details"].waitForPresence(timeout: 10))
    }

    private func tab(_ name: String, repeatDiscarded: Bool = true) {
        // INF-1062: the tabs are words in the top bar's strip, the same on iPhone and an upright iPad; the pressed one lights.
        let tab = app.buttons["tab-" + name.lowercased()]
        XCTAssertTrue(tab.waitForPresence(timeout: 10), app.debugDescription); tapOnPhone(tab, repeatDiscarded: repeatDiscarded)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "selected == true"), object: tab, timeout: 10), .completed, "\(name) is the lit tab after its press")
    }

    /// INF-1062: in reach the bar says nothing; the computer button's value carries the reach for VoiceOver,
    /// and a line under the bar says it only while the computer is not in reach.
    private func reach(_ words: String, timeout: TimeInterval = 20) {
        let button = app.buttons["computer-details"]
        // Reading an absent button's value fails at once, so a join still under way is waited for first.
        XCTAssertTrue(button.waitForPresence(timeout: timeout), app.debugDescription)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value == %@", words), object: button, timeout: timeout), .completed, app.debugDescription)
        if words == "In reach" { XCTAssertFalse(app.otherElements["reach-line"].exists, "In reach, no line under the bar repeats it") }
    }

    /// Away past the app's background time (`INFINITARY_TEST_BACKGROUND_TIME`): the app closes its connection when it ends.
    private func background() async throws {
        XCUIDevice.shared.press(.home)
        // The home waits up to a minute for the phone to go; its answer must not be cut first.
        _ = try await home("disconnected", budget: 90)
    }

    private func submitLink(_ command: String = "link") async throws {
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

    private func join() async throws {
        try await submitLink()
        reach("In reach", timeout: 20)
    }

    // INF-662 piece 2 (the captain's "Both at once, journey in parts"): the journey's four parts are
    // four tests, each run from its own fresh home and simulator (scripts/phone-test-plan.ts), side by side.
    // Every check the single journey made stays, in the part it belongs to; each part first reaches the
    // state the single journey reached before that part.
    private func launchFresh() async throws {
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

    private func launchJoined() async throws {
        try await launchFresh()
        try await join()
        XCTAssertTrue(cardHeading("Your phone is reading your Mac").waitForPresence(timeout: 10), app.debugDescription)
    }

    /// Part 1, join and recover: a wrong Mac, joining, reading, relaunch, out of reach, catch-up, Leave, Forget and Removed.
    func testJoinAndRecover() async throws {
        try await launchFresh()
        try await appearances("join", showing: app.staticTexts["Welcome aboard Infinitary"])
        try await submitLink("wrong-link")
        XCTAssertTrue(app.staticTexts["This is not the computer your link names. Nothing was sent."].waitForPresence(timeout: 15))
        let refused = try await home("state", method: "GET")
        XCTAssertEqual((refused["devices"] as? [Any])?.count, 0)
        picture("wrong-mac")
        try await join()
        // INF-63 accepted B survives the move from the read-only list to native card chrome.
        // Finish the finding before the feed snapshot used by the foundation's Activity checks.
        _ = try await home("review-finding")
        showCard("Review the phone connection finding")
        XCTAssertTrue(app.staticTexts["Review finding"].waitForPresence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Check the phone connection"].exists)
        XCTAssertTrue(app.webViews.staticTexts["The review needs your choice on the Mac."].waitForPresence(timeout: 10))
        // INF-64 piece 4's approved native choices replace the foundation's read-only absence check.
        let keepFinding = app.buttons["card-action-keep"]
        XCTAssertTrue(keepFinding.waitForPresence(timeout: 10))
        // INF-1083: body text exists before its drawn acknowledgement enables the native footer.
        waitUntilEnabled(keepFinding)
        XCTAssertTrue(keepFinding.isEnabled)
        picture("review-finding")
        tapOnPhone(app.buttons["close-card"])
        XCTAssertTrue(cardHeading("Your phone is reading your Mac").waitForPresence(timeout: 10))
        let first = try await home("state", method: "GET")
        let devices = try XCTUnwrap(first["devices"] as? [[String: Any]])
        let phone = try XCTUnwrap(devices.first)
        XCTAssertEqual(phone["kind"] as? String, "view")
        XCTAssertEqual(phone["system"] as? String, "ios")
        XCTAssertTrue(app.staticTexts["Your phone is reading your Mac"].exists)
        XCTAssertFalse(app.buttons["Merge"].exists)
        XCTAssertTrue(app.webViews.staticTexts["This card belongs to the disposable test home."].firstMatch.waitForPresence(timeout: 10))
        verifyPhoneComposerBounds(app: app)
        picture("cards")
        try await appearances("cards", showing: app.staticTexts["Your phone is reading your Mac"])
        // INF-1062: the computer's name leaves the bar for its sheet, and Leave stays behind that sheet (INF-209).
        XCTAssertFalse(app.staticTexts["home-name"].exists, "The bar no longer carries the computer's name")
        XCTAssertFalse(app.buttons["leave"].exists)
        // INF-355: details must also work as the first hardware chord after relaunch.
        app.terminate(); try await launchPhoneApp(app)
        reach("In reach", timeout: 20)
        try await pressPhoneKey("i", modifiers: .command, in: app)
        XCTAssertTrue(app.buttons["close-computer-details"].waitForPresence(timeout: 10))
        XCTAssertEqual(app.staticTexts["home-name"].label, "Test Mac mini")
        XCTAssertTrue(app.staticTexts["In reach"].exists, "The computer's sheet says its reach")
        XCTAssertTrue(app.staticTexts["reached-address"].label.hasPrefix("127.0.0.1:"), "The sheet names the route reached, not the saved preference")
        XCTAssertTrue(app.buttons["leave"].exists)
        try await appearances("computer-details", showing: app.staticTexts["home-name"])
        tapOnPhone(app.buttons["close-computer-details"])
        // INF-1062, the captain's pick: Settings at the bar's left is this phone's own sheet, with no Leave in it.
        try await pressPhoneKey(",", modifiers: .command, in: app)
        XCTAssertTrue(app.buttons["close-phone-settings"].waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(app.staticTexts["app-version"].label.hasPrefix("Version "), app.staticTexts["app-version"].label)
        XCTAssertFalse(app.buttons["leave"].exists)
        try await appearances("phone-settings", showing: app.staticTexts["app-version"])
        tapOnPhone(app.buttons["close-phone-settings"])
        XCTAssertTrue(app.buttons["close-phone-settings"].waitForAbsence(timeout: 10))
        let settings = app.buttons["phone-settings"]
        XCTAssertTrue(waitForPhonePress(settings)); XCTAssertEqual(settings.label, "Settings")
        let strip = [app.buttons["tab-home"], app.buttons["tab-tasks"], app.buttons["tab-activity"]]
        XCTAssertLessThan(settings.frame.maxX, strip[0].frame.minX, "Settings sits left of the strip")
        // INF-1328: the segmented control draws its tabs edge to edge, in order and never overlapping.
        XCTAssertLessThanOrEqual(strip[0].frame.maxX, strip[1].frame.minX); XCTAssertLessThanOrEqual(strip[1].frame.maxX, strip[2].frame.minX)
        XCTAssertLessThan(strip[2].frame.maxX, app.buttons["computer-details"].frame.minX, "The computer sits right of the strip")
        XCTAssertTrue(strip[0].isSelected, "Home is the lit tab")
        let stripFrames = strip.map { $0.frame.integral }
        // INF-1541 piece 1: the card's heading redraws at the largest type before the strip is read against it.
        let heading = app.staticTexts["Your phone is reading your Mac"]
        let standard = waitForRedraw(heading, from: nil)
        _ = try await home("display-large", budget: displayBudget)
        let largest = waitForRedraw(heading, from: standard)
        XCTAssertTrue(waitForPhonePress(app.buttons["computer-details"]))
        // INF-1062: the strip keeps the bar's own size at the largest standard type, so no word truncates and the
        // bar's buttons stay where they were; growing words once truncated Activity and lost a tap on the computer.
        XCTAssertEqual(strip.map { $0.frame.integral }, stripFrames, "The strip's words keep the bar's own size at the largest type")
        picture("cards-largest-standard-type")
        computerDetails()
        XCTAssertTrue(waitForPhonePress(app.buttons["leave"]))
        picture("computer-details-largest-standard-type")
        tapOnPhone(app.buttons["close-computer-details"])
        _ = try await home("display-light", budget: displayBudget)
        _ = waitForRedraw(heading, from: largest)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // INF-1541 piece 1: turned, the card's heading moves onto the stage beside the sidebar, and back upright.
            turnPhone(to: .landscapeLeft, in: app, moving: heading)
            let sidebar = phoneSidebar(app)
            XCTAssertTrue(sidebar.waitForPresence(timeout: 10), app.debugDescription)
            XCTAssertTrue(app.staticTexts["Your phone is reading your Mac"].exists)
            XCTAssertLessThanOrEqual(sidebar.frame.maxX, app.scrollViews["card-scroll"].frame.minX)
            try await appearances("ipad-landscape", showing: app.staticTexts["Your phone is reading your Mac"])
            // INF-589 item 16: Tasks and Activity are a segmented pair at the sidebar's top, each scrolling alone.
            // INF-944 item 6: in the tabs' order, Tasks then Activity, opening on Tasks.
            let tasksRail = phoneSidebarRail("Tasks", in: sidebar), activityRail = phoneSidebarRail("Activity", in: sidebar)
            XCTAssertLessThan(tasksRail.frame.midX, activityRail.frame.midX, "Tasks comes before Activity")
            XCTAssertTrue(tasksRail.isSelected)
            let waiting = sidebar.buttons["group-waiting"]
            XCTAssertTrue(waiting.waitForPresence(timeout: 10), "The sidebar opens on Tasks")
            XCTAssertTrue(waitForPhonePress(waiting))
            XCTAssertLessThanOrEqual(tasksRail.frame.maxY, waiting.frame.minY, "The pair sits at the sidebar's top")
            picture("ipad-landscape-tasks")
            tapOnPhone(activityRail)
            let activity = sidebar.staticTexts.matching(identifier: "activity-text").firstMatch
            XCTAssertTrue(activity.waitForPresence(timeout: 10), "Activity opens at once")
            XCTAssertFalse(waiting.exists)
            XCTAssertLessThanOrEqual(activityRail.frame.maxY, activity.frame.minY)
            tapOnPhone(tasksRail)
            XCTAssertTrue(waiting.waitForPresence(timeout: 10))
            XCTAssertFalse(activity.exists)
            turnPhone(to: .portrait, in: app, moving: heading)
            XCTAssertTrue(sidebar.waitForAbsence(timeout: 10))
        }
        // INF-136 #2: no product traffic for longer than both former pairing deadlines.
        let idle = try await home("idle")
        let idleBefore = try XCTUnwrap(idle["before"] as? [String: Int])
        let idleAfter = try XCTUnwrap(idle["after"] as? [String: Int])
        XCTAssertEqual(idleAfter["connections"], idleBefore["connections"], "An idle phone must keep its existing connection")
        // INF-136 #1/#12: a card revision witnesses processing all preceding stream pushes.
        let stream = try await home("stream")
        XCTAssertTrue(app.staticTexts["Streaming finished"].waitForPresence(timeout: 10))
        let streamed = try await home("state", method: "GET")
        let beforeStream = try XCTUnwrap(stream["before"] as? [String: Int])
        let afterStream = try XCTUnwrap(streamed["readings"] as? [String: Int])
        XCTAssertEqual(afterStream["feed"], beforeStream["feed"], "Streaming does not change Activity")
        XCTAssertEqual(afterStream["cards"], beforeStream["cards"], "The push already carries the card snapshot")
        _ = try await home("stream-reset")
        XCTAssertTrue(app.staticTexts["Your phone is reading your Mac"].waitForPresence(timeout: 10))
        // INF-136 #9: Control Center makes the scene inactive, not backgrounded.
        let beforeInactive = try await home("state", method: "GET")
        // INF-1646: a starved SpringBoard can stall on the pull's first touch, and the system keeps only its first ~180 ms of touches.
        // A default-speed pull lasts over a second, so its lift is dropped and Control Center never finishes opening; this pull lifts
        // within a tenth of a second and waits whole in that queue, so Control Center opens once SpringBoard resumes.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.01)).press(forDuration: 0.05,
            thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.65)),
            withVelocity: XCUIGestureVelocity(rawValue: 20_000), thenHoldForDuration: 0)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // A fresh simulator has no connectivity controls; the container itself witnesses the overlay.
        let controlCenter = springboard.otherElements["cc-root-folder-view"]
        XCTAssertTrue(controlCenter.waitForPresence(timeout: 10), springboard.debugDescription)
        // Dismiss the empty simulator's overlay without invoking iPad's Home/window gesture.
        tapOnPhone(springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.9)))
        XCTAssertTrue(controlCenter.waitForAbsence(timeout: 10))
        app.activate()
        reach("In reach", timeout: 10)
        let afterInactive = try await home("state", method: "GET")
        XCTAssertEqual((afterInactive["readings"] as? [String: Int])?["connections"],
            (beforeInactive["readings"] as? [String: Int])?["connections"], "An inactive scene keeps its connection")
        tab("Activity")
        let feed = try XCTUnwrap(first["feed"] as? [[String: Any]])
        let line = try XCTUnwrap(feed.first?["text"] as? String)
        XCTAssertTrue(app.staticTexts[line].waitForPresence(timeout: 10))
        // INF-1845, the captain: "At the bottom on both, as on the Mac" - the newest line is the last row.
        XCTAssertEqual(app.staticTexts.matching(identifier: "activity-text").allElementsBoundByIndex.last?.label, feed.last?["text"] as? String)
        try await appearances("activity", showing: app.staticTexts[line])
        tab("Home")
        _ = try await home("empty-cards")
        // INF-1060: as on the Mac, the empty stage is the character alone, with no line under it.
        XCTAssertTrue(app.otherElements["phone-character"].waitForPresence(timeout: 10))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == 'No cards to read yet.'")).count, 0)
        // INF-589 item 11: with no card to page, the chevrons and count hide; the pager hides entirely when nothing is minimized.
        for id in ["previous-card", "next-card"] {
            XCTAssertFalse(app.buttons[id].exists, "\(id) shows on an empty stage")
        }
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "card-pager").firstMatch.exists, "The pager shows on an empty stage")
        _ = try await home("capture-character-start")
        try await appearances("empty-stage", showing: app.buttons["phone-settings"])
        _ = try await home("capture-stop")
        _ = try await home("stream-reset")
        XCTAssertTrue(app.staticTexts["Your phone is reading your Mac"].waitForPresence(timeout: 10))

        app.terminate(); try await launchPhoneApp(app)
        reach("In reach", timeout: 20)
        let afterLaunch = try await home("state", method: "GET")
        XCTAssertEqual((afterLaunch["devices"] as? [[String: Any]])?.first?["id"] as? String, phone["id"] as? String)

        _ = try await home("offline")
        XCTAssertTrue(app.staticTexts["Out of reach"].waitForPresence(timeout: 20))
        XCTAssertTrue(app.staticTexts["Your phone is reading your Mac"].exists)
        // INF-589 item 11: out of reach is said once; under the composer, one line says only that changes are off.
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'out of reach' AND NOT (label ==[c] 'Out of reach')")).count, 0,
            app.debugDescription)
        XCTAssertEqual(app.staticTexts["connection-refusal"].label, "Changes are off until Test Mac mini is back.")
        try await appearances("out-of-reach", showing: app.staticTexts["connection-refusal"])
        computerDetails()
        XCTAssertTrue(app.buttons["forget-mac"].exists)
        picture("computer-details-out-of-reach")
        tapOnPhone(app.buttons["close-computer-details"])
        // Record the recovery itself, not the separate appearance and details checks above.
        _ = try await home("capture-start")
        let change = try await home("change")
        _ = try await home("online")
        reach("In reach", timeout: 20)
        let title = try XCTUnwrap(change["title"] as? String)
        showCard(title)
        XCTAssertTrue(cardHeading(title).waitForPresence(timeout: 10))
        picture("caught-up")
        _ = try await home("capture-stop")
        tab("Activity")
        let caughtUp = try await home("state", method: "GET")
        let caughtUpFeed = try XCTUnwrap(caughtUp["feed"] as? [[String: Any]])
        let newest = try XCTUnwrap(caughtUpFeed.last?["text"] as? String)
        XCTAssertTrue(app.staticTexts[newest].waitForPresence(timeout: 10))
        XCTAssertEqual(app.staticTexts.matching(identifier: "activity-text").allElementsBoundByIndex.last?.label, newest)
        let taskKey = try XCTUnwrap(caughtUpFeed.last?["taskKey"] as? String)
        let keyLabel = NSPredicate(format: "label == %@", taskKey)
        XCTAssertTrue(app.descendants(matching: .any).matching(keyLabel).firstMatch.exists,
            "Activity shows the actual computer-authored task key")
        picture("activity-caught-up")
        // INF-1845, the captain's plan B: tapping a line shows its summary, with the whole words.
        tapOnPhone(app.staticTexts[newest])
        let summaryText = app.staticTexts["activity-summary-text"]
        XCTAssertTrue(summaryText.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(summaryText.label, newest)
        picture("activity-summary")
        tapOnPhone(app.buttons["close-activity-summary"])
        XCTAssertTrue(summaryText.waitForAbsence(timeout: 10))
        // Tapping a line's key opens that task's record.
        let key = try XCTUnwrap(app.buttons.matching(identifier: "activity-key").allElementsBoundByIndex.last)
        XCTAssertEqual(key.label, taskKey)
        tapOnPhone(key)
        XCTAssertTrue(app.staticTexts["task-record-title"].waitForPresence(timeout: 10), app.debugDescription)
        tapOnPhone(app.buttons["close-record"])
        tab("Activity")
        // INF-1062, the captain: Activity runs to the foot with nothing over it, so after scrolling to its end
        // the last row is whole in the window and pressable; the message box belongs to Home.
        XCTAssertFalse(app.textFields["message-box"].exists, "Activity has no message box over it")
        XCTAssertFalse(app.otherElements["phone-composer"].exists)
        let long = try await home("long-activity")
        let newestLine = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", try XCTUnwrap(long["newest"] as? String))).firstMatch
        XCTAssertTrue(newestLine.waitForPresence(timeout: 10), app.debugDescription)
        let oldest = app.staticTexts.matching(NSPredicate(format: "label == %@", try XCTUnwrap(caughtUpFeed.first?["text"] as? String))).firstMatch
        // INF-1845, the captain: "make sure activity tab auto-scrolls to the bottom like how a chat app normally would";
        // the newest line, the last row, is whole in the window and pressable with no swipe.
        waitForSteadyTarget(newestLine)
        XCTAssertTrue(waitForPhonePress(newestLine), "The newest line, the last row, shows without a swipe: \(app.debugDescription)")
        XCTAssertLessThanOrEqual(newestLine.frame.maxY, app.frame.maxY, "The last row is whole in the window")
        picture("activity-end")
        let list = app.scrollViews["activity-list"]
        for _ in 0..<12 where !(oldest.exists && oldest.isHittable) { list.swipeDown() }
        // INF-1541 piece 1: XCTest no longer waits out the last swipe's glide, so the row is read once it holds still.
        waitForSteadyTarget(oldest)
        XCTAssertTrue(waitForPhonePress(oldest), "The oldest line, the first row, can be reached and pressed: \(app.debugDescription)")
        tab("Home")

        // INF-1528, the captain: "the moment i minimize the ios app, it seems it immediately disconnects.
        // reopening the app even only after a short while needs to wait for reconnection."
        // A short trip away keeps the same connection: the app comes back in reach, with what changed meanwhile.
        let stateBeforeTrip = try await home("state", method: "GET")
        let beforeTrip = try XCTUnwrap(stateBeforeTrip["readings"] as? [String: Int])
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
        XCTAssertTrue(app.staticTexts["Out of reach"].waitForPresence(timeout: 20))
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
        // INF-1168: the phone tries the home, then the stalled address, each round. A starved simulator can also
        // outlast the phone's own handshake deadline at the home, which sends no request and adds a round, so the
        // address order, not the clock, fixes the count: one stall after every attempt at the home but the last.
        XCTAssertEqual(try since("stalledConnections"), try since("homeAttempts") - 1,
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

    /// Part 2, cards: forms, paging, answers, pictures, recordings, threads, out-of-reach refusal and large type.
    /// The address part, join by its address (INF-1183, the captain's plan "join a home from the iOS app by SSH
    /// address"): the Mac's own sshd beside the test home signs the phone in, asks its fingerprint once,
    /// refuses its key and a wrong password in plain words, lets in the key the phone shows, and the
    /// phone joins with the link the home's door answers, never shown.
    /// INF-1312 (the captain's answers on its plan): the sheet lists the computers on this network with Remote Login on,
    /// under a Your account field so a tap fills the whole address, and sweeps the other addresses only after a yes.
    /// The isolated phone never looks on a real network: the home's own sshd stands in for one announced computer,
    /// and the sweep tries only that sshd under the name localhost, which reads its real sign-in banner.
    func testJoinByAddress() async throws {
        let ssh = try await home("ssh-start")
        let address = try XCTUnwrap(ssh["address"] as? String)
        let port = try XCTUnwrap(ssh["port"] as? Int)
        let parts = address.split(separator: "@").map(String.init)
        let (account, host) = (parts[0], parts[1])
        app.launchEnvironment["INFINITARY_TEST_NEARBY_SSH"] = "Test computer|\(host)|\(port)"
        app.launchEnvironment["INFINITARY_TEST_SWEEP"] = "localhost:\(port)"
        try await launchFresh()
        // The port first, then the address, whose Return continues as Continue does.
        func typeAddress() {
            tapOnPhone(app.buttons["join-by-address"])
            let field = app.textFields["ssh-address"]
            XCTAssertTrue(field.waitForPresence(timeout: 10), app.debugDescription)
            // INF-1377 / INF-1265: the iPad number-pad popover intercepts the next field's tap.
            let portField = app.textFields["ssh-port"]
            focusForPhoneTyping(portField, in: app)
            portField.typeText(String(port))
            if UIDevice.current.userInterfaceIdiom == .pad {
                tapOnPhone(app.navigationBars["Join by its address"])
                // UIKit retains a zero-height, offscreen Keyboard after hiding the popover.
                XCTAssertEqual(waitForPhonePredicate(NSPredicate { _, _ in
                    self.app.keyboards.allElementsBoundByIndex.allSatisfy { $0.frame.intersection(self.app.frame).isEmpty }
                }, object: app, timeout: 10), .completed, app.debugDescription)
            }
            focusForPhoneTyping(field, in: app)
            field.typeText(address + "\n")
        }
        XCTAssertTrue(app.buttons["join-by-address"].waitForPresence(timeout: 10))
        picture("join-with-address")
        tapOnPhone(app.buttons["join-by-address"])
        let announced = app.buttons["nearby-ssh-\(host):\(port)"]
        XCTAssertTrue(announced.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(announced.label.hasPrefix("Test computer"), announced.label)
        XCTAssertFalse(announced.isEnabled, "A tap waits for the account it fills in")
        picture("address-nearby")
        // The sweep asks first; only the yes tries the addresses.
        tapOnPhone(app.buttons["ssh-sweep"])
        let look = app.buttons["ssh-sweep-confirm"].firstMatch
        XCTAssertTrue(look.waitForPresence(timeout: 10), app.debugDescription)
        waitUntilHittable(app.alerts.buttons["Cancel"].firstMatch)
        tapOnPhone(look)
        let swept = app.buttons["nearby-ssh-localhost:\(port)"]
        XCTAssertTrue(swept.waitForPresence(timeout: 20), app.debugDescription)
        XCTAssertTrue(swept.label.hasPrefix("localhost"), swept.label)
        picture("address-swept")
        let accountField = app.textFields["ssh-account"]
        focusForPhoneTyping(accountField, in: app)
        accountField.typeText(account)
        waitUntilEnabled(announced)
        tapOnPhone(announced)
        XCTAssertEqual(app.textFields["ssh-address"].value as? String, address)
        XCTAssertEqual(app.textFields["ssh-port"].value as? String, String(port))
        picture("address-filled")
        tapOnPhone(app.buttons["ssh-continue"])
        // The first sign-in asks about the computer's key, and Not this one sends nothing.
        let fingerprint = app.staticTexts["ssh-fingerprint"]
        XCTAssertTrue(fingerprint.waitForPresence(timeout: 30), app.debugDescription)
        XCTAssertTrue(fingerprint.label.hasPrefix("SHA256:"), fingerprint.label)
        try await appearances("address-fingerprint", showing: fingerprint)
        tapOnPhone(app.buttons["ssh-not-this-one"])
        XCTAssertTrue(app.buttons["join-by-address"].waitForPresence(timeout: 10))
        let declined = try await home("state", method: "GET")
        XCTAssertEqual((declined["devices"] as? [Any])?.count, 0)
        // Asked again, since no yes was kept; then trusted.
        typeAddress()
        XCTAssertTrue(fingerprint.waitForPresence(timeout: 30), app.debugDescription)
        tapOnPhone(app.buttons["ssh-trust"])
        // The computer does not know this phone's key and takes a password.
        let password = app.secureTextFields["ssh-password"]
        XCTAssertTrue(password.waitForPresence(timeout: 30), app.debugDescription)
        let key = app.staticTexts["ssh-public-key"]
        XCTAssertTrue(key.exists)
        try await appearances("address-password", showing: key)
        focusForPhoneTyping(password, in: app)
        password.typeText("not the password")
        tapOnPhone(app.buttons["ssh-send-password"])
        let problem = app.staticTexts["ssh-problem"]
        XCTAssertTrue(problem.waitForPresence(timeout: 30), app.debugDescription)
        XCTAssertEqual(problem.label, "127.0.0.1 did not take that password. Nothing was kept.")
        picture("address-wrong-password")
        // The person adds the key the phone shows to their account there, then tries again.
        XCTAssertTrue(key.waitForPresence(timeout: 10))
        _ = try await home("ssh-authorize", body: key.label)
        tapOnPhone(app.buttons["ssh-try-again"])
        reach("In reach", timeout: 30)
        let joined = try await home("state", method: "GET")
        let devices = try XCTUnwrap(joined["devices"] as? [[String: Any]])
        XCTAssertEqual(devices.count, 1)
        XCTAssertEqual(devices.first?["kind"] as? String, "view")
        XCTAssertEqual(devices.first?["system"] as? String, "ios")
        XCTAssertTrue(cardHeading("Your phone is reading your Mac").waitForPresence(timeout: 10), app.debugDescription)
        picture("address-joined")
    }

    func testCards() async throws {
        // INF-1574: a retried body's drawn height reaches its native frame three seconds late, as on a loaded computer,
        // so the stalled-answer check below sees a body that is drawn but still clipped by its placeholder.
        app.launchEnvironment["INFINITARY_TEST_RETRIED_CARD_LAG"] = "3"
        try await launchJoined()
        try await verifyMergeCard()
        try await verifyCards()
    }

    /// Part 3, talk and tasks: the composer, a photo, task search, start, interrupt, continue and steer.
    func testTalkAndTasks() async throws {
        try await launchJoined()
        // The single journey reached this part with the cards part's hero card on the stage, after a relaunch.
        _ = try await home("empty-cards")
        let hero = try await home("hero-card")
        XCTAssertTrue(cardHeading(try XCTUnwrap(hero["title"] as? String)).waitForPresence(timeout: 10), app.debugDescription)
        app.terminate(); try await launchPhoneApp(app)
        reach("In reach", timeout: 20)
        try await talkAndTasks()
    }

    /// The relaunch part: INF-1735's 20 dark/light relaunch pairs, each lighting Tasks with one press.
    /// Their own part, so the talk part keeps room within its 20-minute allowance on a loaded Mac (INF-1878).
    /// Data: the talk part's hero card, its on-request harbour task and a sent captain ask, so each launch restores a last turn.
    /// Completion: every pair draws the requested appearance, then lights Tasks and shows its list after a single press.
    /// Resources: this part's own fresh simulator and home; no photo, signing material or real account.
    func testRelaunchThenTasks() async throws {
        try await launchJoined()
        // The talk part's state before its relaunch pair: the hero card on the stage and a restored last turn.
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
        try await relaunchPairs(20)
    }

    /// INF-1735: reach and the restored last turn can precede the requested appearance's drawn chrome.
    /// Use the same observed-appearance owner as appearances(), not a raw hero screenshot followed by a press.
    /// Each round is a fresh dark/light relaunch pair with exactly one Tasks press; a miss fails immediately.
    /// Tasks stays shown after the last round. `pictured` keeps the first round's hero pictures.
    private func relaunchPairs(_ rounds: Int, pictured: Bool = false) async throws {
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

    /// Part 4, the character and past choices: a real held turn, saved-sign-in and saved-answer choices, past-card context.
    func testCharacterAndPastChoices() async throws {
        try await launchJoined()
        try await verifyConversationCharacter()
        try await verifyNativeCrewScene()
        try await verifyReviewedCardChoices()
        try await verifyPastMessageContext()
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
            closeCrewSummary()
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
        closeCrewSummary()
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
                            ("model", "crew-summary-model"), ("reasoning", "crew-summary-reasoning"), ("change", "crew-summary-change"),
                            ("review", "crew-summary-review"), ("reason", "crew-summary-reason")] {
            let shown = preview.staticTexts[id]
            if let words = want[field] as? String, !words.isEmpty {
                XCTAssertEqual(shown.label, words, "\(name): \(field) as the desktop says it")
            } else {
                XCTAssertFalse(shown.exists, "\(name): the desktop shows no \(field)")
            }
        }
        // The checks' words are followed by how long they have run, which moves with the clock.
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
        if themes { try await appearances(name, showing: task) } else { picture(name) }
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

    /// INF-64 piece 4: a phone answers at the real home, not a local stand-in; opaque scripts cannot gain native effects.
    /// The cards part owns its simulator/home, no shared account or signed build.
    private func cardHeading(_ title: String) -> XCUIElement {
        // INF-64 piece 4: departure means leaving the stage, not erasing INF-82's foreground notice.
        app.staticTexts.matching(identifier: "card-title").matching(NSPredicate(format: "label == %@", title)).firstMatch
    }

    private func showCard(_ title: String) {
        if app.staticTexts["card-title"].label == title { return }
        // INF-1651: a pick made while the shown card finishes drawing is lost with the menu still open, so the pager
        // opens once the shown body is revealed: until then it is one closed element with nothing inside.
        let body = app.webViews.matching(identifier: "card-body").firstMatch
        if body.exists {
            let revealed = NSPredicate { _, _ in body.descendants(matching: .any).firstMatch.exists }
            XCTAssertEqual(waitForPhonePredicate(revealed, object: nil, timeout: 10), .completed, "The shown card body was never revealed")
        }
        // SwiftUI Menu is a popup on current iOS; use its own stable identity rather than a legacy button type.
        let pager = app.descendants(matching: .any).matching(identifier: "card-pager").firstMatch
        XCTAssertTrue(pager.waitForPresence(timeout: 10), app.debugDescription); tapOnPhone(pager)
        let item = app.buttons[title].firstMatch
        XCTAssertTrue(item.waitForPresence(timeout: 10), app.debugDescription); tapOnPhone(item)
        XCTAssertTrue(cardHeading(title).waitForPresence(timeout: 10))
    }

    private func reveal(_ element: XCUIElement) {
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

    private func waitUntilEnabled(_ element: XCUIElement) {
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "enabled == true"), object: element, timeout: 10), .completed, app.debugDescription)
    }

    /// INF-1610: a card about the captain's message names it under its title, as on the Mac. A long message shows only
    /// its start, and Show all opens the rest; the card then leaves so the parts after it find the stack as before.
    private func verifyAskedLine() async throws {
        let asked = try await home("asked-card")
        let title = try XCTUnwrap(asked["title"] as? String)
        showCard(title)
        let line = app.staticTexts["card-asked"]
        XCTAssertTrue(line.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(line.label.hasPrefix("You asked · "), line.label)
        let toggle = app.buttons["card-asked-toggle"]
        XCTAssertTrue(toggle.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertEqual(toggle.label, "Show all")
        let folded = line.frame.height
        picture("card-asked-folded")
        tapOnPhone(toggle)
        XCTAssertTrue(app.buttons["Show less"].waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertGreaterThan(line.frame.height, folded * 2, "Show all opens the whole message")
        picture("card-asked-open")
        tapOnPhone(app.buttons["close-card"])
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
        tapOnPhone(app.buttons["close-card"])
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

    /// INF-1541 piece 1: XCTest no longer waits out a dialog's entrance, so its button is read once it takes a touch.
    private func waitUntilHittable(_ element: XCUIElement) {
        XCTAssertTrue(waitForPhonePress(element), app.debugDescription)
    }

    /// INF-1524, the captain: "ios app's cards don't have minimize button. also the merge card doesn't have the radar chart."
    /// Data: a crewmate's merge card with its task, model, place, risk, the host's fact strip, an action to take after
    /// merging, a revision and a thread. Completion: the phone draws the Mac's head and foot, puts the card aside on the
    /// computer, asks before discarding typed words, counts a new card beside the pager and sends the words with a choice.
    private func verifyMergeCard() async throws {
        let fixture = try await home("merge-card")
        let title = try XCTUnwrap(fixture["title"] as? String)
        let words = try XCTUnwrap(fixture["words"] as? String)
        showCard(title)
        XCTAssertTrue(cardHeading(title).waitForPresence(timeout: 10), app.debugDescription)
        // The head: the task's key, the model and where it runs, the risk and the revised line.
        XCTAssertEqual(app.buttons["card-task-key"].label, try XCTUnwrap(fixture["key"] as? String))
        XCTAssertTrue(app.staticTexts["card-model"].exists)
        XCTAssertTrue(app.staticTexts["card-place"].exists)
        XCTAssertTrue(app.staticTexts["card-revised"].exists)
        XCTAssertTrue(app.buttons["put-aside-card"].exists)
        XCTAssertEqual(app.buttons["maximize-card"].exists, UIDevice.current.userInterfaceIdiom == .pad)
        // The foot: the host's fact strip and what to do after merging stay with the choices.
        XCTAssertTrue(app.webViews["card-facts"].staticTexts.firstMatch.waitForPresence(timeout: 20), app.debugDescription)
        XCTAssertTrue(app.staticTexts[try XCTUnwrap(fixture["requiredLead"] as? String)].exists)
        waitUntilEnabled(app.buttons["card-action-merge"])
        // Both appearances of the merge card supply the release note's hero pair.
        try await appearances("merge-card", showing: cardHeading(title))
        // The risk: seven dots that open each dimension's words and the crewmate's why.
        reveal(app.buttons["card-risk"]); app.buttons["card-risk"].tap()
        let blast = app.descendants(matching: .any).matching(identifier: "risk-blast").firstMatch
        XCTAssertTrue(blast.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(blast.label.hasPrefix(try XCTUnwrap(fixture["blast"] as? String)), blast.label)
        picture("merge-risk")
        app.buttons["Done"].tap()
        XCTAssertTrue(blast.waitForAbsence(timeout: 10))
        // The thread names who wrote each message in the Mac's words.
        let thread = app.buttons["Thread"]
        reveal(thread); thread.tap()
        XCTAssertTrue(app.staticTexts[try XCTUnwrap(fixture["threadCrew"] as? String)].waitForPresence(timeout: 10), app.debugDescription)
        picture("merge-thread")
        // Typed words are not lost to a close without a question.
        // On iPhone the merge card's head and foot outgrow its stage, so the whole card scrolls between them.
        let reply = app.textFields["card-reply"]
        reveal(reply); focusForPhoneTyping(reply, in: app); reply.typeText(words)
        // The focused field holds the scroll while the keyboard is up, so Done hides it, keeping the words, before the head is reached.
        if app.keyboards.firstMatch.exists {
            let done = app.buttons["dismiss-phone-keyboard"]
            XCTAssertTrue(done.waitForPresence(timeout: 10), app.debugDescription); done.tap()
            XCTAssertTrue(app.keyboards.firstMatch.waitForAbsence(timeout: 10), app.debugDescription)
        }
        let close = app.buttons["close-card"]
        reveal(close); close.tap()
        let question = app.alerts[try XCTUnwrap(fixture["closeTitle"] as? String)]
        XCTAssertTrue(question.waitForPresence(timeout: 10), app.debugDescription)
        picture("merge-close-question")
        question.buttons[try XCTUnwrap(fixture["keepAnswering"] as? String)].tap()
        XCTAssertTrue(question.waitForAbsence(timeout: 10))
        XCTAssertTrue(cardHeading(title).exists, "Keep answering keeps the card")
        // Put aside is the Mac's minimize: the card leaves the stack and waits on its task's row in Tasks (INF-1517).
        let putAside = app.buttons["put-aside-card"]
        reveal(putAside); putAside.tap()
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
        restore.tap()
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
        reveal(later); later.tap()
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
        reveal(app.buttons["close-card"]); app.buttons["close-card"].tap()
        let newsTitle = try XCTUnwrap(news["title"] as? String)
        showCard(newsTitle)
        reveal(app.buttons["close-card"]); app.buttons["close-card"].tap()
        XCTAssertTrue(cardHeading(newsTitle).waitForAbsence(timeout: 10))
    }

    private func verifyCards() async throws {
        try await verifyAskedLine()
        try await verifyCardReadiness()
        let fixture = try await home("cards-fixture")
        let choice = try XCTUnwrap(fixture["choice"] as? String)
        let chart = try XCTUnwrap(fixture["conversation"] as? String)
        let note = try XCTUnwrap(fixture["note"] as? String)
        showCard(choice)
        let boundary = "effect refused · network refused · parent refused · native refused"
        XCTAssertTrue(app.webViews.staticTexts[boundary].waitForPresence(timeout: 20), app.debugDescription)
        // INF-209's native card chrome promises 44-point touch targets, not padding outside a tiny button.
        for id in ["close-card", "previous-card", "next-card", "card-pager"] {
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
        XCTAssertTrue(beforeCalls.contains { $0["channel"] as? String == "inf:cards:seen" })
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
        XCTAssertTrue(app.buttons["close-card"].isEnabled, "A stalled form cannot keep native chrome busy")
        tapOnPhone(app.buttons["retry-card"])
        XCTAssertTrue(app.webViews.staticTexts[boundary].waitForPresence(timeout: 20))
        waitUntilEnabled(choose)
        reveal(choose); tapOnPhone(choose)
        XCTAssertTrue(app.staticTexts["Answer each required question first."].waitForPresence(timeout: 10))
        let refused = try await home("card-state", method: "GET")
        XCTAssertNil(refused["choice"] as? [String: Any])
        showCard(chart); showCard(choice)
        // INF-209: sideways paging belongs to the native card head, outside authored gestures.
        app.staticTexts["card-title"].swipeLeft()
        XCTAssertTrue(cardHeading(chart).waitForPresence(timeout: 10))
        app.staticTexts["card-title"].swipeRight()
        XCTAssertTrue(cardHeading(choice).waitForPresence(timeout: 10))
        // INF-1263: the paged-back body offers its text only where a tap reaches it. Read the body and the text in one
        // snapshot the moment the text appears; before the fix it appeared while the body was its 48-point placeholder.
        // INF-1651: iOS 27.0 first reports the text's frame relative to the web view, so where the text sits is read
        // once it settles.
        let body = app.webViews.matching(identifier: "card-body").firstMatch
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
        tapOnPhone(app.buttons["close-card"])
        _ = try await home("show-past")
        // INF-589 item 7: an answered card opened from its notice shows as a past card.
        XCTAssertTrue(app.staticTexts["Past"].waitForPresence(timeout: 10))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "card-pager").firstMatch.label, "Past card")
        tapOnPhone(app.buttons["close-card"])

        showCard(chart)
        // INF-1062: with no bar under it, scrolling a long card leaves the message box where it is, in the column's width.
        if UIDevice.current.userInterfaceIdiom == .phone {
            let composer = app.otherElements["phone-composer"].firstMatch
            let before = composer.frame
            app.scrollViews["card-scroll"].swipeUp()
            XCTAssertEqual(composer.frame.minY, before.minY, accuracy: 1, "Scrolling a card does not move the message box")
            XCTAssertEqual(composer.frame.width, before.width, accuracy: 1, "Scrolling a card does not narrow the message box")
            verifyPhoneComposerBounds(app: app)
            try await appearances("card-scrolled", showing: app.buttons["close-card"])
        }
        let pictureElement = app.webViews.images["Blue harbour survey"].firstMatch
        XCTAssertTrue(pictureElement.waitForPresence(timeout: 10))
        reveal(pictureElement); tapOnPhone(pictureElement)
        XCTAssertTrue(app.webViews["card-picture"].waitForPresence(timeout: 10))
        picture("picture-viewer")
        _ = try await home("capture-picture-start")
        app.webViews["card-picture"].pinch(withScale: 1.6, velocity: 1)
        picture("picture-zoomed")
        _ = try await home("capture-stop")
        tapOnPhone(app.buttons["Done"])
        // The home measures the recording and owns its duration label.
        let play = app.webViews.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Play the demo,")).firstMatch
        reveal(play)
        _ = try await home("capture-media-start")
        tapOnPhone(play)
        let player = app.descendants(matching: .any).matching(identifier: "card-recording").firstMatch
        XCTAssertTrue(player.waitForPresence(timeout: 10))
        // The body's Play already starts playback; AVKit may hide its controls before a short clip ends.
        // Completion comes from the real player's end notification, not a transient controls snapshot.
        XCTAssertTrue(app.staticTexts["recording-finished"].waitForPresence(timeout: 15), app.debugDescription)
        tapOnPhone(app.buttons["Play again"])
        XCTAssertTrue(app.staticTexts["recording-finished"].waitForPresence(timeout: 15))
        let mediaState = XCTAttachment(string: app.debugDescription)
        mediaState.name = "recording-controls"; mediaState.lifetime = .keepAlways; add(mediaState)
        picture("recording-playing")
        _ = try await home("capture-stop")
        tapOnPhone(app.buttons["Done"])
        let reply = app.textFields["card-reply"]
        reveal(reply)
        _ = try await home("capture-reply-start")
        focusForPhoneTyping(reply, in: app); reply.typeText("Keep the northern entrance clear.")
        let send = app.buttons["send-reply"]
        reveal(send); tapOnPhone(send)
        XCTAssertTrue(app.staticTexts["Keep the northern entrance clear."].waitForPresence(timeout: 10), app.debugDescription)
        let replied = try await home("card-state", method: "GET")
        let thread = try XCTUnwrap(replied["thread"] as? [String: Any])
        XCTAssertTrue((thread["messages"] as? [[String: Any]] ?? []).contains {
            $0["who"] as? String == "captain" && $0["text"] as? String == "Keep the northern entrance clear."
        })
        _ = try await home("thread-answer")
        XCTAssertTrue(app.staticTexts["I kept your harbour reply with this chart."].waitForPresence(timeout: 10))
        picture("card-thread")
        _ = try await home("capture-stop")
        let browser = app.buttons["card-action-browser"]
        reveal(browser); tapOnPhone(browser)
        XCTAssertTrue(app.staticTexts["Do this on Test Mac mini."].waitForPresence(timeout: 10))

        _ = try await home("offline")
        XCTAssertTrue(app.staticTexts["Out of reach"].waitForPresence(timeout: 20))
        XCTAssertFalse(app.buttons["close-card"].isEnabled)
        XCTAssertFalse(app.buttons["card-action-body"].isEnabled)
        let atDisconnect = try await home("card-state", method: "GET")
        let bodyButton = app.webViews.buttons["Choose from the body"]
        reveal(bodyButton); tapOnPhone(bodyButton)
        picture("card-out-of-reach")
        _ = try await home("online")
        reach("In reach", timeout: 20)
        let afterReconnect = try await home("card-state", method: "GET")
        let writes: ([String: Any]) -> Int = { state in (state["calls"] as? [[String: Any]] ?? []).filter { $0["channel"] as? String == "inf:cards:act" }.count }
        XCTAssertEqual(writes(afterReconnect), writes(atDisconnect), "An offline body action is never replayed")
        _ = try await home("hold-card-action")
        reveal(bodyButton); tapOnPhone(bodyButton)
        _ = try await home("card-action-held")
        XCTAssertFalse(app.buttons["card-action-body"].isEnabled, "A body choice owns the same pending gate as the footer")
        XCTAssertFalse(app.buttons["close-card"].isEnabled)
        tapOnPhone(bodyButton)
        XCTAssertTrue(app.staticTexts["This card already has a choice in progress."].waitForPresence(timeout: 10))
        _ = try await home("release-card-action")
        XCTAssertTrue(cardHeading(chart).waitForAbsence(timeout: 10))
        let bodyChoice = try await home("card-state", method: "GET")
        XCTAssertEqual(writes(bodyChoice), writes(afterReconnect) + 1, "The competing body input sends no second change")
        let bodyPast = try XCTUnwrap(bodyChoice["conversation"] as? [String: Any])
        XCTAssertEqual((bodyPast["ending"] as? [String: Any])?["actionId"] as? String, "body")
        // The choice wakes the first mate; its turn ends before INF-1060 below reads the footer's reply button.
        _ = try await home("card-choice-turn-ended")
        _ = try await home("show-body-past")
        XCTAssertTrue(app.staticTexts["Past"].waitForPresence(timeout: 10))
        XCTAssertEqual((bodyPast["ending"] as? [String: Any])?["by"] as? String, "frame")
        let pastWords = try XCTUnwrap(bodyChoice["conversationEnding"] as? String)
        XCTAssertTrue(app.staticTexts["past-ending"].label.hasPrefix(pastWords), "A script's choice is not credited to the captain")
        picture("past-body-choice")
        tapOnPhone(app.buttons["close-card"])
        showCard(note)
        tapOnPhone(app.buttons["close-card"])
        XCTAssertTrue(cardHeading(note).waitForAbsence(timeout: 10))
        let closed = try await home("card-state", method: "GET")
        XCTAssertNotNil(closed["note"] as? [String: Any])
        XCTAssertEqual(closed["leaks"] as? Int, 0)
        // INF-1060, the captain: "after cards are dismissed, it doesn't extend back". With the last card closed,
        // the message box keeps its place and the column's width at the foot of Home.
        verifyPhoneComposerBounds(app: app)
        picture("cards-answered-and-closed")
        // INF-1059, the captain's "why images couldn't render inline?": a picture card already in the stack when the
        // phone comes back is drawn from the first cards read while the board read is still out, so its picture is asked
        // before the computer is in reach. The phone asks for it once it is in reach, rather than keeping a broken box.
        _ = try await home("offline")
        XCTAssertTrue(app.staticTexts["Out of reach"].waitForPresence(timeout: 20))
        let late = try await home("late-picture-card")
        let lateTitle = try XCTUnwrap(late["title"] as? String)
        _ = try await home("online")
        XCTAssertTrue(cardHeading(lateTitle).waitForPresence(timeout: 20), app.debugDescription)
        XCTAssertTrue(app.webViews.staticTexts[try XCTUnwrap(late["words"] as? String)].waitForPresence(timeout: 10))
        _ = try await home("board-read-held")
        _ = try await home("release-board-read")
        reach("In reach", timeout: 20)
        _ = try await home("late-picture-asked")
        picture("card-picture-after-reaching")
        tapOnPhone(app.buttons["close-card"])
        XCTAssertTrue(cardHeading(lateTitle).waitForAbsence(timeout: 10))
        // The same after view in both themes supplies the release note's native hero pair.
        let hero = try await home("hero-card")
        showCard(try XCTUnwrap(hero["title"] as? String))
        XCTAssertTrue(app.webViews.staticTexts["Chart for daylight sailing"].waitForPresence(timeout: 10))
        verifyPhoneComposerBounds(app: app)
        picture("cards-hero-light")
        _ = try await home("appearance-dark", budget: displayBudget)
        XCTAssertTrue(app.webViews.staticTexts["Chart for night sailing"].waitForPresence(timeout: 10))
        verifyPhoneComposerBounds(app: app)
        picture("cards-hero-dark")
        _ = try await home("appearance-light", budget: displayBudget)
        // INF-944 item 5 with INF-945's pick: the Mac's row, pinned at the card's foot with no scrolling,
        // the default last at the right and every choice keeping a 44-point touch area.
        let keepChoice = app.buttons["card-action-keep"], waitChoice = app.buttons["card-action-wait"]
        XCTAssertTrue(waitForPhonePress(keepChoice), "The choices sit in view without scrolling")
        XCTAssertTrue(waitForPhonePress(waitChoice))
        // The answered count starts the first line, so the row wraps where its choices do not fit beside it.
        if abs(keepChoice.frame.midY - waitChoice.frame.midY) < 1 {
            XCTAssertLessThan(waitChoice.frame.maxX, keepChoice.frame.minX, "The default is drawn last")
        } else {
            XCTAssertGreaterThan(keepChoice.frame.minY, waitChoice.frame.minY, "The default is drawn last")
            XCTAssertEqual(keepChoice.frame.maxX, waitChoice.frame.maxX, accuracy: 1, "Each line sits at the trailing edge")
        }
        // XCUI reports the 44-point area in fractions of a pixel, such as 43.99999999999994.
        XCTAssertGreaterThanOrEqual(keepChoice.frame.height.rounded(), 44)
        XCTAssertLessThan(keepChoice.frame.width, app.scrollViews["card-scroll"].frame.width / 2, "A choice keeps its own width")
        // INF-944 item 3: a card minimized on the computer leaves the phone's stack.
        // INF-1517, the captain's picks: Home keeps no Minimized menu; the card waits in Tasks under Waiting on you,
        // in its own row since it has no task, and a tap brings it back on Home and on the computer.
        let heroTitle = try XCTUnwrap(hero["title"] as? String)
        _ = try await home("minimize-hero")
        XCTAssertTrue(cardHeading(heroTitle).waitForAbsence(timeout: 10), app.debugDescription)
        let pager = app.descendants(matching: .any).matching(identifier: "card-pager").firstMatch
        XCTAssertTrue(pager.waitForAbsence(timeout: 10), "Home shows no Minimized menu")
        tab("Tasks")
        let restore = app.buttons.matching(identifier: "minimized-card").matching(NSPredicate(format: "label == %@", heroTitle)).firstMatch
        XCTAssertTrue(restore.waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertLessThan(app.buttons["group-waiting"].frame.minY, restore.frame.minY, "It is listed under Waiting on you")
        picture("tasks-minimized")
        tapOnPhone(restore)
        XCTAssertTrue(cardHeading(heroTitle).waitForPresence(timeout: 10), "Its row brings the card back on Home")
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "selected == true"), object: app.buttons["tab-home"], timeout: 10), .completed)
        let restored = try await home("hero-state", method: "GET")
        let restoredCard = try XCTUnwrap(restored["card"] as? [String: Any])
        XCTAssertNil(restoredCard["minimized"], "The phone brings it back on the computer too")
        // INF-209: the native frame remains usable at the largest standard Dynamic Type size.
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL"]
        try await launchPhoneApp(app)
        reach("In reach", timeout: 20)
        showCard(try XCTUnwrap(hero["title"] as? String))
        let largeChoice = app.buttons["card-action-keep"]
        reveal(largeChoice)
        XCTAssertEqual(largeChoice.label, "Use this entrance")
        picture("card-large-type")
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
        XCTAssertTrue(app.staticTexts["Past"].waitForPresence(timeout: 10)); tapOnPhone(app.buttons["close-card"])
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
        tapOnPhone(app.buttons["close-card"])
    }

    /// INF-499 #3: reading a past card gives the message its history hint, never a current-card hint.
    private func verifyPastMessageContext() async throws {
        let fixture = try await home("context-fixture")
        showCard(try XCTUnwrap(fixture["title"] as? String))
        tapOnPhone(app.buttons["close-card"])
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
        tapOnPhone(app.buttons["close-card"])
    }

    /// INF-64 piece 5: native input and controls reach the real Mac as captain actions.
    /// Data: a project-owned photo, a typed harbour ask, and an on-request task with a held mock-provider turn.
    /// Completion: the Mac keeps the ask/photo, runs that task, records interruption/continuation and hears the steer.
    /// Resources: this journey's existing fresh simulator/home only; no phone signing, microphone or real account.
    private func talkAndTasks() async throws {
        let fixture = try await home("talk-fixture")
        let words = try XCTUnwrap(fixture["text"] as? String)
        addPhoneJourneyPhoto(app: app)
        let input = app.textFields["message-box"]
        focusForPhoneTyping(input, in: app); input.typeText(words)
        picture("message-and-photo")
        let beforeDraft = try await home("talk-state", method: "GET")
        try await verifyComposerDraft(words)
        let afterDraft = try await home("talk-state", method: "GET")
        XCTAssertEqual((afterDraft["writes"] as? [Any])?.count, (beforeDraft["writes"] as? [Any])?.count,
            "Command-Return behind the details sheet sends no hidden composer request")
        // The completed keyboard/details interactions follow rotation's intermediate redraw.
        picture("draft-portrait-ready")
        tapOnPhone(app.buttons["send-message"])
        let sent = try await home("talk-sent")
        let writes = try XCTUnwrap(sent["writes"] as? [[String: Any]])
        let message = try XCTUnwrap(writes.first { $0["channel"] as? String == "inf:converse" })
        XCTAssertEqual((message["actor"] as? [String: Any])?["kind"] as? String, "captain")
        let payload = try XCTUnwrap((message["args"] as? [[String: Any]])?.first)
        XCTAssertEqual(payload["text"] as? String, words)
        XCTAssertEqual(payload["visibleCardId"] as? String, fixture["visibleCardId"] as? String)
        XCTAssertNotNil(payload["visibleCardId"])
        XCTAssertNil(payload["pastCardId"])
        let images = try XCTUnwrap(payload["images"] as? [[String: Any]])
        XCTAssertEqual(images.count, 1); XCTAssertGreaterThan(try XCTUnwrap(images.first?["bytes"] as? Int), 0)
        XCTAssertEqual((sent["lastTurn"] as? [String: Any])?["you"] as? String, words)
        XCTAssertTrue(app.staticTexts["last-turn-you"].waitForPresence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "photo-chip").count, 0)
        verifyPhoneComposerBounds(app: app)
        picture("last-turn")
        // One pair here for the hero pictures; the relaunch part runs INF-1735's 20 (testRelaunchThenTasks).
        try await relaunchPairs(1, pictured: true)
        XCTAssertTrue(app.buttons["group-backlog"].waitForPresence(timeout: 10))
        picture("tasks")
        tapOnPhone(app.buttons["group-backlog"])
        XCTAssertTrue(app.buttons["task-phone-work"].waitForPresence(timeout: 10))
        picture("tasks-backlog")
        // INF-589 item 9: search waits above the list until it is pulled down, and Find a task opens it by key, as on the Mac.
        let search = app.textFields["task-search"]
        XCTAssertFalse(search.exists)
        app.scrollViews["tasks-list"].swipeDown()
        XCTAssertTrue(search.waitForPresence(timeout: 10))
        tapOnPhone(app.buttons["close-task-search"])
        XCTAssertTrue(search.waitForAbsence(timeout: 10))
        try await pressPhoneKey("f", modifiers: [.command, .shift], in: app)
        XCTAssertTrue(search.waitForPresence(timeout: 10))
        search.typeText("harbour")
        XCTAssertTrue(app.buttons["task-phone-work"].waitForPresence(timeout: 10))
        picture("task-search")
        tapOnPhone(app.buttons["task-phone-work"])
        XCTAssertTrue(app.buttons["start-task"].waitForPresence(timeout: 10))
        picture("task-before-start")
        _ = try await home("capture-talk-start")
        tapOnPhone(app.buttons["start-task"])
        let started = try await home("talk-started")
        XCTAssertNotNil(started["startedAt"] as? Double)
        XCTAssertTrue(started["executionDeviceId"] is NSNull, "The phone starts work on its Mac, never on the phone")
        XCTAssertTrue(app.buttons["Crewmate"].waitForPresence(timeout: 10)); tapOnPhone(app.buttons["Crewmate"])
        XCTAssertTrue(app.buttons["interrupt-task"].waitForPresence(timeout: 10))
        picture("crewmate-working")
        _ = try await home("capture-stop")
        tapOnPhone(app.buttons["interrupt-task"])
        let interrupted = try await home("talk-interrupted")
        let events = try XCTUnwrap(interrupted["events"] as? [[String: Any]])
        XCTAssertTrue(events.contains { $0["kind"] as? String == "interrupted" && $0["actor"] as? String == "captain" })
        XCTAssertEqual(interrupted["activity"] as? String, "idle", "Interrupt stops the turn and keeps it steerable")
        _ = try await home("talk-resumable")
        XCTAssertTrue(app.buttons["continue-task"].waitForPresence(timeout: 10))
        picture("task-interrupted")
        tapOnPhone(app.buttons["continue-task"])
        XCTAssertTrue(app.buttons["interrupt-task"].waitForPresence(timeout: 20))
        let steer = try XCTUnwrap(fixture["steer"] as? String)
        let steerField = app.textFields["steer-box"]
        focusForPhoneTyping(steerField, in: app); steerField.typeText(steer)
        tapOnPhone(app.buttons["steer-task"])
        let steered = try await home("talk-steered")
        let task = try XCTUnwrap(steered["task"] as? [String: Any])
        XCTAssertEqual(task["outcome"] as? String, fixture["report"] as? String)
        let allWrites = try XCTUnwrap(steered["writes"] as? [[String: Any]])
        for write in allWrites { XCTAssertEqual((write["actor"] as? [String: Any])?["kind"] as? String, "captain") }
        XCTAssertTrue(allWrites.contains { $0["channel"] as? String == "inf:task:run" && ($0["args"] as? [String])?.last == "continue-task" })
        picture("crewmate-steered")
        tapOnPhone(app.buttons["close-record"])
        // INF-589 item 6: the notice is a quiet pill under the title on any tab, and a tap opens its card.
        let notice = app.buttons["phone-notice"]
        XCTAssertTrue(notice.waitForPresence(timeout: 10))
        // INF-1062: the notice sits under the top bar on any tab, never over its strip.
        let bar = app.navigationBars.firstMatch
        XCTAssertGreaterThanOrEqual(notice.frame.minY, bar.frame.maxY, "The notice sits under the bar, not over it")
        XCTAssertTrue(app.buttons["tab-tasks"].isSelected, "The notice shows on Tasks, where the record was")
        picture("foreground-notice")
        // INF-1541 piece 1: turned, an iPhone's strip moves into the bar; an iPad brings Home's stage beside the sidebar,
        // where INF-1524 counts the new card beside the pager, so its count is what the turn carries into view.
        turnPhone(to: .landscapeLeft, in: app,
                  moving: UIDevice.current.userInterfaceIdiom == .pad ? app.buttons["card-new"] : app.buttons["tab-home"])
        if UIDevice.current.userInterfaceIdiom == .pad {
            // INF-589 item 16: in landscape the stage is Home, beside the sidebar rather than across it.
            // INF-1524, the captain's pick: Home counts the new card beside the pager instead of a pill over the stage.
            let sidebar = phoneSidebar(app)
            XCTAssertTrue(sidebar.waitForPresence(timeout: 10))
            let fresh = app.buttons["card-new"]
            XCTAssertTrue(fresh.waitForPresence(timeout: 10), app.debugDescription)
            XCTAssertNotNil(fresh.label.wholeMatch(of: /[1-9][0-9]* new/), fresh.label)
            XCTAssertFalse(notice.exists, "Home counts the new card instead of a pill")
            XCTAssertGreaterThanOrEqual(fresh.frame.minX, sidebar.frame.maxX, "The count belongs to the stage")
            picture("notice-landscape")
        } else {
            // INF-589 item 17: on its side the card gets the height; the one-row bar keeps its strip and the notice waits.
            XCTAssertTrue(notice.waitForAbsence(timeout: 10))
            XCTAssertTrue(waitForPhonePress(app.buttons["tab-home"]), "The strip stays in the bar on its side")
            picture("on-its-side")
        }
        // Upright, the strip comes back under the bar: from the bar on an iPhone, and from nowhere on an iPad.
        turnPhone(to: .portrait, in: app, moving: app.buttons["tab-home"])
        XCTAssertTrue(notice.waitForPresence(timeout: 10), "Upright, the unread notice returns")
        let noticed = notice.label
        tapOnPhone(notice)
        XCTAssertTrue(notice.waitForAbsence(timeout: 10))
        let heading = app.staticTexts["card-title"]
        XCTAssertTrue(heading.waitForPresence(timeout: 10))
        XCTAssertTrue(noticed.hasSuffix(": " + heading.label), "The notice \(noticed) opens its own card, not \(heading.label)")
        // The card opens on Home, where the last turn and the message box are.
        XCTAssertTrue(app.buttons["tab-home"].isSelected)
        XCTAssertTrue(app.staticTexts["last-turn-you"].waitForPresence(timeout: 10))
        focusForPhoneTyping(input, in: app); input.typeText("Keep this unsent draft")
        _ = try await home("offline")
        XCTAssertTrue(app.staticTexts["Out of reach"].waitForPresence(timeout: 20))
        XCTAssertFalse(app.buttons["send-message"].isEnabled)
        verifyPhoneComposerBounds(app: app)
        picture("offline-draft")
        _ = try await home("online")
        reach("In reach", timeout: 20)
        let after = try await home("talk-state", method: "GET")
        XCTAssertEqual((after["writes"] as? [Any])?.count, allWrites.count, "Reconnecting never sends the retained draft")
        XCTAssertEqual(input.value as? String, "Keep this unsent draft")
        _ = try await home("lose-reply")
        tapOnPhone(app.buttons["send-message"])
        let unconfirmed = app.staticTexts["message-problem"]
        XCTAssertTrue(unconfirmed.waitForPresence(timeout: 20))
        XCTAssertTrue(unconfirmed.label.contains("Could not confirm"), unconfirmed.label)
        verifyPhoneComposerBounds(app: app)
        picture("unconfirmed-send")
        XCTAssertGreaterThanOrEqual(unconfirmed.frame.minY, app.frame.minY)
        XCTAssertLessThanOrEqual(unconfirmed.frame.maxY, app.frame.maxY, "The entire unconfirmed-send warning stays on screen")
        XCTAssertTrue(waitForPhonePress(unconfirmed), "Nothing sits over the warning at the foot")
        _ = try await home("online")
        reach("In reach", timeout: 20)
        let once = try await home("talk-state", method: "GET")
        XCTAssertEqual((once["writes"] as? [Any])?.count, allWrites.count + 1, "A lost reply never repeats the mutation")
        XCTAssertEqual(input.value as? String, "Keep this unsent draft")
        _ = try await home("read-only")
        reach("In reach", timeout: 20)
        XCTAssertFalse(app.buttons["send-message"].isEnabled, "A version-mismatched view can read but cannot act")
        // INF-1649: the line names the side to update; a home past the phone's floor means this phone.
        XCTAssertEqual(app.staticTexts["connection-refusal"].label, "Update Infinitary on this phone to make changes.")
        verifyPhoneComposerBounds(app: app)
        picture("read-only-draft")
        // INF-1649, the captain's direction A: a newer home whose major kept views answers this phone in full.
        _ = try await home("within-floor")
        reach("In reach", timeout: 20)
        XCTAssertTrue(app.staticTexts["connection-refusal"].waitForAbsence(timeout: 20), "Within the floor nothing refuses a change")
        XCTAssertTrue(app.buttons["send-message"].isEnabled, "A view within the home's floor can act")
        XCTAssertEqual(input.value as? String, "Keep this unsent draft")
        picture("within-floor-draft")
        // INF-1649 review R8: a change across majors reaches the newer home: the kept draft sends once.
        tapOnPhone(app.buttons["send-message"])
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value != %@", "Keep this unsent draft"), object: input, timeout: 20), .completed)
        let olderView = try await home("talk-state", method: "GET")
        let olderViewWrites = try XCTUnwrap(olderView["writes"] as? [[String: Any]])
        XCTAssertEqual(olderViewWrites.count, try XCTUnwrap(once["writes"] as? [Any]).count + 1, "A view within the floor changes things on a newer home")
        XCTAssertEqual(olderViewWrites.last?["channel"] as? String, "inf:converse")
        XCTAssertEqual((olderViewWrites.last?["args"] as? [[String: Any]])?.first?["text"] as? String, "Keep this unsent draft")
        // A home older than this phone's floor: the line names the computer, and the draft waits.
        focusForPhoneTyping(input, in: app); input.typeText("Sent to an older computer")
        _ = try await home("older-home")
        reach("In reach", timeout: 20)
        XCTAssertTrue(app.staticTexts["connection-refusal"].waitForPresence(timeout: 20))
        XCTAssertEqual(app.staticTexts["connection-refusal"].label, "Update Infinitary on your computer to make changes.")
        XCTAssertFalse(app.buttons["send-message"].isEnabled, "A view newer than the home's reach can read but cannot act")
        picture("older-home-draft")
        // A home at this phone's floor answers it in full, and the draft sends there.
        _ = try await home("older-home-within")
        reach("In reach", timeout: 20)
        XCTAssertTrue(app.staticTexts["connection-refusal"].waitForAbsence(timeout: 20), "On a home its floor reaches nothing refuses a change")
        XCTAssertEqual(input.value as? String, "Sent to an older computer")
        tapOnPhone(app.buttons["send-message"])
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value != %@", "Sent to an older computer"), object: input, timeout: 20), .completed)
        let newerView = try await home("talk-state", method: "GET")
        let newerViewWrites = try XCTUnwrap(newerView["writes"] as? [[String: Any]])
        XCTAssertEqual(newerViewWrites.count, olderViewWrites.count + 1, "A newer view changes things on an older home its floor reaches")
        XCTAssertEqual((newerViewWrites.last?["args"] as? [[String: Any]])?.first?["text"] as? String, "Sent to an older computer")

        // INF-355: exercise first-after-relaunch paging and Send after the original journey.
        // Earlier relaunches here would erase that journey's in-session past-card prerequisite.
        // Keep all original button-based Send, photo, card and refusal checks unchanged.
        app.terminate()
        _ = try await home("offline")
        _ = try await home("online")
        let keyCards = try await home("cards-fixture")
        let choice = try XCTUnwrap(keyCards["choice"] as? String)
        let chart = try XCTUnwrap(keyCards["conversation"] as? String)
        try await launchPhoneApp(app)
        XCTAssertTrue(app.scrollViews["card-scroll"].waitForPresence(timeout: 20))
        showCard(choice)
        XCTAssertTrue(app.buttons["next-card"].isEnabled)
        computerDetails()
        try await pressPhoneKey("]", modifiers: [.command, .shift], in: app)
        tapOnPhone(app.buttons["close-computer-details"])
        XCTAssertTrue(cardHeading(choice).waitForPresence(timeout: 10), "A sheet keeps its pager shortcut from the stage behind it")
        try await pressPhoneKey("]", modifiers: [.command, .shift], in: app)
        XCTAssertTrue(cardHeading(chart).waitForPresence(timeout: 10))
        app.terminate(); try await launchPhoneApp(app)
        XCTAssertTrue(app.scrollViews["card-scroll"].waitForPresence(timeout: 20))
        showCard(chart)
        XCTAssertTrue(app.buttons["previous-card"].isEnabled)
        try await pressPhoneKey("[", modifiers: [.command, .shift], in: app)
        XCTAssertTrue(cardHeading(choice).waitForPresence(timeout: 10))

        // INF-82: Command-Return sends the complete multiline ask once, not merely hides a keyboard.
        app.terminate(); try await launchPhoneApp(app)
        reach("In reach", timeout: 20)
        XCTAssertTrue(input.waitForPresence(timeout: 10))
        // A multiline field exposes its empty value differently from placeholderValue.
        // Read that state before typing, then require Send to restore it.
        let emptyDraft = try XCTUnwrap(input.value as? String)
        let keyboardWords = words + "\nUse the photo from my earlier message."
        focusForPhoneTyping(input, in: app); input.typeText(keyboardWords)
        XCTAssertEqual(input.value as? String, keyboardWords)
        XCTAssertTrue(app.buttons["send-message"].isEnabled)
        try await pressPhoneKey(XCUIKeyboardKey.return.rawValue, modifiers: .command, in: app)
        XCTAssertEqual(waitForPhonePredicate(NSPredicate(format: "value == %@", emptyDraft), object: input, timeout: 20), .completed)
        let keySent = try await home("talk-state", method: "GET")
        let keyWrites = try XCTUnwrap(keySent["writes"] as? [[String: Any]])
        XCTAssertEqual(keyWrites.count, newerViewWrites.count + 1)
        let keyMessage = try XCTUnwrap(keyWrites.last)
        XCTAssertEqual(keyMessage["channel"] as? String, "inf:converse")
        XCTAssertEqual((keyMessage["actor"] as? [String: Any])?["kind"] as? String, "captain")
        let keyPayload = try XCTUnwrap((keyMessage["args"] as? [[String: Any]])?.first)
        XCTAssertEqual(keyPayload["text"] as? String, keyboardWords)
        XCTAssertEqual((keyPayload["images"] as? [Any])?.count, 0)
        picture("sent-by-keyboard")
    }

    /// INF-209 and INF-82 integration: one composer retains the actual typed/photo draft across tabs and rotation.
    /// This extends the existing real-home journey, using its owned simulator, selected photo and captain ask.
    private func verifyComposerDraft(_ words: String) async throws {
        try await verifyPhoneComposerDrafts(app: app, words: words, tab: { tab($0) }, picture: picture) { start in
            _ = try await self.home(start ? "capture-composer-start" : "capture-stop")
        }
    }


}
