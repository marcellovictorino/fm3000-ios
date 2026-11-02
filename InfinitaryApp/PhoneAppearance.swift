import SwiftUI

/// The phone's own Dark/Light choice, kept on the phone and starting on Dark, the desktop's default.
/// It does not read the Mac's theme.
enum PhoneAppearance: String, CaseIterable, Identifiable {
    case dark, light

    static let storageKey = "phone.appearance"
    var id: String { rawValue }
    var title: String { self == .dark ? "Dark" : "Light" }
    var scheme: ColorScheme { self == .dark ? .dark : .light }
}
