import SwiftUI

/// INF-3106 direction B, the captain's picks: while the software keyboard is up for a field, a keyboard-down button sits
/// inside it, just before its send circle, on iPhone and iPad alike. Apple's iPhone keyboard has no hide key and no app
/// may add one, so the way out lives in the field, next to the words, where it takes none of the room left to read.
/// It is a neutral circle the size of send's, since send is the field's one accent, and it rides on send itself, so the
/// two share one center line however many lines the field grows to.
extension View {
    /// Draws the button before this send control while `shows`; `diameter` is the send circle's, or nil for the reply's
    /// large `arrow.up.circle.fill` symbol, and `height` the touch area send keeps.
    func hidesKeyboardBefore(_ shows: Bool, diameter: CGFloat? = nil, height: CGFloat = 44) -> some View {
        padding(.leading, shows ? 44 : 0)
            .overlay(alignment: .leading) {
                if shows { PhoneHideKeyboardButton(diameter: diameter, height: height) }
            }
    }
}

private struct PhoneHideKeyboardButton: View {
    let diameter: CGFloat?
    let height: CGFloat

    var body: some View {
        Button(action: dismissPhoneKeyboard) {
            circle.frame(width: 44, height: height).contentShape(Rectangle())
        }
        .accessibilityLabel("Hide keyboard")
        .accessibilityIdentifier("hide-keyboard")
    }

    @ViewBuilder private var circle: some View {
        let mark = Image(systemName: "keyboard.chevron.compact.down").foregroundStyle(PhoneTheme.secondary)
        if let diameter {
            mark.font(.system(size: 13, weight: .semibold))
                .frame(width: diameter, height: diameter).background(PhoneTheme.line, in: Circle())
        } else {
            Image(systemName: "circle.fill").imageScale(.large).foregroundStyle(PhoneTheme.line)
                .overlay { mark.font(.system(size: 11, weight: .semibold)) }
        }
    }
}
