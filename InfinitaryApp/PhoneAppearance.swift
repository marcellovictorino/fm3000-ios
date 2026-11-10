import InfinitaryKit
import SwiftUI
import UIKit

/// The captain's Approve and build on a theme of the phone's own (`PhoneLook`): the one owner of this device's choice.
/// A change is saved at once, so it survives a relaunch and an update, and it is never sent to the computer.
@MainActor @Observable final class PhoneAppearance {
    var look: PhoneLook { didSet { look.save() } }

    init() { look = PhoneLook.saved() }

    /// The next choice to the left (-1) or right (1) of the current one, kept at the ends, as a segmented control's
    /// arrows move.
    func step(by offset: Int) {
        let looks = PhoneLook.allCases
        guard let at = looks.firstIndex(of: look), looks.indices.contains(at + offset) else { return }
        look = looks[at + offset]
    }
}

extension PhoneLook {
    /// Device leaves the window to the system's own setting, so iOS's Automatic switching keeps working.
    var style: UIUserInterfaceStyle {
        switch self {
        case .device: .unspecified
        case .dark: .dark
        case .light: .light
        }
    }
}

/// Sets the style of the window it sits in. Sheets, the keyboard, card web views and the crew all read their appearance
/// from that window, so one setting changes every screen at once with no change to the shared colours or card code.
/// Each window of an iPad's several windows carries its own copy, so a new window starts in the chosen theme too.
struct PhoneWindowLook: UIViewRepresentable {
    let look: PhoneLook

    func makeUIView(context: Context) -> Marker {
        let view = Marker()
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        return view
    }

    func updateUIView(_ view: Marker, context: Context) { view.style = look.style }

    final class Marker: UIView {
        var style: UIUserInterfaceStyle = .unspecified { didSet { apply() } }
        override func didMoveToWindow() { super.didMoveToWindow(); apply() }
        private func apply() {
            guard let window, window.overrideUserInterfaceStyle != style else { return }
            window.overrideUserInterfaceStyle = style
        }
    }
}
