import CoreGraphics
import Foundation

/// INF-2039: a crewmate orbits its first mate and never holds still, so a tap on one aims at the frame XCTest read a
/// moment before the touch lands. At an orbit's own pace a neighbour needs over a second to reach the point the
/// crewmate left; while the first mate's warp fidget speeds the home crew up five to eleven times, it needs less than
/// the tap's own delay, and the neighbour takes the tap. A warp moves the whole home crew, and its corkscrew moves a
/// tapped crewmate's neighbours before the crewmate itself, so a tap on an orbiting crewmate first waits until every
/// orbiting crewmate rides one of the orbits no faster than that orbit's own pace.
/// It lives beside the load clock because both test targets compile this folder: the journey taps by it, and the
/// app-hosted PhoneWarpTests hold it against the scene's own motion.
struct PhoneOrbitPace: Sendable {
    /// An orbit as the scene draws it: its turn, its tilt toward the viewer and the turn of its tilted circle on screen.
    struct Plane: Sendable {
        let speedDegPerSec: Double
        let inclination: Double
        let node: Double
    }
    let planes: [Plane]

    /// Readings at least this far apart, in seconds, so a point of frame rounding stays a small share of an orbit's turn.
    static let window: TimeInterval = 0.5
    /// How much older than its time a reading's frame may be: a snapshot of the app takes up to this long.
    static let lag: TimeInterval = 0.1

    /// A crewmate's center and its first mate's, both in screen points, read at `time` (system uptime, seconds).
    struct Reading: Sendable {
        let point: CGPoint
        let center: CGPoint
        let time: TimeInterval
    }

    /// Successive readings of one crewmate.
    struct Watch: Sendable {
        let pace: PhoneOrbitPace
        private var readings: [(offset: CGPoint, time: TimeInterval)] = []
        /// The last window on each orbit: how far the crewmate turned along it and what its pace allowed, radians, and
        /// how far it drifted off that orbit's circle, points, for a failure's message.
        private(set) var last: [(turned: Double, allowed: Double, drift: Double)] = []

        init(pace: PhoneOrbitPace) { self.pace = pace }

        /// Adds `reading`; true once, from the latest reading at least a window earlier to this one, the crewmate keeps
        /// to one orbit's circle and turns along it no faster than that orbit's pace, allowing a point of frame
        /// rounding on each reading. Each reading is drawn back onto the orbit's own untilted circle, where a crewmate
        /// at the orbit's pace keeps its radius and turns evenly, so a warp's speed, flattening or detour shows at once.
        /// Its place is read from its first mate's, so a pan between readings moves neither.
        mutating func read(_ reading: Reading) -> Bool {
            readings.append((CGPoint(x: reading.point.x - reading.center.x, y: reading.point.y - reading.center.y), reading.time))
            guard let from = readings.lastIndex(where: { reading.time - $0.time >= PhoneOrbitPace.window }) else { return false }
            readings.removeFirst(from)
            let elapsed = reading.time - readings[0].time
            last = pace.planes.map { plane in
                let tilt = cos(plane.inclination * .pi / 180), node = plane.node, rate = plane.speedDegPerSec * .pi / 180
                let circle = readings.map { r -> (radius: Double, angle: Double) in
                    let u = r.offset.x * cos(node) + r.offset.y * sin(node), w = (-r.offset.x * sin(node) + r.offset.y * cos(node)) / tilt
                    return (hypot(u, w), atan2(w, u))
                }
                // Summed reading to reading, so a fast warp never wraps a whole window's turn into a small one.
                let turned = zip(circle, circle.dropFirst()).reduce(0) { $0 + remainder($1.1.angle - $1.0.angle, 2 * .pi) }
                let rounding = 2 / (max(1, circle[0].radius) * tilt)
                // The scene turns an orbit's angle against its speed (PhoneSceneMotion: slot - time * rate).
                let along = rate == 0 ? abs(turned) : -turned * (rate > 0 ? 1 : -1)
                let drift = circle.map { abs($0.radius - circle[0].radius) * tilt }.max() ?? 0
                return (along >= -rounding ? along : .infinity, abs(rate) * (elapsed + PhoneOrbitPace.lag) + rounding, drift)
            }
            return atPace
        }

        /// Whether the last window kept to one orbit's circle, within two points, at no more than that orbit's pace.
        var atPace: Bool { last.contains { $0.turned <= $0.allowed && $0.drift <= 2 } }
    }

    /// Every orbiting crewmate in the scene, read together, each by its own Watch.
    struct Crew: Sendable {
        let pace: PhoneOrbitPace
        private(set) var watches: [String: Watch] = [:]

        init(pace: PhoneOrbitPace) { self.pace = pace }

        /// Adds one reading of the crew, each crewmate's center by its id; true once `target` and every other crewmate
        /// read ride their orbits at pace. A crewmate missing from a reading starts its watch again.
        mutating func read(_ points: [String: CGPoint], center: CGPoint, time: TimeInterval, target: String) -> Bool {
            guard points[target] != nil else { watches = [:]; return false }
            watches = watches.filter { points[$0.key] != nil }
            var all = true
            for (id, point) in points {
                var watch = watches[id] ?? Watch(pace: pace)
                if !watch.read(.init(point: point, center: center, time: time)) { all = false }
                watches[id] = watch
            }
            return all
        }

        /// The crewmates still off their orbits' pace, with each orbit's last turn, allowance and drift.
        var unsteady: [String: [(turned: Double, allowed: Double, drift: Double)]] {
            watches.filter { !$0.value.atPace }.mapValues(\.last)
        }
    }
}

