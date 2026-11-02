import SwiftUI
import XCTest
@testable import Infinitary

/// INF-1753: one press of Shift-Command-] turns one card. On a busy iPad the page turn held the main thread past UIKit's
/// key repeat delay, and the repeating SwiftUI shortcut turned a second page before the key-up arrived, skipping a card.
@MainActor final class PhonePagerKeysTests: XCTestCase {
    func testPagerChordsTurnOnePageEachAndNeverRepeat() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        defer { window.isHidden = true; window.rootViewController = nil }
        var pages: [Int] = []
        let host = UIHostingController(rootView: AnyView(PhonePagerKeys(previous: { pages.append(-1) }, next: { pages.append(1) })))
        window.rootViewController = host
        window.makeKeyAndVisible()
        // UIKit looks a chord up among the root view controller's key commands, SwiftUI's own shortcuts beside ours.
        func chords(_ input: String) -> [UIKeyCommand] {
            (host.keyCommands ?? []).filter { $0.input == input && $0.modifierFlags == [.command, .shift] }
        }
        var deadline = PhoneWaitDeadline(20)
        while chords("[").isEmpty || chords("]").isEmpty {
            if deadline.expired() { XCTFail("The pager never offered its chords"); return }
            try await Task.sleep(for: .seconds(PhoneWaitDeadline.tick))
        }
        // UIKit sends a key command's action to the first responder up the chain from where the command was found.
        func press(_ input: String) throws {
            let command = try XCTUnwrap(chords(input).first)
            let action = try XCTUnwrap(command.action)
            let target = try XCTUnwrap(host.target(forAction: action, withSender: command), "Nothing up the chain runs \(input)")
            XCTAssertTrue(UIApplication.shared.sendAction(action, to: target, from: command, for: nil))
        }
        for input in ["[", "]"] {
            XCTAssertEqual(chords(input).count, 1, "Shift-Command-\(input) has exactly one command")
            if #available(iOS 26, *) {
                XCTAssertEqual(chords(input).first?.repeatBehavior, .nonRepeatable, "Holding Shift-Command-\(input) turns no second page")
            }
        }
        try press("[")
        try press("]")
        XCTAssertEqual(pages, [-1, 1], "Each chord turns one page in its own direction")

        await withCheckedContinuation { done in host.present(UIViewController(), animated: false) { done.resume() } }
        try press("]")
        XCTAssertEqual(pages, [-1, 1], "A sheet keeps the pager's chords from the stage behind it")
        await withCheckedContinuation { done in host.dismiss(animated: false) { done.resume() } }
        try press("]")
        XCTAssertEqual(pages, [-1, 1, 1], "The chords come back once the sheet closes")

        host.rootView = AnyView(EmptyView())
        deadline = PhoneWaitDeadline(20)
        while !chords("]").isEmpty {
            if deadline.expired() { XCTFail("The chords stayed after the pager left"); return }
            try await Task.sleep(for: .seconds(PhoneWaitDeadline.tick))
        }
        XCTAssertTrue(chords("[").isEmpty, "Without a pager neither chord is offered")
    }
}
