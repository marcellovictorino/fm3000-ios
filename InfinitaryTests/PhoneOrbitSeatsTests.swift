import SwiftUI
import XCTest
@testable import Infinitary
@testable import InfinitaryKit

/// INF-1325: the captain asked the phone's orbits to work as the desktop's updated ones do.
/// The desktop's own seat choices, recorded by scripts/generate-phone-scene.ts through arrivals and departures,
/// are replayed here through the phone's roster and scene, a read of the board per step.
@MainActor final class PhoneOrbitSeatsTests: XCTestCase {
    private struct Step: Decodable {
        let arrive: [String]?
        let leave: [String]?
        let program: Program?
        let crew: [String: [Double]]?
        let marks: [String: [Double]]?
        let outer: Double?
        struct Program: Decodable { let id: String; let parts: [String] }
    }

    private func sequences() throws -> [String: [Step]] {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "PhoneOrbitSeats.generated", withExtension: "json"))
        return try JSONDecoder().decode([String: [Step]].self, from: Data(contentsOf: url))
    }

    /// The board the phone reads after each step: the crew in arrival order, on one computer, and the program while it runs.
    private func board(_ crew: [String], arrived: [String: Int], program: Step.Program?, device: String?, seq: Int, waits: [String: String] = [:], reviews: [String: String] = [:]) throws -> PhoneBoard {
        var tasks: [[String: Any]] = crew.map { id in
            var task: [String: Any] = ["id": id, "key": id, "projectId": "p", "kind": "work", "title": id, "status": "active",
                                       "createdAt": Double(arrived[id] ?? 0),
                                       "blockedBy": [String](), "activity": "running"]
            if let blocker = waits[id] {
                task["blockedBy"] = [blocker]; task["activity"] = "idle"
                task["workPosture"] = ["state": "idle", "reason": "dependency"]
            }
            if let builder = reviews[id] { task["reviewOf"] = builder }
            if let device { task["executionDeviceId"] = device }
            if let program, program.parts.contains(id) { task["parentId"] = program.id }
            return task
        }
        if let program {
            tasks.append(["id": program.id, "key": program.id, "projectId": "p", "kind": "work", "title": program.id, "status": "active",
                          "createdAt": 0.0, "blockedBy": [String](), "program": true])
        }
        let json: [String: Any] = ["seq": seq, "tasks": tasks, "projects": [["id": "p", "name": "Infinitary"]], "links": [[String: Any]]()]
        return try JSONDecoder().decode(PhoneBoard.self, from: JSONSerialization.data(withJSONObject: json))
    }

    /// A point drawn on an orbit, back on that orbit's own circle: its angle and its radius.
    private static func polar(_ point: CGPoint, plane: Int) -> (angle: Double, radius: Double) {
        let p = CharacterCatalog.shared.planes[plane], incline = p.inclination * .pi / 180
        let u = point.x * cos(p.node) + point.y * sin(p.node), v = (-point.x * sin(p.node) + point.y * cos(p.node)) / cos(incline)
        return (atan2(v, u), hypot(u, v))
    }

    private func replay(_ name: String, device: String? = nil) throws {
        let steps = try XCTUnwrap(sequences()[name])
        let presence = try JSONDecoder().decode([PhoneComputerPresence].self, from: Data(#"[{"id":"studio","name":"Studio","inReach":true}]"#.utf8))
        // The phone draws the desktop's ring at its own scale, so the eight crewmates of the captain's ask fit an iPhone.
        let share = (device == nil ? 1 : CharacterCatalog.shared.ring["remoteShare"]!) * PhoneSceneRoster.ringScale
        let cache = PhoneSceneRoster.Cache(), motion = PhoneSceneMotion()
        _ = cache.read(board: try board([], arrived: [:], program: nil, device: device, seq: 0), presence: presence, homeName: "Mac", inReach: true, generation: 1, revision: 0)
        var present: [String] = [], arrived: [String: Int] = [:]
        for (index, step) in steps.enumerated() {
            present.removeAll { step.leave?.contains($0) == true }
            for id in step.arrive ?? [] { present.append(id); arrived[id] = arrived.count + 1 }
            let seq = index + 1
            let roster = cache.read(board: try board(present, arrived: arrived, program: step.program, device: device, seq: seq), presence: presence,
                                    homeName: "Mac", inReach: true, generation: 1, revision: seq)
            guard let crew = step.crew, !present.isEmpty else { continue }
            let computer = try XCTUnwrap(roster.computers.first { $0.id == (device ?? "home") })
            let frame = motion.frame(roster: roster, now: 0, settled: true)
            let label = "\(name) step \(index + 1)"
            XCTAssertEqual(Set(computer.book.crew.keys), Set(present), label)
            // Each crewmate is on the orbit the desktop chose for it.
            for (id, reading) in crew { XCTAssertEqual(computer.book.crew[id]?.plane, Int(reading[0]), "\(label): \(id)'s orbit") }
            let marks = frame.marks.filter { $0.computerID == computer.id }
            XCTAssertEqual(Set(marks.map(\.task.id)), Set((step.marks ?? [:]).keys), label)
            // Each orbit has the desktop's size, its crew and program rings evenly spaced around it. Which of several
            // equal gaps a newcomer takes rests on the last bit of the desktop's rounding, so the turn of the whole
            // orbit is not compared.
            for plane in CharacterCatalog.shared.planes.indices {
                let desktop = crew.values.filter { Int($0[0]) == plane }.map { CGPoint(x: $0[1], y: $0[2]) }
                guard let expected = desktop.first.map({ Self.polar($0, plane: plane).radius }) else { continue }
                let parts = Set(step.program?.parts ?? [])
                var points = frame.glyphs.filter { computer.book.crew[$0.task.id]?.plane == plane && !parts.contains($0.task.id) }
                    .map { CGPoint(x: ($0.point.x - $0.center.x) / share, y: ($0.point.y - $0.center.y) / share) }
                XCTAssertEqual(points.count, desktop.count, "\(label): crew on orbit \(plane)")
                if plane == 0 { points += marks.map { CGPoint(x: ($0.point.x - $0.center.x) / share, y: ($0.point.y - $0.center.y) / share) } }
                let places = points.map { Self.polar($0, plane: plane) }
                for place in places { XCTAssertEqual(place.radius, expected, accuracy: 1e-4, "\(label): orbit \(plane)'s size") }
                let seats = places.count
                let angles = places.map(\.angle).sorted()
                for (i, angle) in angles.enumerated().dropFirst() {
                    let gap = angle - angles[i - 1]
                    XCTAssertEqual(gap, 2 * .pi / Double(seats), accuracy: 1e-6, "\(label): orbit \(plane)'s visible spacing")
                }
            }
            if computer.programs.isEmpty, !present.isEmpty {
                XCTAssertEqual(computer.radius, try XCTUnwrap(step.outer) * share, accuracy: 1e-4, "\(label): the area follows the first orbit")
            }
        }
    }

    /// Growth, two orbits and no third, refills from the second orbit, and a new start from empty.
    func testHomeSeatsMatchTheDesktop() throws { try replay("ring") }
    /// Another computer's group follows the same rule at the desktop's share of home's size.
    func testAnotherComputerSeatsAtItsShare() throws { try replay("ring", device: "studio") }
    /// A program's ring sits on the first orbit; branch parts keep logical membership but no angular reservation.
    func testProgramRingSitsOnTheFirstOrbit() throws { try replay("program") }

    /// INF-1375 approved A: only visible occupants take angular space, on both native devices.
    func testVisibleSeatsCloseWaitAndReviewGapsAndOpenOnReturn() throws {
        let ids = (1...8).map { "crew-\($0)" }, arrived = Dictionary(uniqueKeysWithValues: (1...8).map { ("crew-\($0)", $0) })
        for device in [nil, "studio"] as [String?] {
            let presence = try JSONDecoder().decode([PhoneComputerPresence].self, from: Data(#"[{"id":"studio","name":"Studio","inReach":true}]"#.utf8))
            let cache = PhoneSceneRoster.Cache(), motion = PhoneSceneMotion()
            func read(_ seq: Int, waits: [String: String] = [:], reviews: [String: String] = [:], crew: [String]? = nil) throws -> PhoneSceneRoster {
                cache.read(board: try board(crew ?? ids, arrived: arrived, program: nil, device: device, seq: seq, waits: waits, reviews: reviews), presence: presence,
                           homeName: "Mac", inReach: true, generation: 1, revision: seq)
            }
            func even(_ frame: PhoneSceneMotion.Frame, roster: PhoneSceneRoster, offMain: Set<String> = []) throws {
                let computer = try XCTUnwrap(roster.computers.first { $0.id == (device ?? "home") })
                let share = computer.share * PhoneSceneRoster.ringScale
                for plane in CharacterCatalog.shared.planes.indices {
                    let glyphs = frame.glyphs.filter { computer.book.crew[$0.task.id]?.plane == plane && !offMain.contains($0.task.id) }
                    let places = glyphs.map { Self.polar(CGPoint(x: ($0.point.x - $0.center.x) / share, y: ($0.point.y - $0.center.y) / share), plane: plane) }
                    let angles = places.map(\.angle).sorted()
                    for place in places { XCTAssertEqual(place.radius, PhoneSceneRoster.desktopRadius(plane, counts: computer.book.counts), accuracy: 1e-5) }
                    for (i, angle) in angles.enumerated() {
                        let next = angles[(i + 1) % angles.count] + (i == angles.count - 1 ? 2 * .pi : 0)
                        XCTAssertEqual(next - angle, 2 * .pi / Double(angles.count), accuracy: 1e-6)
                    }
                }
            }
            let ordinary = try read(1)
            try even(motion.frame(roster: ordinary, now: 0, settled: true), roster: ordinary)
            let waiting = try read(2, waits: ["crew-2": "crew-1"])
            let waitFrame = motion.frame(roster: waiting, now: 0, settled: true)
            try even(waitFrame, roster: waiting, offMain: ["crew-2"])
            XCTAssertEqual(waitFrame.links.count, 1)
            // Photograph the production painter, not a proposed drawing or a pixel golden.
            if device == nil {
                for (name, roster, frame) in [("ordinary", ordinary, PhoneSceneMotion().frame(roster: ordinary, now: 0, settled: true)), ("waiting", waiting, waitFrame)] {
                    let paint = CharacterPainter.Cache()
                    let renderer = ImageRenderer(content: Canvas { context, _ in
                        PhoneCrewPainter.draw(frame, roster: roster, now: 0, still: true, in: &context, palette: paint.palette(context.environment))
                        var center = context; center.translateBy(x: roster.homeX - 140, y: roster.height / 2 - 140)
                        CharacterPainter.draw(.still(.idle, at: 0), in: &center, size: CGSize(width: 280, height: 280), cache: paint)
                    }.frame(width: roster.width, height: roster.height).background(PhoneTheme.background).environment(\.colorScheme, .dark))
                    renderer.scale = 2
                    let picture = XCTAttachment(image: try XCTUnwrap(renderer.uiImage))
                    picture.name = "native-scene-eight-\(name)"; picture.lifetime = .keepAlways; add(picture)
                }
            }
            let review = try read(3, reviews: ["crew-2": "crew-1"])
            try even(motion.frame(roster: review, now: 0, settled: true), roster: review, offMain: ["crew-2"])
            let returned = try read(4)
            try even(motion.frame(roster: returned, now: 0, settled: true), roster: returned)
            let fallback = try read(5, reviews: Dictionary(uniqueKeysWithValues: (2...5).map { ("crew-\($0)", "crew-1") }))
            try even(motion.frame(roster: fallback, now: 0, settled: true), roster: fallback)
            let departed = try read(6, crew: ids.filter { $0 != "crew-2" })
            try even(motion.frame(roster: departed, now: 0, settled: true), roster: departed)
            // A fresh scene at restart resolves the same seven visible seats without a prior frame.
            try even(PhoneSceneMotion().frame(roster: waiting, now: 0, settled: true), roster: waiting, offMain: ["crew-2"])
        }
    }

    /// INF-1375: exercise the real native view through wait start/end, retaining its real-speed recording.
    func testRelationshipCircleReturnsInTheNativeView() async throws {
        let ids = (1...8).map { "crew-\($0)" }, arrived = Dictionary(uniqueKeysWithValues: (1...8).map { ("crew-\($0)", $0) })
        let cache = PhoneSceneRoster.Cache()
        func roster(_ sequence: Int, waiting: Bool) throws -> PhoneSceneRoster {
            cache.read(board: try board(ids, arrived: arrived, program: nil, device: nil, seq: sequence, waits: waiting ? ["crew-2": "crew-1"] : [:]), presence: [], homeName: "Mac", inReach: true, generation: 1, revision: sequence)
        }
        let stage = OrbitGapStage(try roster(1, waiting: false))
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        defer { window.isHidden = true; window.rootViewController = nil }
        CharacterCues.greetingPending = false
        window.rootViewController = UIHostingController(rootView: OrbitGapView(stage: stage, bounds: window.bounds.size))
        window.makeKeyAndVisible()
        func ticks(_ count: Int) async {
            let sample = DisplaySample(ticks: count)
            let result = await sample.complete(within: 20)
            sample.stop(); XCTAssertEqual(result, .completed)
            XCTAssertEqual(stage.crew.current.glyphs.count, ids.count)
        }
        func capture(_ action: String) async throws {
            let control = try XCTUnwrap(ProcessInfo.processInfo.environment["PHONE_TEST_HOME"])
            var request = URLRequest(url: try XCTUnwrap(URL(string: control + "/" + action)))
            request.httpMethod = "POST"
            let (_, response) = try await URLSession.shared.data(for: request)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        }
        await ticks(60)
        try await capture("capture-orbit-gap-start")
        stage.roster = try roster(2, waiting: true)
        await ticks(180)
        XCTAssertEqual(stage.crew.current.links.count, 1)
        stage.roster = try roster(3, waiting: false)
        await ticks(180)
        XCTAssertTrue(stage.crew.current.links.isEmpty)
        try await capture("capture-stop")
    }

    /// INF-1532, the captain's choice A: near the scene's edge a waiter's circle shrinks instead of throwing the
    /// waiter back to its main orbit for part of each loop. Through a whole turn of its blocker on a crowded home,
    /// the waiter stays on its circle and its glyph stays inside the scene.
    func testWaiterKeepsItsShrinkingCircleInsideTheScene() throws {
        for count in [19, 24] {
            let crew = (1...count).map { "crew-\($0)" }
            let arrived = Dictionary(uniqueKeysWithValues: crew.enumerated().map { ($1, $0 + 1) })
            let roster = PhoneSceneRoster(board: try board(crew, arrived: arrived, program: nil, device: nil, seq: 1, waits: ["crew-2": "crew-1"]),
                                          presence: [], homeName: "Mac", inReach: true, generation: 1)
            let computer = try XCTUnwrap(roster.computers.first { $0.id == "home" })
            let plane = try XCTUnwrap(computer.book.crew["crew-1"]?.plane)
            let full = CharacterCatalog.shared.dependency["radiusPx"]! * PhoneSceneRoster.ringScale * computer.share
            let motion = PhoneSceneMotion(), start = 4.0, turn = 360 / abs(CharacterCatalog.shared.planes[plane].speedDegPerSec)
            var worstGap = 0.0
            // Let the waiter glide onto its circle, then follow every frame of one loop.
            for step in 0...Int((start + turn) * 60) {
                let now = Double(step) / 60, frame = motion.frame(roster: roster, now: now, settled: false)
                guard now >= start else { continue }
                let glyphs = Dictionary(uniqueKeysWithValues: frame.glyphs.map { ($0.task.id, $0) })
                let waiter = try XCTUnwrap(glyphs["crew-2"]), blocker = try XCTUnwrap(glyphs["crew-1"])
                worstGap = max(worstGap, hypot(waiter.point.x - blocker.point.x, waiter.point.y - blocker.point.y))
                XCTAssertLessThanOrEqual(abs(waiter.point.x - waiter.center.x) + waiter.size / 2, computer.width / 2, "\(count) crew at \(now) s")
                XCTAssertLessThanOrEqual(abs(waiter.point.y - waiter.center.y) + waiter.size / 2, roster.height / 2, "\(count) crew at \(now) s")
            }
            XCTAssertLessThanOrEqual(worstGap, full + 1, "\(count) crew: the waiter left its circle")
        }
    }

    /// The captain's ask: "by default 8 crewmates should all be visible on a portrait screen on ios". Through a whole
    /// turn of the first orbit, every one of eight crewmates stays inside the narrowest portrait iPhone around home.
    func testEightCrewmatesFitTheNarrowestPortraitIPhone() throws {
        let crew = (1...8).map { "crew-\($0)" }
        let arrived = Dictionary(uniqueKeysWithValues: crew.enumerated().map { ($1, $0 + 1) })
        let roster = PhoneSceneRoster(board: try board(crew, arrived: arrived, program: nil, device: nil, seq: 1), presence: [],
                                      homeName: "Mac", inReach: true, generation: 1)
        let motion = PhoneSceneMotion(), half = PhoneSceneRoster.narrowestPortraitWidth / 2
        let turn = 360 / abs(CharacterCatalog.shared.planes[0].speedDegPerSec)
        for step in 0...Int(turn * 4) {
            let frame = motion.frame(roster: roster, now: Double(step) / 4, settled: false)
            XCTAssertEqual(frame.glyphs.count, crew.count)
            for glyph in frame.glyphs {
                XCTAssertLessThanOrEqual(abs(glyph.point.x - roster.homeX) + glyph.size / 2, half, "\(glyph.task.id) at \(Double(step) / 4) s")
            }
        }
    }
}

/// The recording renders the production scene in an owned native test window.
@Observable @MainActor private final class OrbitGapStage {
    var roster: PhoneSceneRoster
    let renderer = PhoneSceneRenderer()
    var crew: PhoneSceneMotion { renderer.crew }
    init(_ roster: PhoneSceneRoster) { self.roster = roster }
}
@MainActor private struct OrbitGapView: View {
    let stage: OrbitGapStage
    let bounds: CGSize
    var body: some View {
        PhoneSceneSurface(renderer: stage.renderer, roster: stage.roster, state: .idle, still: false, running: true)
            .frame(width: stage.roster.width, height: stage.roster.height)
            .offset(x: bounds.width / 2 - stage.roster.homeX, y: bounds.height / 2 - stage.roster.height / 2)
            .frame(width: bounds.width, height: bounds.height, alignment: .topLeading).clipped()
            .background(PhoneTheme.background).environment(\.colorScheme, .dark)
    }
}
