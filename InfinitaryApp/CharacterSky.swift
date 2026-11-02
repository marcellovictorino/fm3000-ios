import SwiftUI

/// The desktop sky figures, expressed in native paths. Layout and physical-looking proportions come
/// from the generated catalog; all motion uses the scene's elapsed time, never frame counts.
enum CharacterSky {
    static let rings = [[0, 1, 5, 4, 12, 8], [9, 11, 10, 14, 15, 13], [2, 3, 7, 6]]
    static let winding = rings[2] + rings[0] + rings[1]
    static func envelope(_ pose: CharacterPose) -> Double {
        pose.mode == .fidget ? band(pose.progress, 0.05, 0.25, 0.8, 0.17) : 0
    }
    static func twinkle(_ t: Double) -> Double { sin(t * 1.7) * 0.5 + sin(t * 2.9 + 1.3) * 0.3 + sin(t * 4.7 + 4.1) * 0.2 }
    static func tilted(_ x: Double, _ y: Double, _ tilt: Double, _ c: Double) -> CGPoint {
        CGPoint(x: c + x * cos(tilt) - y * sin(tilt), y: c + x * sin(tilt) + y * cos(tilt))
    }
    static func saturn(_ radius: Double, _ angle: Double, _ c: Double, _ r: Double) -> CGPoint {
        let data = CharacterCatalog.shared.saturn
        return tilted(cos(angle) * radius * r, -sin(angle) * radius * r * data.q, data.tilt, c)
    }
    static func galaxy(_ arm: Int, _ angle: Double, _ time: Double, _ c: Double, _ r: Double) -> CGPoint {
        let g = CharacterCatalog.shared.galaxy, radius = r * g["r0"]! * exp(g["pitch"]! * angle)
        let a = angle + time * g["spin"]! + Double(arm) * .pi
        return tilted(cos(a) * radius, sin(a) * radius * g["q"]!, g["tilt"]!, c)
    }
    static func lensed(_ rho: Double, _ angle: Double, _ c: Double, _ r: Double) -> CGPoint {
        let s = sin(angle), x = rho * cos(angle), flat = rho * 0.3 * s, lift = 1.28 * r * 0.5 * s
        return CGPoint(x: c + x * (s > 0 ? 1 - 0.42 * s : 1), y: c - (s > 0 ? hypot(flat, lift) : flat))
    }
    struct Placed {
        var point: CGPoint
        var progress = 0.0, white = 0.0
        var scale = 1.0, fade = 1.0
        var w: Double?
    }
    static func place(_ index: Int, base: CGPoint, pose: CharacterPose, c: Double, r: Double) -> Placed {
        var placed = Placed(point: base)
        let k = envelope(pose), time = pose.milliseconds / 1000
        guard k > 0.001, let variant = pose.variant else { return placed }
        if let con = CharacterCatalog.shared.constellations[variant.rawValue] {
            let rank = Double(con.order.firstIndex(of: index) ?? 0) / 15
            let blend = easeInOut(clamp01(k * 1.6 - rank * 0.6)), si = con.slots[index], star = con.stars[si]
            let dx = c + (star.x * con.scale + con.offset[0]) * r - base.x
            let dy = c + (star.y * con.scale + con.offset[1]) * r - base.y
            let bulge = sin(blend * .pi) * 0.14 * (index & 1 == 1 ? 1.0 : -1.0)
            placed.point = CGPoint(x: base.x + dx * blend - dy * bulge, y: base.y + dy * blend + dx * bulge)
            placed.progress = blend; placed.w = 0.7
            placed.scale = 1 + (max(0.55, 1.5 - 0.22 * star.mag) - 1) * blend
            placed.fade = 1 + 0.18 * twinkle(time * 5 + Double(si) * 2.3) * blend
            placed.white = (star.white == true ? 0.85 : star.nebula == true ? 0.35 : 0) * blend
        } else if variant == .saturn {
            let data = CharacterCatalog.shared.saturn, ring = rings.firstIndex { $0.contains(index) }!
            let slot = rings[ring].firstIndex(of: index)!, n = Double(rings[ring].count)
            let radius = ring == 0 ? data.ringA : ring == 1 ? data.ringB : data.globe * 0.97
            let speed = ring == 0 ? data.spinA : ring == 1 ? data.spinB : data.spinBelt
            let angle = time * speed + (Double(slot) + (ring == 1 ? 0.5 : 0)) / n * 2 * .pi
            let point = saturn(radius, angle, c, r), blend = easeInOut(clamp01(k)), near = sin(angle) < 0
            placed.point = CGPoint(x: base.x + (point.x - base.x) * blend, y: base.y + (point.y - base.y) * blend)
            placed.progress = blend; placed.w = near ? 0.7 : -0.5
            if !near && (ring == 2 || hypot(point.x - c, point.y - c) < data.globe * r * 0.98) { placed.fade = 1 - blend * 0.92 }
        } else if variant == .galaxy || variant == .blackhole {
            let galaxy = variant == .galaxy
            let u = galaxy ? Double(index >> 1) / 7 : Double(winding.firstIndex(of: index)!) / 15
            let blend = easeInOut(clamp01(k * 1.6 - u * 0.6)), turn = blend * (galaxy ? 1.4 : 1.6)
            let dx = base.x - c, dy = base.y - c
            let start = CGPoint(x: c + dx * cos(turn) - dy * sin(turn), y: c + dx * sin(turn) + dy * cos(turn))
            let target: CGPoint
            if galaxy {
                let g = CharacterCatalog.shared.galaxy
                target = self.galaxy(index & 1, g["armStart"]! + Double(index >> 1) * g["armStep"]!, time, c, r)
                placed.w = 0.6; placed.scale = 1 + 0.25 * blend * (1 - u)
                placed.fade = 1 + 0.15 * twinkle(time * 4 + Double(index)) * blend
            } else {
                target = lensed(r * (0.59 + (1.62 - 0.59) * u), time * 2.2 * (1 + 0.35 * (1 - u)) + u * 2 * .pi * 1.2, c, r)
            }
            placed.point = CGPoint(x: start.x + (target.x - start.x) * blend, y: start.y + (target.y - start.y) * blend)
            placed.progress = blend
        }
        return placed
    }
    struct Eye { var point: CGPoint; var depth = 1.0, alpha = 1.0, z = 0.0 }
    static func eye(_ side: Double, base: CGPoint, pose: CharacterPose, c: Double, r: Double) -> Eye {
        let k = envelope(pose)
        guard k > 0.001 else { return Eye(point: base) }
        if pose.variant == .algol {
            let a = CharacterCatalog.shared.algol
            let phase = easeInOut(clamp01((pose.progress - 0.1) / 0.8)) * 2 * .pi * a["orbits"]!
            let front = sin(phase) * side, blend = easeInOut(clamp01(k))
            let x = c + cos(phase) * a["sep"]! * r * side
            let y = c - a["eyeRise"]! * r + sin(phase) * a["sep"]! * r * a["flatten"]! * side
            let align = pow(max(0, 1 - abs(cos(phase)) * 3), 2)
            return Eye(point: CGPoint(x: base.x + (x - base.x) * blend, y: base.y + (y - base.y) * blend),
                       depth: 1 + 0.12 * front * blend, alpha: 1 - (front < 0 ? a["cover"]! * align * blend : 0), z: front)
        }
        if pose.variant == .blackhole {
            let angle = pose.milliseconds / 1000 * 1.35 + (side == 1 ? 0 : .pi)
            let target = lensed(r * 0.7, angle, c, r), blend = min(1, k * 1.25)
            return Eye(point: CGPoint(x: base.x + (target.x - base.x) * blend, y: base.y + (target.y - base.y) * blend), depth: 1 + (sin(angle) > 0 ? -0.12 : 0.1) * k)
        }
        return Eye(point: base)
    }
    static func dim(_ pose: CharacterPose) -> Double {
        guard pose.mode == .fidget, pose.variant == .algol else { return 1 }
        let a = CharacterCatalog.shared.algol
        let phase = easeInOut(clamp01((pose.progress - 0.1) / 0.8)) * 2 * .pi * a["orbits"]!
        return 1 - a["dip"]! * pow(max(0, 1 - abs(cos(phase)) * 3), 2) * easeInOut(clamp01(envelope(pose)))
    }
    static func path(_ count: Int, point: (Double) -> CGPoint) -> Path {
        Path { p in for i in 0...count { let at = point(Double(i) / Double(count)); if i == 0 { p.move(to: at) } else { p.addLine(to: at) } } }
    }
    static func draw(_ pose: CharacterPose, over: Bool, context: inout GraphicsContext, c: Double, r: Double, color: Color, background: Color) {
        let k = envelope(pose), blend = easeInOut(clamp01(k)), time = pose.milliseconds / 1000
        guard k > 0.001, let variant = pose.variant else { return }
        if let con = CharacterCatalog.shared.constellations[variant.rawValue], over {
            for (index, edge) in con.lines.enumerated() {
                let traced = clamp01((pose.progress - 0.2 - Double(index) * 0.012) / 0.1)
                let a = con.stars[edge[0]], b = con.stars[edge[1]]
                let start = CGPoint(x: c + (a.x * con.scale + con.offset[0]) * r, y: c + (a.y * con.scale + con.offset[1]) * r)
                let end = CGPoint(x: start.x + (b.x - a.x) * con.scale * r * traced, y: start.y + (b.y - a.y) * con.scale * r * traced)
                context.stroke(Path { $0.move(to: start); $0.addLine(to: end) }, with: .color(color.opacity(0.45 * blend)), lineWidth: 1)
            }
        } else if variant == .saturn {
            let data = CharacterCatalog.shared.saturn
            for line in data.streamlines {
                context.stroke(path(40) { saturn(line[0], (over ? .pi : 0) + $0 * .pi, c, r) }, with: .color(color.opacity(line[1] * blend)), lineWidth: 1)
            }
            if !over {
                let globe = Path(ellipseIn: CGRect(x: c - data.globe * r, y: c - data.globe * r, width: 2 * data.globe * r, height: 2 * data.globe * r))
                context.fill(globe, with: .color(background.opacity(0.94 * blend)))
                context.fill(globe, with: .radialGradient(Gradient(colors: [color.opacity(0), color.opacity(0.16 * blend)]), center: CGPoint(x: c, y: c), startRadius: data.globe * r * 0.55, endRadius: data.globe * r))
                context.stroke(globe, with: .color(color.opacity(0.7 * blend)), lineWidth: 1.2)
                for y in [-0.38, 0.42] {
                    context.stroke(path(40) { v in let a = .pi * (y < 0 ? 1.1 : 0.1) + v * .pi * 0.8; return tilted(cos(a) * data.globe * r * 0.9, (y + sin(a) * 0.16) * data.globe * r, data.tilt, c) }, with: .color(color.opacity(0.25 * blend)), lineWidth: 1)
                }
            }
        } else if variant == .galaxy && !over {
            let g = CharacterCatalog.shared.galaxy
            for arm in 0..<2 {
                let armPath = path(60) { galaxy(arm, g["armFrom"]! + $0 * g["armSpan"]!, time, c, r) }
                context.stroke(armPath, with: .color(color.opacity(0.12 * blend)), lineWidth: r * 0.12)
                context.stroke(armPath, with: .color(color.opacity(0.42 * blend)), lineWidth: 1)
            }
        } else if variant == .blackhole && !over {
            let shadow = Path(ellipseIn: CGRect(x: c - r * 0.5, y: c - r * 0.5, width: r, height: r))
            context.fill(shadow, with: .color(background.opacity(blend)))
            for n in 0..<9 {
                let rho = r * (0.59 + Double(n) / 8 * 1.03)
                let ring = path(100) { lensed(rho, $0 * 2 * .pi, c, r) }
                context.stroke(ring, with: .linearGradient(Gradient(colors: [color.opacity(0.7 * blend), color.opacity(0.15 * blend)]), startPoint: CGPoint(x: c - rho, y: c), endPoint: CGPoint(x: c + rho, y: c)), lineWidth: n == 0 ? 1.6 : 0.7)
            }
        } else if variant == .algol && !over {
            let a = CharacterCatalog.shared.algol, radius = r * a["sep"]!
            let orbit = Path(ellipseIn: CGRect(x: c - radius, y: c - a["eyeRise"]! * r - radius * a["flatten"]!, width: radius * 2, height: radius * 2 * a["flatten"]!))
            context.stroke(orbit, with: .color(color.opacity(0.25 * blend)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
        }
    }
}
