import SwiftUI

/// Native Dynamic Type roles, using the design skill's vendored typefaces.
enum PhoneFont {
    static let body = Font.custom("SpaceGrotesk-Light", size: 17, relativeTo: .body).weight(.regular)
    static let title = Font.custom("SpaceGrotesk-Light", size: 22, relativeTo: .title2).weight(.semibold)
    static let headline = Font.custom("SpaceGrotesk-Light", size: 17, relativeTo: .headline).weight(.semibold)
    static let callout = Font.custom("SpaceGrotesk-Light", size: 16, relativeTo: .callout).weight(.regular)
    /// INF-1846's chosen 15 points, one step under the message box's words: the rows above the box.
    static let subheadline = Font.custom("SpaceGrotesk-Light", size: 15, relativeTo: .subheadline).weight(.regular)
    static let mono = Font.custom("JetBrainsMono-Regular", size: 12, relativeTo: .caption)
    static let caption = Font.custom("SpaceGrotesk-Light", size: 12, relativeTo: .caption).weight(.regular)
    static let display = Font.custom("SpaceGrotesk-Light", size: 28, relativeTo: .title).weight(.regular)
    static let data = Font.custom("JetBrainsMono-Regular", size: 12, relativeTo: .caption)
    static let micro = Font.custom("JetBrainsMono-Regular", size: 11, relativeTo: .caption2)
    /// INF-1926's chosen 14 points: the crew summary's words, one step under the rows above the message box.
    static let summary = Font.custom("SpaceGrotesk-Light", size: 14, relativeTo: .subheadline).weight(.regular)
    /// The crew summary's side labels and small words, at the desktop's 11.
    static let label = Font.custom("SpaceGrotesk-Light", size: 11, relativeTo: .caption2).weight(.regular)
}
