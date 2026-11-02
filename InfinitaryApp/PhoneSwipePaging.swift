import SwiftUI

/// Swiping the stage left turns to the next card and right to the previous one, matching the pager's arrows.
/// It runs beside other gestures and only counts a clearly horizontal, deliberate drag.
private struct PhoneSwipePaging: ViewModifier {
    let previous: (() -> Void)?
    let next: (() -> Void)?

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 30).onEnded { drag in
                let dx = drag.translation.width, dy = drag.translation.height
                guard abs(dx) > 60, abs(dx) > abs(dy) * 2 else { return }
                if dx < 0 { next?() } else { previous?() }
            })
    }
}

extension View {
    func phoneSwipePaging(previous: (() -> Void)?, next: (() -> Void)?) -> some View {
        modifier(PhoneSwipePaging(previous: previous, next: next))
    }
}
