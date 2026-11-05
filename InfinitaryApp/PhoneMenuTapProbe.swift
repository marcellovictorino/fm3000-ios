import InfinitaryKit
import Observation
import SwiftUI
import UIKit
import UIKit.UIGestureRecognizerSubclass

/// INF-2095: a tap on a card-pager menu item was lost, with the menu left open, when a reply notice cleared inside the
/// tap's 80 ms. The clear redrew the workspace, the redraw re-ran the pager's menu content, and UIKit then sometimes
/// rebuilt the open menu under the finger. The isolated phone gate's stand-in for that ordering, from INF-2095's lab
/// hook: each touch that begins on a menu item redraws the workspace a moment later (clearing a reply notice when one
/// shows), and every run of the pager's menu content between that redraw and the item's pick counts as a rebuild inside
/// the tap, which the journey reads from `menu-tap-probe`. Simulator builds with the gate's switch only.
@MainActor @Observable final class PhoneMenuTapProbe {
    static let shared: PhoneMenuTapProbe? = {
        #if targetEnvironment(simulator)
        let environment = ProcessInfo.processInfo.environment
        guard environment["INFINITARY_ISOLATED_PHONE_TEST"] == "1", environment["INFINITARY_TEST_MENU_TAP_REDRAW"] == "1" else { return nil }
        return PhoneMenuTapProbe()
        #else
        nil
        #endif
    }()

    /// Item touches that redrew the workspace, and the menu content runs that followed one before its pick.
    private(set) var taps = 0
    private(set) var rebuilds = 0
    private(set) var clears = 0
    /// Read by the workspace's body, so a change redraws the workspace and nothing else; a notice clear redraws it too.
    private(set) var redraws = 0
    @ObservationIgnored private var armed = false
    @ObservationIgnored private var session: ReadOnlySession?

    /// The pager's menu content ran.
    func menuBuilt() { if armed { rebuilds += 1 } }
    /// A pager menu item's action ran: the tap reached its pick.
    func picked() { armed = false }

    /// Watches every touch in the workspace's windows without taking part in their gestures.
    func install(_ session: ReadOnlySession) {
        self.session = session
        for scene in UIApplication.shared.connectedScenes {
            for window in (scene as? UIWindowScene)?.windows ?? [] where !(window.gestureRecognizers ?? []).contains(where: { $0 is Hook }) {
                window.addGestureRecognizer(Hook(probe: self))
            }
        }
    }

    fileprivate func itemTouched() {
        Task { @MainActor in
            // INF-2095's lab cleared the notice 10 ms into the tap; its lost picks saw the menu rebuilt 2 to 17 ms later.
            try? await Task.sleep(for: .milliseconds(10))
            taps += 1; armed = true
            if session?.notice != nil { session?.notice = nil; clears += 1 } else { redraws += 1 }
        }
    }

    /// Fails at once and cancels nothing, so the menu's own gestures run as they would without it.
    private final class Hook: UIGestureRecognizer, UIGestureRecognizerDelegate {
        weak var probe: PhoneMenuTapProbe?
        init(probe: PhoneMenuTapProbe) {
            self.probe = probe
            super.init(target: nil, action: nil)
            cancelsTouchesInView = false; delaysTouchesBegan = false; delaysTouchesEnded = false
            delegate = self
        }
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            var view = touches.first?.view
            var item = false
            while let next = view {
                if String(describing: type(of: next)).contains("ContextMenuCell") { item = true; break }
                view = next.superview
            }
            if item { probe?.itemTouched() }
            state = .failed
        }
        func gestureRecognizer(_ recognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}

/// The probe's counts as one accessibility element, for the journey to read.
struct PhoneMenuTapProbeReading: View {
    let probe: PhoneMenuTapProbe
    var body: some View {
        Color.clear.frame(width: 1, height: 1)
            .accessibilityElement().accessibilityIdentifier("menu-tap-probe")
            .accessibilityLabel("\(probe.taps) taps, \(probe.rebuilds) rebuilds, \(probe.clears) notice clears, \(probe.redraws) redraws")
            .allowsHitTesting(false)
    }
}
