import InfinitaryKit
import SwiftUI

/// INF-1375, approved A: the desktop's eligible wait/review circles, at the phone/computer scale.
/// Published task facts alone choose relationships; branches and bounds resolve actual placement.
enum PhoneSceneCompanions {
    struct Cue { var blocker: String; var index: Int; var count: Int; var circles: Bool }
    static func cues(_ tasks: [PhoneTask], parts: Set<String>) -> [String: Cue] {
        let byKey = Dictionary(uniqueKeysWithValues: tasks.map { ($0.key, $0) })
        let byID = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        var cues: [String: Cue] = [:], waits: [String: [PhoneTask]] = [:]
        let limit = Int(CharacterCatalog.shared.dependency["maxCompanions"]!)
        for task in tasks where !task.blockedBy.isEmpty {
            let blockers = task.blockedBy.compactMap { byKey[$0] }.filter { PhoneSceneRoster.computerID($0) == PhoneSceneRoster.computerID(task) }
            guard let blocker = blockers.first else { continue }
            // The builder's merge hold is not a second circle back to its reviewer.
            if blockers.count == 1 && blocker.reviewOf == task.id { continue }
            let eligible = task.workPosture?.state == "idle" && task.workPosture?.reason == "dependency"
                && task.blockedBy.count == 1 && blocker.blockedBy.isEmpty
                && !tasks.contains { $0.blockedBy.contains(task.key) }
            if eligible { waits[blocker.id, default: []].append(task) }
            else { cues[task.id] = Cue(blocker: blocker.id, index: 0, count: 1, circles: false) }
        }
        for (blocker, group) in waits {
            for (index, task) in group.sorted(by: { $0.key < $1.key }).enumerated() {
                cues[task.id] = Cue(blocker: blocker, index: index, count: group.count, circles: group.count <= limit)
            }
        }
        var reviews: [String: [String]] = [:]
        for task in tasks {
            guard let builder = task.reviewOf, builder != task.id, let other = byID[builder],
                  PhoneSceneRoster.computerID(other) == PhoneSceneRoster.computerID(task), cues[task.id] == nil else { continue }
            reviews[builder, default: []].append(task.id)
        }
        for (builder, reviewers) in reviews {
            let seated = cues.filter { $0.value.circles && $0.value.blocker == builder }.sorted { $0.value.index < $1.value.index }
            let count = seated.count + reviewers.count
            let circles = cues[builder]?.circles != true && count <= limit
            if circles { for (index, pair) in seated.enumerated() { cues[pair.key] = Cue(blocker: builder, index: index, count: count, circles: true) } }
            for (index, reviewer) in reviewers.sorted().enumerated() {
                cues[reviewer] = Cue(blocker: builder, index: seated.count + index, count: circles ? count : 1, circles: circles)
            }
        }
        for id in Array(cues.keys) {
            if parts.contains(id) || parts.contains(cues[id]!.blocker) { cues[id]?.circles = false }
        }
        return cues
    }

    /// The circle spans the blocker's radial spoke and its plane's normal.
    private static func axes(_ orbit: PhoneSceneRoster.Orbit) -> (radial: (Double, Double, Double), normal: (Double, Double, Double)) {
        let p = CharacterCatalog.shared.planes[Int(orbit.plane.rounded())]
        let incline = p.inclination * .pi / 180, c = cos(p.node), s = sin(p.node)
        return ((c * cos(orbit.angle) - s * cos(incline) * sin(orbit.angle), s * cos(orbit.angle) + c * cos(incline) * sin(orbit.angle), sin(incline) * sin(orbit.angle)),
                (s * sin(incline), -c * sin(incline), cos(incline)))
    }

    /// INF-1532, the captain's choice A: the full radius, or the largest smaller one whose whole circle stays
    /// within `reach` of the computer's center around a blocker at `point`, so a waiter near the edge keeps
    /// circling on a tighter circle instead of leaving it. Zero when the blocker itself is past the reach.
    static func radius(orbit: PhoneSceneRoster.Orbit, around point: CGPoint, reach: CGSize, share: Double) -> Double {
        let (radial, normal) = axes(orbit)
        let spanX = hypot(radial.0, normal.0), spanY = hypot(radial.1, normal.1)
        let full = CharacterCatalog.shared.dependency["radiusPx"]! * PhoneSceneRoster.ringScale * share
        return max(0, min(full, (reach.width - abs(point.x)) / spanX, (reach.height - abs(point.y)) / spanY))
    }

    static func offset(_ cue: Cue, orbit: PhoneSceneRoster.Orbit, time: Double, settled: Bool, radius: Double) -> (point: CGPoint, z: Double) {
        let tuning = CharacterCatalog.shared.dependency, (radial, normal) = axes(orbit)
        let phase = tuning["phase"]! + Double(cue.index) / Double(max(1, cue.count)) * 2 * .pi + (settled ? 0 : time * tuning["degPerSec"]! * .pi / 180)
        return (CGPoint(x: radius * (radial.0 * cos(phase) + normal.0 * sin(phase)),
                        y: radius * (radial.1 * cos(phase) + normal.1 * sin(phase))),
                radius * (radial.2 * cos(phase) + normal.2 * sin(phase)))
    }
}
