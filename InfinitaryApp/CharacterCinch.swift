import SwiftUI

/// INF-3011: the cinch the Mac's first mate plays while it shortens its conversation (src/renderer/src/character/cinch.ts).
/// A ring is drawn tight round the body, motes stream in to its centre, and at the end the body springs back with a lift
/// of light. Every number is the Mac's, generated into the catalog (`cinch`), so the two draw the same look.
/// Folding is a parameter over working, never a state: the machine never hears it.
struct CharacterFold: Sendable, Equatable {
    /// The first mate is shortening its conversation now.
    var folding = false
    /// Each shortening heard starting, so one heard starting and ending at once still plays.
    var starts = 0
}

enum CharacterCinch {
    static var settings: [String: Double] { CharacterCatalog.shared.cinch }
    private static func n(_ key: String) -> Double { settings[key]! }

    /// One frame of a cinch, as cinch.ts's `CinchFrame`; times in milliseconds since it began.
    struct Frame: Sendable, Equatable {
        enum Phase: String, Sendable { case `in`, hold, out }
        var phase: Phase
        var k, t, holdS, u, vis, lift, holdEnd: Double
    }

    private static func back(_ t: Double) -> Double {
        let c1 = 1.70158
        return 1 + (c1 + 1) * pow(t - 1, 3) + c1 * pow(t - 1, 2)
    }
    private static func pump(_ holdS: Double) -> Double { 0.5 - 0.5 * cos(2 * .pi * holdS / n("rhythmS")) }

    /// The cinch at `t` ms since it began; `endedAt` is when the shortening ended, or nil while it runs.
    static func frame(_ t: Double, endedAt: Double?) -> Frame? {
        guard t >= 0 else { return nil }
        let inMs = n("inMs"), outMs = n("outMs")
        let holdEnd = endedAt.map { max($0, inMs) } ?? .infinity
        if t < inMs {
            return Frame(phase: .in, k: easeInOut(t / inMs), t: t, holdS: 0, u: 0, vis: clamp01(t / (inMs * 0.3)), lift: 0, holdEnd: holdEnd)
        }
        if t < holdEnd {
            let holdS = (t - inMs) / 1000
            return Frame(phase: .hold, k: 1 - n("pump") * pump(holdS), t: t, holdS: holdS, u: 0, vis: 1, lift: 0, holdEnd: holdEnd)
        }
        let u = (t - holdEnd) / outMs
        guard u < 1 else { return nil }
        let holdS = (holdEnd - inMs) / 1000
        let k0 = 1 - n("pump") * pump(holdS)
        return Frame(phase: .out, k: k0 * (1 - back(u)), t: t, holdS: holdS, u: u, vis: 1 - easeInOut(u),
                     lift: sin(.pi * u) * n("release"), holdEnd: holdEnd)
    }

    /// Reduce Motion's still: the tight pose while the shortening runs.
    static func still(_ folding: Bool) -> Frame? {
        folding ? Frame(phase: .hold, k: 1, t: n("inMs"), holdS: 0, u: 0, vis: 1, lift: 0, holdEnd: .infinity) : nil
    }

    /// When the current cinch began and whether its shortening has ended, as cinch.ts's `CinchClock` (seconds in).
    struct Clock: Sendable {
        private var seen: Int
        private var at = -Double.infinity
        private var endedAt: Double? = 0
        init(starts: Int) { seen = starts }

        mutating func update(_ now: Double, _ fold: CharacterFold) {
            let ms = now * 1000
            if fold.starts != seen || (fold.folding && endedAt != nil) { seen = fold.starts; at = ms; endedAt = nil }
            if !fold.folding && endedAt == nil { endedAt = ms - at }
        }
        func frame(_ now: Double) -> Frame? { CharacterCinch.frame(now * 1000 - at, endedAt: endedAt) }
    }

    static func hash(_ slot: Double) -> Double {
        let x = sin(slot * 12.9898 + 78.233) * 43758.5453
        return x - floor(x)
    }

    struct Mote: Sendable, Equatable { var slot: Int; var u: Double }

    /// The motes in flight at a frame, and how bright the centre is from the ones just arrived.
    static func motes(_ frame: Frame) -> (motes: [Mote], arrival: Double) {
        var motes: [Mote] = [], arrival = 0.0
        let inMs = n("inMs"), moteInMs = n("moteInMs"), moteHoldMs = n("moteHoldMs"), arrivalMs = n("arrivalMs")
        let birthsEnd = min(frame.t, frame.holdEnd)
        func visit(_ slot: Int, _ born: Double) {
            let age = frame.t - born, life = n("moteLifeMs") + n("moteLifeSpread") * hash(Double(slot) + 0.5)
            if age < 0 { return }
            if age < life { motes.append(Mote(slot: slot, u: age / life)) } else { arrival = max(arrival, exp(-(age - life) / arrivalMs)) }
        }
        let reach = n("moteLifeMs") + n("moteLifeSpread") + arrivalMs * 3
        for j in 0..<Int((inMs / moteInMs).rounded(.up)) {
            let born = Double(j) * moteInMs
            if born > birthsEnd { break }
            if frame.t - born < reach { visit(j, born) }
        }
        if birthsEnd > inMs {
            var j = max(0, Int(floor((frame.t - reach - inMs) / moteHoldMs)))
            while true {
                let born = inMs + Double(j) * moteHoldMs
                if born > birthsEnd { break }
                visit(1000 + j, born); j += 1
            }
        }
        return (motes, arrival)
    }

    /// What the cinch asks of the body at tightness `k`.
    struct Body: Sendable { var scale, spin, lid, outer: Double; var look: (x: Double, y: Double) }
    static func body(_ k: Double) -> Body {
        let kz = clamp01(k)
        return Body(scale: 1 - (1 - n("tightness")) * k, spin: 1 - (1 - n("spinKeep")) * kz, lid: n("lid") * kz,
                    outer: 1 - n("outerDim") * kz, look: (0.12 * (1 - kz), 0.4 - 0.3 * kz))
    }
    static let rest = Body(scale: 1, spin: 1, lid: 0, outer: 1, look: (0.12, 0.4))

    private static let warm = CharacterPainter.RGB(255, 246, 230)

    /// The centre's fill and the ring, with its glint while it holds: under the wires.
    static func drawUnder(_ frame: Frame, k: Double, gate: Double, arrival: Double, still: Bool, c: Double, r0: Double, size: Double,
                          dim: CharacterPainter.RGB, bright: CharacterPainter.RGB, boost: Double, in context: inout ScenePen) {
        let kz = clamp01(k), vis = frame.vis * gate
        if vis <= 0.01 && kz <= 0.01 { return }
        let R = r0 * body(k).scale
        if kz > 0.01 {
            let fill = still ? 0.6 : 0.35 + 0.65 * arrival, cy = c - 0.04 * R
            context.fill(circle(c, cy, R * 0.5), with: .radialGradient(
                PenGradient(colors: [bright.mix(warm, 0.3).color(0.26 * kz * fill), bright.color(0)]),
                center: CGPoint(x: c, y: cy), startRadius: 0, endRadius: R * 0.5))
        }
        let grow = frame.phase == .out ? easeInOut(frame.u) * r0 * n("ringGrow") : 0
        let rr = r0 * (n("ringFrom") * (1 - kz) + n("ringTight") * n("tightness") * kz) + grow
        let sweep = frame.phase == .in ? clamp01(frame.t / (n("inMs") * n("throwShare"))) * 2 * .pi : 2 * .pi
        let s = size / 280
        context.stroke(arc(c, rr, -.pi / 2, -.pi / 2 + sweep), with: .color(dim.mix(bright, 0.6).color(min(1, 0.5 * vis * boost))),
                       style: StrokeStyle(lineWidth: 1.3 * s, lineCap: .round))
        if frame.phase == .hold && !still {
            let th = -.pi / 2 + 2 * .pi * frame.holdS / n("rhythmS"), glint = bright.mix(warm, 0.5)
            context.stroke(arc(c, rr, th - 0.35, th + 0.35), with: .color(glint.color(min(1, 0.12 * boost * gate))),
                           style: StrokeStyle(lineWidth: 6 * s, lineCap: .round))
            context.stroke(arc(c, rr, th - 0.3, th + 0.3), with: .color(glint.color(min(1, 0.95 * boost * gate))),
                           style: StrokeStyle(lineWidth: 2 * s, lineCap: .round))
        }
    }

    /// The motes streaming in to the centre from beyond the outer cell's corners: over the wires, under the eyes.
    static func drawOver(_ frame: Frame, motes: [Mote], k: Double, gate: Double, c: Double, r0: Double, size: Double,
                         corners: [CGPoint], bright: CharacterPainter.RGB, in context: inout ScenePen) {
        guard !motes.isEmpty, !corners.isEmpty else { return }
        let R = r0 * body(k).scale, ty = c - 0.04 * R, col = bright.mix(warm, 0.3), s = size / 280
        for m in motes {
            let P = corners[Int(floor(hash(Double(m.slot)) * Double(corners.count))) % corners.count]
            let dx = P.x - c, dy = P.y - c, d = max(hypot(dx, dy), 0.000001)
            let out = (d + r0 * 0.35) * (1 + 0.4 * hash(Double(m.slot) + 0.25))
            let x0 = c + dx / d * out, y0 = c + dy / d * out
            let u = pow(m.u, 1.6), u2 = pow(max(0, m.u - 0.1), 1.6)
            let fade = gate * frame.vis * (1 - u * 0.6)
            let x = x0 + (c - x0) * u, y = y0 + (ty - y0) * u
            var trail = Path()
            trail.move(to: CGPoint(x: x0 + (c - x0) * u2, y: y0 + (ty - y0) * u2)); trail.addLine(to: CGPoint(x: x, y: y))
            context.stroke(trail, with: .color(col.color(0.45 * fade)), style: StrokeStyle(lineWidth: 1 * s, lineCap: .round))
            context.fill(circle(x, y, 1.8 * s * (1 - 0.5 * u)), with: .color(col.color(0.9 * fade)))
        }
    }

    private static func circle(_ x: Double, _ y: Double, _ r: Double) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }
    private static func arc(_ c: Double, _ r: Double, _ from: Double, _ to: Double) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: c, y: c), radius: r, startAngle: .radians(from), endAngle: .radians(to), clockwise: false)
        return path
    }
}
