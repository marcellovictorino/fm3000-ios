import XCTest

/// The pick part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// INF-2095: a quick pick on the card pager's menu was lost, with the menu left open, when the reply notice cleared
    /// inside the tap: the clear redrew the workspace, which re-ran the pager's menu, and UIKit rebuilt the open menu
    /// under the finger. A redraw that changes no card leaves the open menu alone, so every pick lands.
    /// Data: the joined home's first card and the merge card, whose reply notice the first redraw clears while it shows.
    /// Completion: each pick shows its card's heading, and the app's probe counts the taps it redrew and no menu rebuild.
    /// Platform: either device's simulator; the probe and its switch exist only in a simulator build of the gate.
    /// Resources: this test's own fresh app and test home; no photo, signing material or real account.
    func testMenuPickSurvivesAWorkspaceRedraw() async throws {
        // The app's probe redraws the workspace 10 ms into each touch on a menu item, clearing the notice when one shows.
        app.launchEnvironment["INFINITARY_TEST_MENU_TAP_REDRAW"] = "1"
        try await launchJoined()
        let first = app.staticTexts["card-title"].label
        let merged = try await home("merge-card")
        let merge = try XCTUnwrap(merged["title"] as? String)
        let probe = app.descendants(matching: .any).matching(identifier: "menu-tap-probe").firstMatch
        XCTAssertTrue(probe.waitForPresence(timeout: 10), app.debugDescription)
        // Four picks, each of the card not shown, so every pick that lands changes the heading.
        for (round, title) in [merge, first, merge, first].enumerated() {
            showCard(title)
            let counted = NSPredicate(format: "label BEGINSWITH %@", "\(round + 1) taps, ")
            XCTAssertEqual(waitForPhonePredicate(counted, object: probe, timeout: 10), .completed, probe.label)
            XCTAssertEqual(probe.label.components(separatedBy: ", ")[1], "0 rebuilds", "A redraw inside pick \(round + 1) rebuilt the open menu")
        }
        print("INF-2095 menu picks across a workspace redraw: \(probe.label)")
    }
}
