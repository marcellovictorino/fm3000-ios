import InfinitaryKit
import SwiftUI
import UIKit
import UIKit.UIGestureRecognizerSubclass
@preconcurrency import WebKit

/// INF-3110, the captain's "Row with a lean": the cards sit side by side, the next and previous cards' edges show at
/// the shown card's sides, and a sideways swipe anywhere on the card, outside the body's own controls, moves the row.
/// The numbers are the ones the captain submitted with the plan.
enum PhoneCardRowMotion {
    /// The room between two cards, and so how much of a neighbour's edge shows in the stage's side margin.
    static let gap = PhoneTheme.space2
    /// The first points a finger travels decide whether it swipes or scrolls, and move nothing.
    static let decide: CGFloat = 10
    /// A swipe travels at least this many times as far sideways as up or down; otherwise the card scrolls.
    static let sideways: CGFloat = 1.5
    /// A finger that rests this long before it moves is selecting text, never swiping.
    static let rest: TimeInterval = 0.5
    /// Letting go past this share of the card's width slides on.
    static let slideOn: CGFloat = 0.35
    /// Or letting go faster than this, in points a second, toward the next card.
    static let flick: CGFloat = 500
    /// The lean at the slide-on point, in degrees, which keeps growing a little past it.
    static let lean = 3.0
    static let leanReach: CGFloat = 1.4
    /// With no card that way the row moves this share of the finger's travel, then glides back.
    static let endGives: CGFloat = 0.3
    /// Under Reduce Motion the row stays still and the card dims this much at the slide-on point.
    static let dim = 0.45
    /// The chevron toward a side with no card shows this share as bright.
    static let hintAtEnd = 0.35

    /// The app's glide (--ease-out) over a share of a card's page time (--dur-page), never overshooting.
    static func glide(_ share: CGFloat) -> Animation {
        let (a, b, c, d) = PhoneTheme.glide
        return .timingCurve(a, b, c, d, duration: PhoneTheme.pageSeconds * Double(share))
    }

    /// The one fade Reduce Motion keeps (--dur-fade).
    static var fade: Animation {
        let (a, b, c, d) = PhoneTheme.glide
        return .timingCurve(a, b, c, d, duration: PhoneTheme.fadeSeconds)
    }
}

/// Where the row stands. Only the small modifiers below read it, so a finger's every move redraws them and not the cards.
@MainActor @Observable final class PhoneCardRow {
    /// How far the row has moved sideways from the shown card's place.
    var offset: CGFloat = 0
    var lean = 0.0
    /// Under Reduce Motion: how far the shown card has dimmed, the side the finger heads to, and that side's chevron.
    var dim = 0.0
    var heading = 1
    var hint = 0.0
    /// The row fading in under Reduce Motion after a page turn.
    var fade = 1.0
    /// The shown card's width, which is also one step of the row less the gap.
    var width: CGFloat = 0
    /// The shown card's height, which the plain edges beside it take while the row is still.
    var height: CGFloat = 0

    func settle() { offset = 0; lean = 0; dim = 0; hint = 0; fade = 1 }
}

struct PhoneCardRowSlot: Identifiable {
    let card: PhoneCard
    /// The card's place in the row: 0 is shown, -1 before it, 1 after it.
    let slot: Int
    /// A card beside the shown one is built only while the row moves; while it is still, its edge is a plain surface.
    var built = true
    /// A revision builds the card's pane again to draw its new body (INF-2565), so its offer is part of who it is.
    var id: String { "\(built ? "" : "edge:")\(card.id):\(card.offerID ?? card.body):\(card.isPast)" }
}

/// The edge of a card beside the shown one while the row is still: only its surface, which is all its 8 points show.
/// Accessibility searches see through a hidden view, so a card is built beside the shown one only while the row moves.
struct PhoneCardRowEdge: View {
    let row: PhoneCardRow

    var body: some View {
        // Never taller than the room the stage offers, so with the keyboard up it never pushes the message box under it.
        Color.clear.frame(maxWidth: .infinity, minHeight: 0, maxHeight: max(row.height, 1)).phoneCardSurface()
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// A card's place in the row: one step to each side per slot, moved with the row. A card beside the shown one is drawn
/// but takes no touches and stays out of accessibility.
struct PhoneCardRowPlace: ViewModifier {
    let row: PhoneCardRow
    let slot: Int

    func body(content: Content) -> some View {
        let shown = slot == 0
        content
            .offset(x: CGFloat(slot) * (row.width + PhoneCardRowMotion.gap) + row.offset)
            .opacity((shown ? 1 - row.dim : 1) * row.fade)
            .allowsHitTesting(shown)
            .accessibilityHidden(!shown)
            .zIndex(shown ? 1 : 0)
    }
}

/// Every card leans by the row's angle about its own foot.
struct PhoneCardRowLean: ViewModifier {
    let row: PhoneCardRow

    func body(content: Content) -> some View {
        content.rotationEffect(.degrees(row.lean), anchor: .bottom)
    }
}

/// Under Reduce Motion the row stays still, and a chevron at the side the finger heads to brightens as it nears the
/// slide-on point.
struct PhoneCardRowHint: View {
    let row: PhoneCardRow

    var body: some View {
        // The chevron is drawn only while it shows, so accessibility never finds a second Forward beside the pager's.
        if row.hint > 0 {
            Image(systemName: row.heading > 0 ? "chevron.right" : "chevron.left")
                .font(.system(size: 20, weight: .semibold)).foregroundStyle(PhoneTheme.secondary)
                .padding(PhoneTheme.space3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: row.heading > 0 ? .trailing : .leading)
                .opacity(row.hint)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
    }
}

/// The row shows its neighbours only in the room between the card and the screen's edge, and never cuts the card's
/// shadow above or below.
struct PhoneCardRowClip: Shape {
    let room: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(rect.insetBy(dx: -room, dy: -max(rect.width, rect.height)))
    }
}

/// The row's swipe: a one-finger pan anywhere on the shown card that leaves the body's own controls their drags, waits
/// out a rest that selects text, and lets an upward or downward drag scroll the card.
struct PhoneCardSwipe: UIGestureRecognizerRepresentable {
    let allowed: () -> Bool
    let began: () -> Void
    let moved: (CGFloat) -> Void
    /// Where the finger let go and how fast it moved; no speed when the swipe was cancelled.
    let ended: (CGFloat, CGFloat?) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> PhoneCardPan {
        let pan = PhoneCardPan()
        // Two fingers never page, so a pinch stays a pinch.
        pan.maximumNumberOfTouches = 1
        pan.delegate = context.coordinator
        context.coordinator.allowed = allowed
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: PhoneCardPan, context: Context) {
        context.coordinator.allowed = allowed
    }

    func handleUIGestureRecognizerAction(_ recognizer: PhoneCardPan, context: Context) {
        let dx = recognizer.translation(in: recognizer.view).x
        switch recognizer.state {
        case .began: began(); moved(dx)
        case .changed: moved(dx)
        case .ended: ended(dx, recognizer.velocity(in: recognizer.view).x)
        case .cancelled, .failed: ended(dx, nil)
        default: break
        }
    }

    @MainActor final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var allowed: () -> Bool = { false }

        /// A touch that lands on one of the body's own sideways controls stays the body's.
        func gestureRecognizer(_ recognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var view = touch.view
            while let at = view {
                if let body = at as? CardBodyView { return !body.claims(touch.location(in: body)) }
                view = at.superview
            }
            return true
        }

        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard allowed(), let pan = recognizer as? PhoneCardPan, pan.numberOfTouches <= 1,
                  pan.rested < PhoneCardRowMotion.rest else { return false }
            var travel = pan.translation(in: pan.view)
            if travel == .zero { travel = pan.velocity(in: pan.view) }
            return abs(travel.x) >= PhoneCardRowMotion.sideways * abs(travel.y) && travel.x != 0
        }

        /// A card's scroller waits the moment it takes the swipe to decide, so a sideways swipe never also scrolls it and
        /// an upward or downward one is the scroller's alone.
        func gestureRecognizer(_ recognizer: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
            (other.view as? UIScrollView)?.panGestureRecognizer === other
        }

        /// No other touch handling on the card takes a swipe from the row: on an iPad a web view's own recognizers, and the
        /// card's pull that puts the keyboard away, recognized a sideways drag first, and the row's swipe then never began.
        /// The body's own controls stay its own through the claims above, and a scroller still waits for the swipe to decide.
        func gestureRecognizer(_ recognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            (other.view as? UIScrollView)?.panGestureRecognizer !== other
        }
    }
}

/// The row's pan, which keeps how long the finger rested before it moved, read from the touches' own times: measured
/// against the clock when the swipe decides, a busy moment, such as a card body drawing, counted as a rest.
final class PhoneCardPan: UIPanGestureRecognizer {
    private var landed: TimeInterval = 0
    private var at: CGPoint = .zero
    private var moved: TimeInterval?

    /// How long the finger rested where it landed before it moved past the points that decide a swipe; a finger's
    /// tremble within them is still a rest.
    var rested: TimeInterval { (moved ?? landed) - landed }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .possible, let touch = touches.first { landed = touch.timestamp; at = touch.location(in: nil); moved = nil }
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if moved == nil, let touch = touches.first {
            let now = touch.location(in: nil)
            if hypot(now.x - at.x, now.y - at.y) >= PhoneCardRowMotion.decide { moved = touch.timestamp }
        }
        super.touchesMoved(touches, with: event)
    }
}

/// INF-3110: the body tells the app where its own sideways controls sit - a slider, a canvas or anything a script drags,
/// and anything that scrolls sideways - so a swipe starting there stays the body's. The script runs in every frame of the
/// card's page in a world of its own, which the body's scripts cannot see, and it reports only rectangles.
@MainActor enum CardClaims {
    static let world = WKContentWorld.world(name: "card-claims")
    static let handler = "cardClaims"

    static let script = WKUserScript(source: """
    (() => {
      if (window === window.top) return;
      const pans = (value) => value !== "auto" && value !== "manipulation" && !value.includes("pan-x");
      const grabs = new Set(["grab", "grabbing", "move", "ew-resize", "col-resize", "e-resize", "w-resize"]);
      let queued = false, last = "";
      const measure = () => {
        queued = false;
        const claims = [];
        for (const element of document.querySelectorAll("body *")) {
          const style = getComputedStyle(element);
          const scrolls = (style.overflowX === "auto" || style.overflowX === "scroll") && element.scrollWidth > element.clientWidth + 1;
          const own = element.localName === "canvas" || (element.localName === "input" && element.type === "range")
            || element.getAttribute("draggable") === "true" || pans(style.touchAction) || grabs.has(style.cursor) || scrolls;
          if (!own) continue;
          const box = element.getBoundingClientRect();
          if (box.width > 0 && box.height > 0) claims.push([box.left, box.top, box.width, box.height].map(Math.round));
        }
        const said = JSON.stringify(claims);
        if (said === last) return;
        last = said;
        try { window.webkit.messageHandlers.\(handler).postMessage(claims); } catch {}
      };
      const queue = () => { if (!queued) { queued = true; requestAnimationFrame(measure); } };
      new MutationObserver(queue).observe(document, { subtree: true, childList: true, attributes: true, characterData: true });
      new ResizeObserver(queue).observe(document.documentElement);
      addEventListener("load", queue);
      queue();
    })();
    """, injectionTime: .atDocumentEnd, forMainFrameOnly: false, in: world)
}

/// Keeps the claims a card's body frame reported on its view; only a child frame's report counts.
@MainActor final class CardClaimsReader: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard !message.frameInfo.isMainFrame, let body = message.webView as? CardBodyView,
              let list = message.body as? [[NSNumber]] else { return }
        body.claimed = list.compactMap { box in
            box.count == 4 ? CGRect(x: box[0].doubleValue, y: box[1].doubleValue, width: box[2].doubleValue, height: box[3].doubleValue) : nil
        }
    }
}
