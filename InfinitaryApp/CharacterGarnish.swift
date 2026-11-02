import SwiftUI

/// Replies and fidgets use the same light and line-art primitives as the desktop, with no image runtime.
enum CharacterGarnish {
    static func draw(_ p: CharacterPose, in context: inout GraphicsContext, c: Double, r: Double, size: Double,
                     color: Color, eyes: [CGPoint], pose: (Double, Double) -> CGPoint) {
        let t = p.progress, px = size / 280
        func dot(_ x: Double, _ y: Double, _ radius: Double, _ alpha: Double) {
            context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)), with: .color(color.opacity(alpha)))
        }
        func line(_ points: [CGPoint], _ width: Double, _ alpha: Double) {
            context.stroke(Path { path in for (i, point) in points.enumerated() { if i == 0 { path.move(to: point) } else { path.addLine(to: point) } } },
                           with: .color(color.opacity(alpha)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }
        if p.mode == .ponder {
            let k = band(t, 0.1, 0.2, 0.85, 0.15), angle = t * 9
            dot(c - r * 0.75 + cos(angle) * r * 0.16, c - r * (0.95 + t * 0.25) + sin(angle) * r * 0.08, 2.2 * px, 0.9 * k)
        }
        if p.mode == .celebrate {
            let k = band(t, 0.12, 0.1, 0.7, 0.3)
            for i in 0..<8 {
                let a = Double(i) / 8 * 2 * .pi, x = c + cos(a) * r * 1.5, y = c + sin(a) * r * 1.5
                line([CGPoint(x: x - 3 * px * k, y: y), CGPoint(x: x + 3 * px * k, y: y)], 1.2 * px, k)
                line([CGPoint(x: x, y: y - 3 * px * k), CGPoint(x: x, y: y + 3 * px * k)], 1.2 * px, k)
            }
        }
        if p.mode == .fidget && p.variant == .orbit {
            let k = band(t, 0.08, 0.12, 0.88, 0.12), angle = -.pi / 2 + easeInOut(clamp01((t - 0.1) / 0.75)) * 2 * .pi
            for ghost in 0..<3 {
                let g = Double(ghost), a = angle - g * 0.16
                dot(c + cos(a) * r * 1.18, c + sin(a) * r * 0.85, (2.4 - g * 0.5) * px, (0.9 - g * 0.3) * k)
            }
        }
        if p.mode == .salute {
            let k = pulse(t, 0.18, 0.34), sweep = CharacterReply.saluteSnap(t), center = pose(c, c)
            for base in [-2.2, 0.94] {
                for j in 0..<3 {
                    let a = base + sweep * 0.9, length = 0.9 * k
                    let arc = CharacterSky.path(12) { u in
                        let angle = a - length * Double(j + 1) / 3 + u * length / 3
                        return CGPoint(x: center.x + cos(angle) * r * 1.22, y: center.y + sin(angle) * r * 1.22)
                    }
                    context.stroke(arc, with: .color(color.opacity(0.8 * k * (1 - Double(j) * 0.3))), lineWidth: 1.4 * px)
                }
            }
        } else if p.mode == .tick {
            let drawn = CharacterReply.tickDrawn(t), fade = 1 - clamp01((t - 0.64) / 0.22), flash = pulse(t, 0.41, 0.2)
            func point(_ p: CGPoint) -> CGPoint { CGPoint(x: c + p.x * r, y: c + p.y * r) }
            var path = [point(CharacterReply.tickPoints[0])]
            if drawn * CharacterReply.tickTotal > CharacterReply.tickFirst { path.append(point(CharacterReply.tickPoints[1])) }
            path.append(point(CharacterReply.alongTick(drawn)))
            line(path, 5.5 * px, (0.16 + 0.22 * flash) * fade); line(path, 1.9 * px, (0.85 + 0.15 * flash) * fade)
            if let pen = CharacterReply.tickPen(t) { dot(c + pen.x * r, c + pen.y * r, 2.4 * px, 0.95 * clamp01((t - 0.06) / 0.04)) }
            let end = point(CharacterReply.tickPoints[2])
            for i in 0..<5 {
                let a = -.pi * 0.95 + Double(i) * 0.42, from = r * (0.08 + 0.1 * (1 - flash)), to = from + r * 0.07 * flash
                line([CGPoint(x: end.x + cos(a) * from, y: end.y + sin(a) * from), CGPoint(x: end.x + cos(a) * to, y: end.y + sin(a) * to)], 1.2 * px, 0.8 * flash)
            }
        } else if p.mode == .tuck {
            if let kept = CharacterReply.tuckDot(t) {
                let at = pose(c + kept.x * r, c + kept.y * r), halo = 9 * kept.r * px
                if t >= 0.36 {
                    for i in 1...2 {
                        if let back = CharacterReply.tuckDot(max(0.36, t - Double(i) * 0.025)) {
                            let b = pose(c + back.x * r, c + back.y * r)
                            dot(b.x, b.y, (2.4 - Double(i) * 0.5) * back.r * px, 0.5 - Double(i) * 0.18)
                        }
                    }
                }
                context.fill(Path(ellipseIn: CGRect(x: at.x - halo, y: at.y - halo, width: halo * 2, height: halo * 2)), with: .radialGradient(Gradient(colors: [color.opacity(0.45 * kept.alpha), color.opacity(0)]), center: at, startRadius: 0, endRadius: halo))
                dot(at.x, at.y, 3 * kept.r * px, 0.95 * kept.alpha)
            }
            let u = (t - 0.55) / 0.3
            if u > 0 && u < 1 {
                let at = pose(c, c - 0.04 * r), radius = max(1, r * (1.15 - 0.95 * easeInOut(u)))
                context.stroke(Path(ellipseIn: CGRect(x: at.x - radius, y: at.y - radius, width: radius * 2, height: radius * 2)), with: .color(color.opacity(0.55 * sin(u * .pi))), lineWidth: 1.4 * px)
            }
        } else if p.mode == .aww {
            let k = band(t, 0.12, 0.1, 0.78, 0.14), radius = r * 0.085 * p.cur.eyeScale * 1.2
            for eye in eyes {
                let side = eye.x < c ? -1.0 : 1.0, y = eye.y + radius * 2.1
                for i in -1...1 {
                    let x = eye.x + side * radius * 0.9 + Double(i) * radius * 0.85
                    line([CGPoint(x: x - radius * 0.28, y: y + radius * 0.42), CGPoint(x: x + radius * 0.28, y: y - radius * 0.42)], 1.3 * px, 0.75 * k)
                }
            }
        }
    }
}
