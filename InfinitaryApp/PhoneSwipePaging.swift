import SwiftUI

/// Swiping the card left turns to the next card and right to the previous one, matching the pager's arrows.
/// The card follows the finger with a slight tilt, springs back on a short drag, and on a full one slides off while the
/// next card slides in from the other side. With Reduce Motion the card only fades out and the next fades in.
/// It runs beside other gestures and only moves for a clearly horizontal drag.
private struct PhoneSwipePaging: ViewModifier {
    let card: String
    let previous: (() -> Void)?
    let next: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragX: CGFloat = 0
    @State private var fade: Double = 1
    @State private var width: CGFloat = 390
    @State private var startCard: String?

    func body(content: Content) -> some View {
        content
            .offset(x: dragX)
            .rotationEffect(.degrees(Double(dragX / max(width, 1)) * 8), anchor: .bottom)
            .opacity(fade * (1 - min(abs(dragX) / max(width, 1), 1) * 0.5))
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .onChanged { drag in
                        if startCard == nil { startCard = card }
                        guard !reduceMotion else { return }
                        let dx = drag.translation.width, dy = drag.translation.height
                        if abs(dx) > abs(dy) * 1.5 {
                            // At either end of the stack the card gives a little and comes back.
                            dragX = (dx < 0 ? next : previous) == nil ? dx * 0.2 : dx
                        } else if dragX != 0 {
                            withAnimation(.interactiveSpring) { dragX = 0 }
                        }
                    }
                    .onEnded { drag in
                        defer { startCard = nil }
                        let dx = drag.translation.width, dy = drag.translation.height
                        let flung = abs(drag.predictedEndTranslation.width) > width / 2
                        let turn = dx < 0 ? next : previous
                        // The card head's own swipe may already have turned the card; then only the new one comes in.
                        if startCard != card { return enter(from: dx < 0 ? 1 : -1) }
                        guard let turn, abs(dx) > abs(dy) * 2, abs(dx) > 60 || flung else {
                            return withAnimation(.spring(duration: 0.3, bounce: 0.3)) { dragX = 0 }
                        }
                        leave(toward: dx < 0 ? -1 : 1, then: turn)
                    })
    }

    /// Slides (or fades) the card off toward `side` (-1 left, 1 right), turns the page, then brings the new card in.
    private func leave(toward side: CGFloat, then turn: @escaping () -> Void) {
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.15)) { fade = 0 } completion: {
                turn()
                withAnimation(.easeIn(duration: 0.15)) { fade = 1 }
            }
            return
        }
        withAnimation(.easeIn(duration: 0.18)) { dragX = side * width * 1.3 } completion: {
            turn()
            enter(from: -side)
        }
    }

    /// Places the new card a little past `side` and settles it in the centre, as a page push does.
    private func enter(from side: CGFloat) {
        if reduceMotion { return }
        var still = Transaction(); still.disablesAnimations = true
        withTransaction(still) { dragX = side * width * 0.35 }
        // The next run of the main queue starts the settle from the placed edge rather than the old card's exit.
        DispatchQueue.main.async { withAnimation(.spring(duration: 0.35, bounce: 0.15)) { dragX = 0 } }
    }
}

extension View {
    func phoneSwipePaging(card: String, previous: (() -> Void)?, next: (() -> Void)?) -> some View {
        modifier(PhoneSwipePaging(card: card, previous: previous, next: next))
    }
}
