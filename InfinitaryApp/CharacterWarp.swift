import SwiftUI

/// The warp fidgets of character/warp.ts and crew/warp.ts on the Mac: the whole crew travelling at warp speed through
/// a wormhole, in all three of the prototype's treatments (captain, INF-1750: "add all 3 actually"). The settings, the
/// schedule, the travel table and the very stars come generated from the desktop owners; the shapes are ported here.
enum CharacterWarp {
    struct Data: Decodable, Sendable {
        let durationMs: Double
        let warpSpeed: Double
        let stars: Int
        let reachPx: Double
        let travelPerSecond: Double
        let releaseMs: Double
        let schedule: [String: Double]
        let lead: [String: Double]
        let travel: [Double]
        let head: [[Double]]
        let side: [[Double]]
        let inner: [[Double]]
    }
    static var data: Data { CharacterCatalog.shared.warp }
    typealias RGB = CharacterPainter.RGB
    private static let white = RGB(255, 246, 230)

    static func isWarp(_ variant: CharacterMachine.Fidget?) -> Bool { variant == .tunnel || variant == .sphere || variant == .corkscrew }

    /// The wind-up / cruise / exit envelope, 0..1.
    static func envelope(_ et: Double) -> Double {
        let s = data.schedule
        return band(et, s["inAt"]!, s["inFor"]!, s["outAt"]!, s["outFor"]!)
    }
    /// How fast the warp travels at `et`, 0..1: a short spool, then the jump, then the exit.
    static func speed(_ et: Double) -> Double {
        let s = data.schedule
        let spool = easeInOut(clamp01((et - s["inAt"]!) / 0.11)) * 0.16
        let jump = easeInOut(clamp01((et - s["jumpAt"]!) / 0.07))
        return (spool + 0.84 * jump) * (1 - easeInOut(clamp01((et - s["exitAt"]!) / 0.09)))
    }
    /// The distance the warp has covered by `et`, read from the desktop's own table.
    static func travel(_ et: Double) -> Double {
        let table = data.travel, steps = table.count - 1, f = clamp01(et) * Double(steps), i = Int(f)
        if i >= steps { return table[steps] }
        return table[i] + (table[i + 1] - table[i]) * (f - Double(i))
    }
    /// The crew's travel speed during a warp, times normal.
    static func crewTravel(_ variant: CharacterMachine.Fidget, _ speed: Double) -> Double {
        1 + (data.lead[variant.rawValue] ?? 0) * data.travelPerSecond * data.warpSpeed * speed
    }

    /// One warp this frame, as the Mac's WarpFrame.
    struct Frame {
        var variant: CharacterMachine.Fidget
        var et, k, sp, tv, t, coreR, heat: Double
    }
    static func frame(_ pose: CharacterPose, coreR: Double) -> Frame? {
        guard pose.mode == .fidget, let variant = pose.variant, isWarp(variant) else { return nil }
        let et = pose.progress
        return Frame(variant: variant, et: et, k: envelope(et), sp: speed(et), tv: travel(et), t: pose.milliseconds / 1000, coreR: coreR, heat: pose.heat)
    }

    /// The crew's side of the warp (the Mac's CrewWarp): a warp cut short lets the crew go home over the release.
    struct Ride {
        private var last: Frame?
        private var cutAt: Double?
        mutating func resolve(_ warp: Frame?, now: Double) -> Frame? {
            if let warp { last = warp; cutAt = nil; return warp }
            guard var held = last, held.et < 1 else { last = nil; return nil }
            let at = cutAt ?? now
            cutAt = at
            let release = 1 - easeInOut(clamp01((now - at) * 1000 / data.releaseMs))
            if release <= 0 { last = nil; cutAt = nil; return nil }
            held.k = envelope(held.et) * release; held.sp = speed(held.et) * release; held.t += now - at
            return held
        }
    }

    // MARK: the first mate's own pose

    struct Pose {
        var sa = 0.0, sb = 0.0, scale = 1.0, jitter = 0.0, lid = 0.0
        var look = (x: 0.0, y: 0.0)
        var glow = 1.0, sx = 1.0, sy = 1.0, rot = 0.0
    }
    static func pose(_ variant: CharacterMachine.Fidget, _ et: Double) -> Pose {
        let k = envelope(et), sp = speed(et)
        switch variant {
        case .tunnel:
            return Pose(sa: 0.55 * k, sb: 0.3 * k, scale: 1 - 0.07 * pulse(et, 0.03, 0.14) + 0.05 * pulse(et, 0.13, 0.12),
                        jitter: 0.025 * sp, lid: 0.3 * k, look: (0, 0.05), glow: 1 + 1.3 * k)
        case .sphere:
            return Pose(sa: 0.12 * k, glow: 1 + 0.86 * k)
        default:
            return Pose(sa: 0.35 * k, lid: 0.18 * k, look: (0.9, 0), glow: 1 + 1.14 * k, sx: 1 + 0.12 * sp, sy: 1 - 0.06 * sp, rot: 0.12 * k)
        }
    }
    static func pose(of pose: CharacterPose) -> Pose? {
        guard pose.mode == .fidget, let variant = pose.variant, isWarp(variant) else { return nil }
        return Self.pose(variant, pose.progress)
    }

    /// The sphere's radius: it opens, swells as the crew pass through, and closes.
    static func sphereRadius(_ et: Double, _ r: Double) -> Double {
        r * 1.12 * easeInOut(clamp01(envelope(et) * 1.4)) * (1 + 0.22 * pulse(et, 0.45, 0.13))
    }
    /// The sphere: vertex `index` takes its place on the rim, inner cell first, swirling in as the black hole's do.
    static func sphereVertex(_ index: Int, base: CGPoint, et: Double, c: Double, r: Double, time: Double) -> (point: CGPoint, progress: Double)? {
        let k = envelope(et)
        guard k > 0.001 else { return nil }
        let rank = Double(CharacterSky.winding.firstIndex(of: index) ?? 0), blend = easeInOut(clamp01(k * 1.6 - rank / 15 * 0.6))
        guard blend > 0 else { return nil }
        let turn = blend * 1.6, dx = base.x - c, dy = base.y - c
        let sx = c + dx * cos(turn) - dy * sin(turn), sy = c + dx * sin(turn) + dy * cos(turn)
        let angle = rank / 16 * 2 * .pi + time * 0.5, rs = sphereRadius(et, r)
        return (CGPoint(x: sx + (c + cos(angle) * rs * 1.02 - sx) * blend, y: sy + (c + sin(angle) * rs * 1.02 - sy) * blend), blend)
    }

    // MARK: drawing

    private static func shade(_ color: RGB, _ alpha: Double) -> GraphicsContext.Shading { .color(color.color(max(0, min(1, alpha)))) }
    private static func line(_ points: [CGPoint]) -> Path {
        Path { p in for (i, at) in points.enumerated() { if i == 0 { p.move(to: at) } else { p.addLine(to: at) } } }
    }
    private static func ring(_ x: Double, _ y: Double, _ r: Double) -> Path { Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)) }
    private static var reach: Double { data.reachPx }
    /// Everything fades before the crew square's edge.
    private static func vignette(_ r: Double) -> Double { 1 - easeInOut(clamp01((r - reach * 0.62) / (reach * 0.38))) }

    private struct Backdrop {
        let w: Frame
        let cx, cy: Double
        let col: RGB
        let boost: Double
        func calm(_ r: Double) -> Double { 0.15 + 0.85 * easeInOut(clamp01((r - w.coreR * 0.85) / (w.coreR * 1.1))) }
    }

    /// Stars rushing toward the viewer, head-on; a sphere's lens pushes them out past its rim.
    private static func starsHead(_ b: Backdrop, lens: Double, in context: inout GraphicsContext) {
        let w = b.w, f = 83.0, tail = 0.008 + 0.11 * w.sp * min(1.6, data.warpSpeed)
        func bend(_ x: Double, _ y: Double) -> CGPoint {
            guard lens > 0.5 else { return CGPoint(x: x, y: y) }
            let r = max(hypot(x, y), 1e-6), th = (r + (r * r + 4 * lens * lens).squareRoot()) / 2
            return CGPoint(x: x / r * th, y: y / r * th)
        }
        for s in data.head.prefix(data.stars) {
            var z = (s[2] - w.tv).truncatingRemainder(dividingBy: 1)
            if z < 0 { z += 1 }
            z = max(z, 0.025)
            let zt = min(1, z + tail), zm = (z + zt) / 2
            let h = bend(s[0] / z * f, s[1] / z * f), m = bend(s[0] / zm * f, s[1] / zm * f), t = bend(s[0] / zt * f, s[1] / zt * f)
            let r = hypot(h.x, h.y)
            if r > reach { continue }
            let near = 1 - z
            let a = w.k * clamp01(near * 1.8) * vignette(r) * b.calm(r) * (0.3 + 0.7 * near) * b.boost
            if a < 0.01 { continue }
            context.stroke(line([CGPoint(x: b.cx + t.x, y: b.cy + t.y), CGPoint(x: b.cx + m.x, y: b.cy + m.y), CGPoint(x: b.cx + h.x, y: b.cy + h.y)]),
                           with: shade(b.col.mix(white, 0.2 + 0.5 * near), a), style: StrokeStyle(lineWidth: 0.6 + 1.3 * near, lineCap: .round))
        }
    }

    /// The tunnel, head-on: a glow at its far end, six ribs twisting down its walls, rings pouring out.
    private static func tunnel(_ b: Backdrop, in context: inout GraphicsContext) {
        let w = b.w, k = w.k, rt = 67.0, z0 = w.tv * 0.5
        func off(_ z: Double) -> CGPoint {
            let m = pow(z, 1.6) * 29 * k
            return CGPoint(x: cos(w.t * 0.55) * m, y: sin(w.t * 0.43 + 1) * m)
        }
        let o = off(1), far = CGPoint(x: b.cx + o.x, y: b.cy + o.y)
        context.fill(Path(CGRect(x: far.x - 80, y: far.y - 80, width: 160, height: 160)), with: .radialGradient(
            Gradient(colors: [b.col.mix(white, 0.6).color(clamp01(0.26 * k * b.boost)), b.col.color(0)]), center: far, startRadius: 0, endRadius: 69))
        let rib = StrokeStyle(lineWidth: 0.8, lineCap: .round)
        for m in 0..<6 {
            var previous = CGPoint.zero
            for s in 0...18 {
                let z = 1 - Double(s) / 18 * 0.8, r = rt / z, q = off(z), angle = Double(m) / 6 * 2 * .pi + (z + z0) * 2.4
                let at = CGPoint(x: b.cx + q.x + cos(angle) * r, y: b.cy + q.y + sin(angle) * r)
                if s > 0 { context.stroke(line([previous, at]), with: shade(b.col, 0.2 * k * vignette(r) * clamp01((1 - z) * 3) * b.boost), style: rib) }
                previous = at
            }
        }
        let rings = 11
        for j in 0..<rings {
            var z = (Double(j) / Double(rings) - z0).truncatingRemainder(dividingBy: 1)
            if z < 0 { z += 1 }
            if z < 0.2 { continue }
            let r = rt / z, q = off(z)
            context.stroke(ring(b.cx + q.x, b.cy + q.y, r), with: shade(b.col.mix(white, 0.25 * (1 - z)), k * clamp01((1 - z) * 2.5) * vignette(r) * 0.6 * b.boost),
                           lineWidth: 0.7 + 1.2 * (1 - z))
        }
        starsHead(b, lens: 0, in: &context)
    }

    /// The hourglass wormhole's half-height at `x` px from the first mate.
    static func tubeRadius(_ x: Double, _ r: Double) -> Double { ((r * 1.3) * (r * 1.3) + 0.72 * x * x).squareRoot() }
    private static let span = 560.0, q = 0.3
    private static func endFade(_ x: Double) -> Double { pow(sin(.pi * clamp01((x + span / 2) / span)), 1.8) }

    /// The corkscrew's wormhole, side-on: streaming stars, its silhouette, twisting stripes and rings through the throat.
    private static func tube(_ b: Backdrop, in context: inout GraphicsContext) {
        let w = b.w, k = w.k, r0 = w.coreR, stretch = min(1.6, data.warpSpeed)
        for s in data.side {
            let d = s[2]
            var x = (s[0] * reach - w.tv * 347 * d).truncatingRemainder(dividingBy: 2 * reach)
            if x < -reach { x += 2 * reach }
            if x > reach { x -= 2 * reach }
            let y = s[1] * reach * 0.92, r = hypot(x, y)
            let a = k * (0.2 + 0.6 * d) * vignette(r) * b.calm(r) * b.boost * 0.8
            if a < 0.01 { continue }
            context.stroke(line([CGPoint(x: b.cx + x, y: b.cy + y), CGPoint(x: b.cx + x + 4 + w.sp * 83 * d * stretch, y: b.cy + y)]),
                           with: shade(b.col.mix(white, 0.2 + 0.4 * d), a), style: StrokeStyle(lineWidth: 0.5 + 1.1 * d, lineCap: .round))
        }
        let sc = w.tv * 267
        for sign in [-1.0, 1.0] {
            for s in 0..<42 {
                let x1 = -span / 2 + Double(s) / 42 * span, x2 = x1 + span / 42
                context.stroke(line([CGPoint(x: b.cx + x1, y: b.cy + sign * tubeRadius(x1, r0)), CGPoint(x: b.cx + x2, y: b.cy + sign * tubeRadius(x2, r0))]),
                               with: shade(b.col, 0.42 * k * endFade((x1 + x2) / 2) * b.boost), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
            }
        }
        let stripe = StrokeStyle(lineWidth: 0.8, lineCap: .round)
        for m in 0..<6 {
            var previous = CGPoint.zero
            for s in 0...40 {
                let x = -span / 2 + Double(s) / 40 * span, r = tubeRadius(x, r0), ph = Double(m) / 6 * 2 * .pi + (x - sc) * 0.00825
                let at = CGPoint(x: b.cx + x + q * r * sin(ph), y: b.cy - r * cos(ph))
                if s > 0 { context.stroke(line([previous, at]), with: shade(b.col, 0.15 * k * endFade(x) * (sin(ph) > 0 ? 1 : 0.45) * b.boost), style: stripe) }
                previous = at
            }
        }
        let rings = 10, gap = span / Double(rings)
        for j in 0..<rings {
            let x = ((Double(j) * gap - sc).truncatingRemainder(dividingBy: span) + span).truncatingRemainder(dividingBy: span) - span / 2
            let r = tubeRadius(x, r0), a = k * endFade(x) * 0.5 * b.boost, width = 0.7 + 0.6 * endFade(x)
            func half(_ from: Double) -> Path { CharacterSky.path(16) { v in let t = from + v * .pi; return CGPoint(x: b.cx + x + q * r * cos(t), y: b.cy + r * sin(t)) } }
            context.stroke(half(.pi / 2), with: shade(b.col, a * 0.5), lineWidth: width)
            context.stroke(half(-.pi / 2), with: shade(b.col.mix(white, 0.2), a), lineWidth: width)
        }
    }

    /// The corkscrew's place `s` along its spiral for `n` riders, in the desktop's pixels from the first mate.
    static func helix(_ s: Double, _ n: Int, _ w: Frame) -> (x: Double, y: Double, z: Double) {
        let count = Double(max(n, 1)), gap = min(35, 253 / count), x = -(64 + gap * s)
        let rho = tubeRadius(x, w.coreR) * 0.62, ph = w.tv * 2.2 + w.t * 0.8 - s * min(0.78, 9 / count)
        return (x + q * rho * sin(ph), -rho * cos(ph), sin(ph))
    }

    /// The backdrop, under every crewmate: the wormhole and its stars, the corkscrew's faint track, and the jump and exit rings.
    /// `scale` is the phone's share of the desktop's orbits, which the crew's own moves use.
    static func drawBackdrop(_ w: Frame, at center: CGPoint, riders: Int, scale: Double, palette: CharacterPainter.Palette, in context: inout GraphicsContext) {
        guard w.k > 0.001 else { return }
        let col = palette.acc.mix(palette.hot, w.heat)
        let b = Backdrop(w: w, cx: center.x, cy: center.y, col: col, boost: palette.boost)
        switch w.variant {
        case .tunnel: tunnel(b, in: &context)
        case .sphere: starsHead(b, lens: sphereRadius(w.et, w.coreR), in: &context)
        default:
            tube(b, in: &context)
            if riders > 0 {
                var previous = helix(-0.6, riders, w)
                for s in -4...((riders - 1) * 8 + 4) {
                    let h = helix(Double(s) / 8, riders, w)
                    context.stroke(line([CGPoint(x: b.cx + previous.x * scale, y: b.cy + previous.y * scale), CGPoint(x: b.cx + h.x * scale, y: b.cy + h.y * scale)]),
                                   with: shade(col, (0.12 + 0.24 * (h.z + 1) / 2) * w.k * w.k * palette.boost), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
                    previous = h
                }
            }
        }
        let s = data.schedule
        for (at, length) in [(s["jumpAt"]! - 0.005, 0.1), (s["exitAt"]! - 0.005, 0.11)] {
            let u = (w.et - at) / length
            if u <= 0 || u >= 1 { continue }
            context.stroke(ring(b.cx, b.cy, w.coreR + (reach * 0.95 - w.coreR) * easeInOut(u)), with: shade(col.mix(white, 0.5), 0.55 * (1 - u) * palette.boost), lineWidth: 1.4)
        }
    }

    /// The sphere itself, under the first mate's wires: the background swallowing what is inside, the far side's
    /// stars bent into arcs toward the rim, and a bright rim that flares as the crew pass through.
    static func drawSphere(_ et: Double, c: Double, r: Double, time: Double, bright: RGB, background: RGB, boost: Double, in context: inout GraphicsContext) {
        let k = envelope(et), rs = sphereRadius(et, r)
        guard rs >= 0.5 else { return }
        let disc = ring(c, c, rs), center = CGPoint(x: c, y: c)
        context.fill(disc, with: shade(background, 0.95 * clamp01(k * 1.5)))
        context.fill(disc, with: .radialGradient(Gradient(colors: [bright.mix(white, 0.4).color(0.13 * k), bright.color(0.03 * k)]), center: center, startRadius: 0, endRadius: rs))
        let swirl = time * 0.22 + 5 * easeInOut(clamp01((et - 0.44) / 0.14)), far = bright.mix(white, 0.55)
        for star in data.inner {
            let u = star[0], rho = rs * (0.1 + 0.86 * pow(u, 0.55)), length = 0.03 + 0.55 * pow(u, 5), angle = star[1] + swirl * (1.25 - u * 0.5)
            let arc = CharacterSky.path(8) { v in CGPoint(x: c + cos(angle + v * length) * rho, y: c + sin(angle + v * length) * rho) }
            context.stroke(arc, with: shade(far, k * star[2] * 0.8 * (0.35 + 0.65 * u) * boost), style: StrokeStyle(lineWidth: 0.6 + 0.9 * star[2], lineCap: .round))
        }
        let through = pulse(et, 0.45, 0.13)
        context.stroke(disc, with: shade(bright.mix(white, 0.4), (0.12 + 0.2 * through) * k * boost), lineWidth: 7)
        context.stroke(disc, with: shade(bright.mix(white, 0.55 + 0.35 * through), 0.85 * k * boost), lineWidth: 1.4)
    }

    // MARK: the crew

    /// Points in a rider's light trail.
    private static let trailPoints = 6

    /// Move one orbiting crewmate for the warp, after the orbit placed it: `index` is its place among the `count`
    /// riders and `at` its point from the first mate's center. The desktop's pixel moves are drawn at `scale`.
    /// Every move is scaled by the envelope, so at its end each crewmate is back on its seat.
    static func ride(_ g: inout PhoneSceneMotion.Glyph, index: Int, count: Int, around center: CGPoint, w: Frame, scale: Double) {
        let k = w.k, sp = w.sp, et = w.et
        guard k > 0.001 else { return }
        var x = g.point.x - center.x, y = g.point.y - center.y
        func trail(_ dx: Double, _ dy: Double, _ length: Double) {
            guard length >= 1 else { return }
            g.streak = (0..<trailPoints).map { i in
                let s = Double(i) / Double(trailPoints - 1) * length
                return CGPoint(x: center.x + x + dx * s, y: center.y + y + dy * s)
            }
        }
        defer { g.point = CGPoint(x: center.x + x, y: center.y + y) }
        switch w.variant {
        case .tunnel:
            let seed = Double(index) * 1.37
            x += CharacterSky.twinkle(w.t * 0.5 * 14 + seed * 3.1) * 2.9 * sp * scale
            y += CharacterSky.twinkle(w.t * 0.5 * 13 + seed * 5.7) * 2.9 * sp * scale
            if k > 0.5 { g.depth = 0.5 + abs(g.depth - 0.5) }
            let d = max(hypot(x, y), 1)
            trail(x / d, y / d, 21 * sp * scale)
        case .corkscrew:
            let ki = easeInOut(clamp01(k * 1.7 - Double(index) / Double(max(count, 1)) * 0.7))
            guard ki > 0 else { return }
            let h = helix(Double(index), count, w)
            x += (h.x * scale - x) * ki; y += (h.y * scale - y) * ki
            g.depth += ((h.z + 1) / 2 - g.depth) * ki
            g.scale *= 1 + 0.25 * h.z * ki
            g.alpha *= 1 - 0.4 * ki * clamp01(-h.z)
            trail(-1, 0, 19 * sp * ki * scale)
        default:
            // The sphere: in one after another, then out one after another.
            let n = Double(max(1, count - 1)), dive = 0.11
            let t0 = 0.17 + 0.22 * Double(index) / n, t1 = 0.56 + 0.2 * Double(index) / n
            guard et >= t0 else { return }
            let r0 = hypot(x, y), a0 = atan2(y, x), rs = max(sphereRadius(et, w.coreR), 1), going = et < t1
            let u = clamp01((et - (going ? t0 : t1)) / dive)
            if going && u >= 1 { g.alpha = 0; return }
            if !going && u >= 1 { return }
            // Each spirals in toward the centre, a little more than a quarter turn, then out the same way.
            let turn = 1.8
            func place(_ e: Double) -> (x: Double, y: Double, r: Double) {
                let rr = r0 * (going ? 1 - e : e), aa = a0 + turn * (going ? e : e - 1)
                return (cos(aa) * rr, sin(aa) * rr, rr)
            }
            let at = place(easeInOut(u)), inside = clamp01(1 - at.r / rs)
            x = at.x; y = at.y
            g.depth = 1
            g.scale *= 1 - 0.8 * inside
            g.alpha *= !going && u <= 0 ? 0 : 1 - inside * 0.85
            g.streak = (0..<trailPoints).map { i in
                let p = place(easeInOut(clamp01(u - Double(i) * 0.035)))
                return CGPoint(x: center.x + p.x, y: center.y + p.y)
            }
        }
    }
}
