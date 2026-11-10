import Foundation

/// The captain's Approve and build on a theme of the phone's own: Infinitary on iPhone and iPad keeps its Theme on the
/// device, apart from the computer's, and offers to match the device, Dark or Light. The choice is saved in this app's
/// own defaults, never in the connection file, so Leave, Forget, Removed and joining another computer keep it, and it
/// never reaches the computer. Nothing saved, or a value this version does not know, reads as matching the device.
public enum PhoneLook: String, CaseIterable, Sendable {
    case device, dark, light

    /// The words on the segmented control, as short as the computer's Dark and Light pills.
    public var words: String {
        switch self {
        case .device: "Device"
        case .dark: "Dark"
        case .light: "Light"
        }
    }

    static let key = "phone-theme"

    public static func saved(in defaults: UserDefaults = .standard) -> PhoneLook {
        defaults.string(forKey: key).flatMap(PhoneLook.init(rawValue:)) ?? .device
    }

    public func save(in defaults: UserDefaults = .standard) {
        defaults.set(rawValue, forKey: Self.key)
    }
}
