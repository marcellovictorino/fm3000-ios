import SwiftUI
import XCTest
@testable import Infinitary
@testable import InfinitaryKit

/// INF-3462, the captain: "i want to make the animation never clipped. it can sit underneath other elements". Home's
/// crew scene was drawn inside the stage between the top bar and the message area, so a short stage, as with the
/// keyboard up or a phone on its side, cut the first mate and the crew flat. The drawing now covers the whole window,
/// under the message box, while the stage keeps its touch in the middle space.
/// Hosts the shipped Home (the cards stage and the message box) for a joined computer that has not answered yet.
@MainActor final class PhoneSceneBackdropTests: XCTestCase {
    func testHomeDrawsTheCrewSceneAcrossTheWindowUnderTheMessageBox() async throws {
        let session = ReadOnlySession(mac: JoinedMac(addresses: [], pin: "backdrop", deviceID: "backdrop", name: "Mac"),
                                      phone: try PhoneIdentity.loadOrCreate())
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        defer { window.isHidden = true; window.rootViewController = nil }
        // An upright window, so Home shows its stage over the message box and no sidebar.
        let size = scene.coordinateSpace.bounds.size
        window.frame = CGRect(x: 0, y: 0, width: min(size.width, size.height), height: max(size.width, size.height))
        window.rootViewController = UIHostingController(rootView: NavigationStack {
            PhoneWorkspace(session: session, stage: PhoneCards(session: session), tasks: nil as EmptyView?,
                           composer: MessageComposer(session: session))
        }.environment(\.colorScheme, .dark))
        window.makeKeyAndVisible()

        // Every view in drawing order: a view earlier in the list is drawn under a later one.
        func drawn() -> [UIView] {
            var order: [UIView] = []
            func walk(_ view: UIView) { order.append(view); view.subviews.forEach(walk) }
            walk(window)
            return order
        }
        var deadline = PhoneWaitDeadline(20)
        while !drawn().contains(where: { $0 is PhoneSceneSurfaceView && $0.bounds.height > 0 }) {
            if deadline.expired() { XCTFail("Home never drew its crew scene"); return }
            try await Task.sleep(for: .seconds(PhoneWaitDeadline.tick))
        }
        let frames = DisplaySample(ticks: 2)
        let shown = await frames.complete(within: 20)
        frames.stop(); XCTAssertEqual(shown, .completed, "No frame was drawn after the scene appeared")

        let order = drawn()
        let surface = try XCTUnwrap(order.firstIndex { $0 is PhoneSceneSurfaceView })
        let drawing = order[surface].convert(order[surface].bounds, to: window).integral
        let stage = try XCTUnwrap(order.first { $0 is UIScrollView && $0.accessibilityIdentifier == "crew-scene" }
            ?? order.first { $0 is UIScrollView }, "Home has no crew stage")
        let middle = stage.convert(stage.bounds, to: window).integral
        let box = try XCTUnwrap(order.firstIndex { $0 is UITextView || $0 is UITextField }, "Home has no message box")

        XCTAssertLessThan(middle.height, window.bounds.height, "The stage is the middle space, short of the window")
        XCTAssertEqual(drawing, window.bounds.integral, "The crew scene is drawn across the whole window, not the stage alone")
        XCTAssertLessThan(surface, box, "The crew scene is drawn under the message box")
        XCTAssertFalse(order[surface].isUserInteractionEnabled, "The drawing takes no touch; the stage keeps it")
    }
}
