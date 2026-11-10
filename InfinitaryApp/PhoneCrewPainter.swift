import SwiftUI

/// Native solids share desktop vertices, edges, depth projection, heat, the banked background-wait ring and the waiting-on-you beacon.
enum PhoneCrewPainter {
    static func circle(_ at: CGPoint, _ r: Double) -> Path {
        Path(ellipseIn: CGRect(x: at.x - r, y: at.y - r, width: r * 2, height: r * 2))
    }
    static func draw(_ frame: PhoneSceneMotion.Frame, roster: PhoneSceneRoster, now: Double, still: Bool,
                     in context: inout ScenePen, palette: CharacterPainter.Palette) {
        // As on the desktop, no orbit is outlined and another computer's group has no ring at its center.
        for (from, to, review) in frame.links {
            var path = Path(); path.move(to: from); path.addLine(to: to)
            let angle = atan2(to.y - from.y, to.x - from.x), at = CGPoint(x: to.x - cos(angle) * 20, y: to.y - sin(angle) * 20)
            path.move(to: CGPoint(x: at.x - cos(angle - 0.5) * 6, y: at.y - sin(angle - 0.5) * 6))
            path.addLine(to: at); path.addLine(to: CGPoint(x: at.x - cos(angle + 0.5) * 6, y: at.y - sin(angle + 0.5) * 6))
            context.stroke(path, with: .color((review ? palette.hot : palette.dim).color(0.5)), style: StrokeStyle(lineWidth: 1, dash: review ? [] : [3, 4]))
        }
        for mark in frame.marks {
            context.stroke(circle(mark.point, CharacterCatalog.shared.program["rootMarkPx"]!), with: .color(palette.acc.color(0.8)), lineWidth: 1.2)
        }
        for glyph in frame.glyphs {
            streak(glyph, in: &context, palette: palette)
            draw(glyph, now: now, still: still, in: &context, palette: palette)
        }
        for (point, strength) in frame.packets {
            context.fill(circle(point, 5), with: .radialGradient(PenGradient(colors: [palette.acc.color(0.6 * strength), palette.acc.color(0)]), center: point, startRadius: 0, endRadius: 5))
            context.fill(circle(point, 2), with: .color(palette.acc.color(strength)))
        }
    }
    /// Keyboard browsing's accent outline round the selected crewmate's 44-point square, and the desktop's corner
    /// brackets round the crewmate whose summary is open (INF-1926), drawn with the frame they belong to.
    static func drawMarks(_ frame: PhoneSceneMotion.Frame, selection: String?, bracketed: (task: String, computer: String)?,
                          in context: inout ScenePen, palette: CharacterPainter.Palette) {
        guard selection != nil || bracketed != nil else { return }
        let glyphs = frame.glyphs.map { (id: $0.task.id, task: $0.task.id, computer: PhoneSceneRoster.computerID($0.task), point: $0.point, reach: $0.size / 2 + 4) }
        let marks = frame.marks.map { (id: $0.id, task: $0.task.id, computer: $0.computerID, point: $0.point, reach: CharacterCatalog.shared.program["rootMarkPx"]! + 4) }
        for target in glyphs + marks {
            let square = CGRect(x: target.point.x - 22, y: target.point.y - 22, width: 44, height: 44)
            if selection == target.id {
                context.stroke(Path(roundedRect: square, cornerRadius: PhoneTheme.controlRadius, style: .continuous),
                               with: .color(palette.accent), lineWidth: 1.5)
            }
            if let bracketed, bracketed.task == target.task, bracketed.computer == target.computer {
                context.stroke(PhoneCrewBrackets(reach: target.reach).path(in: square), with: .color(palette.muted), lineWidth: 1)
            }
        }
    }
    /// A warp rider's light trail (CharacterWarp.ride), in its own light lifted toward white, thinning and fading away from it.
    private static func streak(_ glyph: PhoneSceneMotion.Glyph, in context: inout ScenePen, palette: CharacterPainter.Palette) {
        let points = glyph.streak, segments = points.count - 1
        guard segments > 0, glyph.unfold > 0.01 else { return }
        let color = palette.acc.mix(palette.hot, glyph.unknown ? 0 : max(glyph.work, glyph.wait * glyph.job)).mix(CharacterPainter.RGB(255, 246, 230), 0.25)
        for i in 0..<segments {
            let fade = 1 - Double(i) / Double(segments)
            context.stroke(Path { $0.move(to: points[i]); $0.addLine(to: points[i + 1]) },
                           with: .color(color.color(min(1, 0.42 * fade * fade * glyph.alpha * glyph.unfold * palette.boost))),
                           style: StrokeStyle(lineWidth: max(0.6, glyph.size * 0.2 * fade), lineCap: .round))
        }
    }
    private static func draw(_ glyph: PhoneSceneMotion.Glyph, now: Double, still: Bool, in context: inout ScenePen, palette: CharacterPainter.Palette) {
        let solid = CharacterCatalog.shared.solids[glyph.task.tier ?? "low"] ?? CharacterCatalog.shared.solids["low"]!
        let work = glyph.unknown ? 0 : glyph.work
        // A background wait banks to idle strength; its wires stay ember only for local work, ice cyan for checks (INF-1777).
        let waits = CharacterCatalog.shared.wait, wait = glyph.unknown ? 0 : glyph.wait
        let color = palette.acc.mix(palette.hot, max(work, wait * glyph.job))
        let beacon = CharacterCatalog.shared.captain
        let working = 0.55 + 0.45 * work, banked = working + (waits["strength"]! - working) * wait
        let strength = (banked + (beacon["wire"]! - banked) * glyph.captain) * glyph.alpha * (glyph.unknown ? 0.45 : 1) * palette.boost
        let jitter = glyph.nudge * 3
        let at = CGPoint(x: glyph.point.x + CharacterSky.twinkle(now * 14) * jitter, y: glyph.point.y + CharacterSky.twinkle(now * 13) * jitter)
        let radius = glyph.size * 0.4, angle = glyph.spin
        let points: [(CGPoint, Double)] = solid.v.map { v in
            let x = v[0] * cos(angle) - v[2] * sin(angle), z = v[0] * sin(angle) + v[2] * cos(angle)
            let y = v[1] * cos(angle * 0.6) - z * sin(angle * 0.6), z2 = v[1] * sin(angle * 0.6) + z * cos(angle * 0.6)
            let depth = 3 / (3 - z2)
            return (CGPoint(x: at.x + x * depth * radius * glyph.unfold, y: at.y + y * depth * radius * glyph.unfold), depth)
        }
        // The beacon (INF-1543): the Waiting on you ring under a soft halo, breathing; a still frame holds mid light.
        let waiting = glyph.captain * glyph.alpha * glyph.unfold
        if waiting > 0.01 {
            let breath = still ? 0.5 : 0.5 - 0.5 * cos(2 * .pi * (now - glyph.captainSince) / (beacon["breathMs"]! / 1000))
            let haloR = glyph.size * beacon["haloReach"]!, haloA = beacon["halo"]! * (0.4 + 0.6 * breath) * waiting
            context.fill(circle(at, haloR), with: .radialGradient(PenGradient(colors: [palette.acc.color(haloA), palette.acc.color(0)]), center: at, startRadius: 0, endRadius: haloR))
            let ringR = glyph.size * beacon["ring"]! * (1 + beacon["swell"]! * (breath - 0.5))
            let light = (beacon["lo"]! + (beacon["hi"]! - beacon["lo"]!) * breath) * waiting * palette.boost
            context.stroke(circle(at, ringR), with: .color(palette.acc.color(min(1, light))), lineWidth: beacon["line"]!)
        }
        let spill = glyph.flicker * CharacterCatalog.shared.flicker["glowSpill"]!
        if work > 0 || spill > 0 {
            let halo = glyph.size * (0.95 + 0.2 * spill), alpha = (0.14 * work + 0.5 * spill) * glyph.alpha * glyph.unfold
            context.fill(circle(at, halo), with: .radialGradient(PenGradient(colors: [color.color(alpha), color.color(0)]), center: at, startRadius: 0, endRadius: halo))
        }
        if glyph.unfold < 1 { context.fill(circle(at, 2.8 * (1 - glyph.unfold)), with: .color(palette.acc.color(glyph.alpha))) }
        // The wait ring: dashed, never the beacon's full ring, with a brighter arc travelling round it; a still frame holds it whole.
        let ringK = wait * glyph.alpha * glyph.unfold
        if ringK > 0.01 && glyph.batch {
            let gate = CharacterCatalog.shared.batch
            let half = gate["arcDeg"]! * .pi / 360
            let turn = glyph.batchRunning && !still ? now * gate["turnRadPerS"]! : 0
            for center in [0.0, Double.pi] {
                var arc = Path()
                arc.addArc(center: at, radius: glyph.size * gate["ring"]!,
                           startAngle: .radians(center - half + turn), endAngle: .radians(center + half + turn), clockwise: false)
                context.stroke(arc, with: .color(palette.acc.color(min(1, gate["alpha"]! * ringK * palette.boost))),
                               style: StrokeStyle(lineWidth: gate["line"]!, lineCap: .round))
            }
        } else if ringK > 0.01 {
            let ringR = glyph.size * waits["ring"]!, dash = 2 * .pi * ringR / waits["dashes"]!
            context.stroke(circle(at, ringR), with: .color(palette.acc.color(min(1, (still ? 0.6 : 0.3) * ringK * palette.boost))),
                           style: StrokeStyle(lineWidth: 1, dash: [dash * waits["dashShare"]!, dash * (1 - waits["dashShare"]!)]))
            if !still {
                let arc = CharacterSky.path(20) { t in
                    let angle = now * waits["arcRate"]! + t * waits["arc"]!
                    return CGPoint(x: at.x + cos(angle) * ringR, y: at.y + sin(angle) * ringR)
                }
                context.stroke(arc, with: .color(palette.acc.mix(CharacterPainter.RGB(255, 244, 224), 0.2).color(min(1, 0.9 * ringK))), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            }
        }
        let width = max(1, min(1.6, 1.4 * glyph.size / 30)) * solid.ink[1]
        for (index, edge) in solid.e.enumerated() {
            let a = points[edge[0]], b = points[edge[1]], flicker = glyph.flicker * CharacterFlicker.wire(index, now * 1000)
            let alpha = max(0.35, min(0.9, 0.4 + ((a.1 + b.1) / 2 - 0.85) * 0.9)) * strength * solid.ink[0]
            context.stroke(Path { $0.move(to: a.0); $0.addLine(to: b.0) }, with: .color(color.mix(CharacterPainter.RGB(255, 246, 230), min(1, flicker * 0.7)).color(min(1, alpha * (1 + 0.9 * flicker)))), style: StrokeStyle(lineWidth: width, lineCap: .round))
        }
        if work > 0.05 && glyph.unfold > 0.9 && !still {
            let cycle = now / 0.9, fraction = cycle - floor(cycle)
            if fraction < 0.3 {
                let edge = solid.e[Int(cycle) % solid.e.count]
                context.stroke(Path { $0.move(to: points[edge[0]].0); $0.addLine(to: points[edge[1]].0) }, with: .color(color.mix(CharacterPainter.RGB(255, 246, 230), 0.75).color(sin(fraction / 0.3 * .pi) * work * glyph.alpha)), lineWidth: width * 0.6)
            }
        }
        for index in 0..<(solid.nodes ?? points.count) {
            let point = points[index], pulse = 1 + 0.5 * work * max(0, sin(now / 0.3 + Double(index) * 1.3))
            let radius = 1.2 * glyph.size / 28 * pulse * (0.4 + 0.6 * glyph.unfold) * solid.ink[2]
            context.fill(circle(point.0, radius), with: .color(color.color(max(0.5, min(1, 0.5 + (point.1 - 0.85) * 0.8)) * strength * solid.ink[0])))
        }
    }
}
