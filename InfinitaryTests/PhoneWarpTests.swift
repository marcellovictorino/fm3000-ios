import SwiftUI
import XCTest
@testable import Infinitary
@testable import InfinitaryKit

/// INF-1755: the warp fidgets play on the phone as on the Mac (captain, INF-1750: "add all 3 actually"). Only the
/// crew circling the first mate ride along, crew on another computer stay in their own group (the captain's answer:
/// "Only the crew circling the first mate"), and every rider comes home to its own seat on its own orbit.
@MainActor final class PhoneWarpTests: XCTestCase {
    private func roster(home: Int, remote: Int) throws -> PhoneSceneRoster {
        func task(_ id: String, device: String?) -> [String: Any] {
            var task: [String: Any] = ["id": id, "key": id, "projectId": "p", "kind": "work", "title": id, "status": "active",
                                       "createdAt": 0.0, "blockedBy": [String](), "activity": "running"]
            if let device { task["executionDeviceId"] = device }
            return task
        }
        let tasks = (1...home).map { task("home-\($0)", device: nil) } + (1...remote).map { task("studio-\($0)", device: "studio") }
        let json: [String: Any] = ["seq": 1, "tasks": tasks, "projects": [["id": "p", "name": "Infinitary"]], "links": [[String: Any]]()]
        let board = try JSONDecoder().decode(PhoneBoard.self, from: JSONSerialization.data(withJSONObject: json))
        let presence = try JSONDecoder().decode([PhoneComputerPresence].self, from: Data(#"[{"id":"studio","name":"Studio","inReach":true}]"#.utf8))
        return PhoneSceneRoster.Cache().read(board: board, presence: presence, homeName: "Mac", inReach: true, generation: 1, revision: 1)
    }

    func testEveryWarpTakesOnlyTheHomeCrewAndBringsEachHomeToItsSeat() throws {
        let roster = try roster(home: 8, remote: 3)
        let home = try XCTUnwrap(roster.computers.first { $0.id == "home" })
        for variant in [CharacterMachine.Fidget.tunnel, .sphere, .corkscrew] {
            let riding = PhoneSceneMotion(), still = PhoneSceneMotion()
            let seconds = CharacterCatalog.shared.fidgets[variant.rawValue]! / 1000
            var moved = 0.0, last: PhoneSceneMotion.Frame?
            for step in 0...Int((seconds + 1) * 60) {
                let now = Double(step) / 60
                var pose = CharacterPose(mode: .fidget, progress: min(1, now / seconds), variant: variant, milliseconds: now * 1000)
                if now >= seconds { pose.mode = .idle; pose.variant = nil }
                let a = riding.frame(roster: roster, now: now, settled: false, warp: CharacterWarp.frame(pose, coreR: 280 * 0.27))
                let b = still.frame(roster: roster, now: now, settled: false)
                let alone = Dictionary(uniqueKeysWithValues: b.glyphs.map { ($0.task.id, $0) })
                for glyph in a.glyphs {
                    let other = try XCTUnwrap(alone[glyph.task.id])
                    if glyph.task.id.hasPrefix("studio") {
                        // Crew on another computer keep their own group and pace.
                        XCTAssertEqual(glyph.point.x, other.point.x, accuracy: 0.000001, "\(variant) \(glyph.task.id) at \(now)")
                        XCTAssertEqual(glyph.point.y, other.point.y, accuracy: 0.000001, "\(variant) \(glyph.task.id) at \(now)")
                    } else { moved = max(moved, hypot(glyph.point.x - other.point.x, glyph.point.y - other.point.y)) }
                }
                last = a
            }
            XCTAssertGreaterThan(moved, 20, "\(variant): the home crew ride the warp")
            XCTAssertEqual(riding.warp == nil, true, "\(variant): the warp has ended")
            // Home again: each rider is back on its own orbit's circle, at its full size, with no trail.
            for glyph in try XCTUnwrap(last).glyphs where glyph.task.id.hasPrefix("home") {
                let seat = try XCTUnwrap(home.book.crew[glyph.task.id]), orbit = try XCTUnwrap(glyph.orbit)
                XCTAssertEqual(Int(orbit.plane.rounded()), seat.plane, "\(variant) \(glyph.task.id)'s orbit")
                let drawn = PhoneSceneRoster.projected(orbit)
                XCTAssertEqual(glyph.point.x, glyph.center.x + drawn.point.x, accuracy: 0.5, "\(variant) \(glyph.task.id)")
                XCTAssertEqual(glyph.point.y, glyph.center.y + drawn.point.y, accuracy: 0.5, "\(variant) \(glyph.task.id)")
                XCTAssertEqual(glyph.scale, 1)
                XCTAssertTrue(glyph.streak.isEmpty)
            }
        }
    }

    /// INF-2039: the native scene check taps an orbiting crewmate where XCTest read it a moment before the touch lands.
    /// A warp speeds the home crew up until a trailing crewmate takes that point, so the check holds the tap until
    /// PhoneOrbitPace reads every home crewmate riding its orbit at its own pace. Read from the scene's own motion every
    /// tenth of a second, as the check polls: a tap aimed whenever the crew pass still lands on its crewmate, and
    /// without the watch some tap in each warp would open a neighbour. No reading shows a warp that has not yet moved
    /// anyone, so an aim read before the warp moved any crewmate by a point is the one kind the watch cannot hold.
    func testAnOrbitingTapWaitsOutEveryWarp() throws {
        let roster = try roster(home: 32, remote: 1)
        let pace = PhoneOrbitPace(planes: CharacterCatalog.shared.planes.map {
            .init(speedDegPerSec: $0.speedDegPerSec, inclination: $0.inclination, node: $0.node)
        })
        let center = CGPoint(x: roster.homeX, y: roster.height / 2)
        // The failing run's tap: XCTest read crew-20's frame 0.12 s before it synthesized the touch.
        let delay = 0.12, fps = 60.0
        for variant in [CharacterMachine.Fidget.tunnel, .sphere, .corkscrew] {
            let motion = PhoneSceneMotion(), plain = PhoneSceneMotion()
            let seconds = CharacterCatalog.shared.fidgets[variant.rawValue]! / 1000
            // Idle orbit first, then the warp, then its release home.
            let idle = 3.0, end = idle + seconds + 2
            var frames: [PhoneSceneMotion.Frame] = [], unmoved: [Bool] = []
            for step in 0...Int(end * fps) {
                let now = Double(step) / fps, et = (now - idle) / seconds
                var pose = CharacterPose(mode: .idle, milliseconds: now * 1000)
                if et >= 0 && et < 1 { pose = CharacterPose(mode: .fidget, progress: et, variant: variant, milliseconds: now * 1000) }
                let frame = motion.frame(roster: roster, now: now, settled: false, warp: CharacterWarp.frame(pose, coreR: 280 * 0.27))
                let alone = Dictionary(uniqueKeysWithValues: plain.frame(roster: roster, now: now, settled: false).glyphs.map { ($0.task.id, $0.point) })
                frames.append(frame)
                unmoved.append(frame.glyphs.allSatisfy { glyph in alone[glyph.task.id].map { hypot(glyph.point.x - $0.x, glyph.point.y - $0.y) <= 1 } ?? false })
            }
            func lands(aimedAt step: Int, on id: String) throws -> Bool {
                let aim = try XCTUnwrap(frames[step].glyphs.first { $0.task.id == id }).point
                let later = frames[step + Int(delay * fps)].glyphs
                let target = try XCTUnwrap(later.first { $0.task.id == id }).point
                let reach = hypot(aim.x - target.x, aim.y - target.y)
                // PhoneTouchCell: the 44-point square about the crewmate, less whatever lies nearer another crewmate.
                return abs(aim.x - target.x) <= 22 && abs(aim.y - target.y) <= 22
                    && later.allSatisfy { $0.task.id == id || hypot(aim.x - $0.point.x, aim.y - $0.point.y) >= reach }
            }
            var crew = PhoneOrbitPace.Crew(pace: pace)
            var passed = 0, held = 0, missed = 0, unseen = 0
            for step in stride(from: 0, to: frames.count - Int(delay * fps), by: Int(fps / 10)) {
                let home = frames[step].glyphs.filter { $0.task.executionDeviceId == nil }
                let time = Double(step) / fps
                let atPace = crew.read(Dictionary(uniqueKeysWithValues: home.map { ($0.task.id, $0.point) }), center: center,
                                       time: time, target: try XCTUnwrap(home.first).task.id)
                if time >= PhoneOrbitPace.window && time < idle {
                    XCTAssertTrue(atPace, "\(variant): at \(time) s the crew orbit at their own pace, \(crew.unsteady)")
                }
                for glyph in home {
                    let landed = try lands(aimedAt: step, on: glyph.task.id)
                    if !landed { missed += 1 }
                    guard atPace else { held += 1; continue }
                    passed += 1
                    if !landed && unmoved[step] { unseen += 1; continue }
                    XCTAssertTrue(landed, "\(variant): the crew passed the watch at \(time) s, but a tap aimed at \(glyph.task.id) opens another crewmate")
                }
            }
            XCTAssertGreaterThan(missed, 0, "\(variant): without the watch, a tap in the warp opens a neighbour")
            print("INF-2039 \(variant): \(passed) aims at pace, \(held) held, \(missed) that would open another crewmate, \(unseen) aimed before the warp moved anyone")
        }
    }
}
