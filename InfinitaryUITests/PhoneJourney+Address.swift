import XCTest

/// The address part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
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
}
