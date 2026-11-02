import Foundation

func easeInOut(_ x: Double) -> Double { x * x * (3 - 2 * x) }
func easeOut(_ x: Double) -> Double { 1 - pow(1 - x, 2) }

/// Native port of replies.ts. Desktop-generated traces exercise all five clips, including their gaze.
struct CharacterReply: Decodable {
    struct Gaze: Decodable { var x, y: Double }
    var pitch = 0.0, spin = 0.0, rot = 0.0, tx = 0.0, ty = 0.0, sx = 1.0, sy = 1.0
    var gaze: Gaze?
    var pointer = true, suppressBlink = false
    var lid = 0.0, happy = 0.0, glow = 0.0
    static func saluteSnap(_ t: Double) -> Double {
        let u = clamp01((t - 0.2) / 0.24) - 1
        return 1 + 2.9 * u * u * u + 1.9 * u * u
    }
    static let tickPoints: [CGPoint] = [CGPoint(x: 0.9, y: 0.7312), CGPoint(x: 1.0584, y: 0.8984), CGPoint(x: 1.384, y: 0.5112)]
    static let tickFirst = hypot(tickPoints[1].x - tickPoints[0].x, tickPoints[1].y - tickPoints[0].y)
    static let tickTotal = tickFirst + hypot(tickPoints[2].x - tickPoints[1].x, tickPoints[2].y - tickPoints[1].y)
    static func alongTick(_ progress: Double) -> CGPoint {
        let d = progress * tickTotal, first = d <= tickFirst
        let a = tickPoints[first ? 0 : 1], b = tickPoints[first ? 1 : 2]
        let k = first ? d / tickFirst : (d - tickFirst) / (tickTotal - tickFirst)
        return CGPoint(x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k)
    }
    static func tickDrawn(_ t: Double) -> Double { easeInOut(clamp01((t - 0.17) / 0.26)) }
    static func tickPen(_ t: Double) -> CGPoint? {
        guard t >= 0.06 && t <= 0.47 else { return nil }
        if t >= 0.17 { return alongTick(tickDrawn(t)) }
        let k = easeInOut(clamp01((t - 0.06) / 0.11)), a = tickPoints[0]
        return CGPoint(x: a.x * k, y: -0.1 + (a.y + 0.1) * k + sin(k * .pi) * 0.12)
    }
    struct Dot { let x, y, alpha, r: Double }
    static func tuckDot(_ t: Double) -> Dot? {
        guard t >= 0.04 && t < 0.58 else { return nil }
        if t < 0.36 {
            let rise = easeOut(clamp01((t - 0.04) / 0.12))
            return Dot(x: 0.58, y: -1.18 + (1 - rise) * 0.18 + sin((t - 0.04) * 2 * .pi * 2.2) * 0.035 * rise, alpha: rise, r: 1)
        }
        let k = easeInOut(clamp01((t - 0.36) / 0.2)), q = 1 - k
        return Dot(x: q * q * 0.58 + 2 * q * k * 1.1, y: q * q * -1.18 + 2 * q * k * -0.3 + k * k * -0.04, alpha: 1, r: 1 - 0.35 * k)
    }
    static func frame(_ mode: CharacterMachine.Mode, _ t: Double) -> Self {
        func look(_ p: CGPoint) -> Gaze { Gaze(x: max(-1, min(1, p.x * 0.85)), y: max(-1, min(1, p.y * 0.8))) }
        var f = Self()
        switch mode {
        case .nod:
            let n = nodBeat(t)
            f.pitch = -0.5 * n; f.ty = 0.045 * n; f.sx = 1 + 0.02 * n; f.sy = 1 - 0.04 * n
            f.gaze = Gaze(x: 0, y: 0.25 + 0.55 * n); f.happy = band(t, 0.1, 0.08, 0.68, 0.1); f.glow = pulse(t, 0.05, 0.3) * 0.8
        case .salute:
            let wind = pulse(t, 0, 0.26), tall = pulse(t, 0.2, 0.36)
            f.spin = -0.2 * wind + .pi / 2 * saluteSnap(t); f.pitch = 0.16 * tall
            f.ty = 0.012 * wind - 0.03 * tall; f.sx = 1 + 0.045 * wind - 0.02 * tall; f.sy = 1 - 0.06 * wind + 0.05 * tall
            f.gaze = Gaze(x: 0, y: 0.1 - 0.3 * tall); f.pointer = false
            f.lid = 0.5 * band(t, 0.02, 0.08, 0.36, 0.1); f.suppressBlink = true; f.glow = tall
        case .tick:
            let drawn = tickDrawn(t)
            f.rot = 0.06 * band(t, 0.08, 0.14, 0.62, 0.2); f.ty = 0.018 * pulse(t, 0.4, 0.2)
            if let pen = tickPen(t) { f.gaze = look(pen) }
            else { f.gaze = t < 0.66 && drawn > 0 ? look(alongTick(0.55)) : Gaze(x: 0, y: 0.15) }
            f.pointer = false; f.happy = band(t, 0.47, 0.06, 0.84, 0.1); f.glow = pulse(t, 0.41, 0.2) * 0.9
        case .tuck:
            let gulp = pulse(t, 0.53, 0.22)
            f.sx = 1 - 0.05 * gulp; f.sy = f.sx; f.pitch = 0.18 * band(t, 0.06, 0.14, 0.36, 0.18)
            if let dot = tuckDot(t) { f.gaze = Gaze(x: look(CGPoint(x: dot.x, y: dot.y)).x, y: max(-1, dot.y * 1.1)) }
            else { f.gaze = Gaze(x: 0, y: 0.1) }
            f.pointer = false; f.lid = pulse(t, 0.6, 0.26); f.suppressBlink = true; f.glow = gulp
        case .aww:
            let shy = band(t, 0.05, 0.15, 0.8, 0.18)
            let sway = sin((t - 0.12) * 2 * .pi * 2.1) * 0.035 * band(t, 0.12, 0.12, 0.74, 0.16)
            f.rot = -0.07 * shy + sway; f.ty = 0.012 * shy; f.sx = 1 - 0.045 * shy; f.sy = f.sx
            f.gaze = Gaze(x: -0.55, y: 0.55); f.pointer = false; f.happy = band(t, 0.06, 0.1, 0.84, 0.12); f.glow = shy * 0.6
        default: break
        }
        return f
    }
}
