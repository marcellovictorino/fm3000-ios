import SwiftUI
import XCTest
@testable import Infinitary
@testable import InfinitaryKit

/// INF-1066: real published board/pairing readings own the scene, not names or invented activity.
/// The disposable home seeds through TaskService and its routing/pairing owners; no accounts or real computers.
@MainActor final class PhoneSceneRosterTests: XCTestCase {
    private func home(_ action: String) async throws -> [String: Any] {
        let control = try XCTUnwrap(ProcessInfo.processInfo.environment["PHONE_TEST_HOME"])
        var request = URLRequest(url: try XCTUnwrap(URL(string: control + "/" + action)))
        request.httpMethod = "POST"
        let (data, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200, String(decoding: data, as: UTF8.self))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
    private func captureCrowdedScene(_ roster: PhoneSceneRoster, state: PhoneCharacter.State, reply: CharacterMachine.Emote? = nil) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene), renderer = PhoneSceneRenderer()
        defer { window.isHidden = true; window.rootViewController = nil }
        CharacterCues.greetingPending = false
        let bounds = window.bounds, character = renderer.character
        let source = "crowded-" + (reply?.rawValue ?? state.rawValue)
        window.rootViewController = UIHostingController(rootView: PhoneSceneSurface(
            renderer: renderer, roster: roster, state: state, still: false, running: true)
            .frame(width: roster.width, height: roster.height)
            .offset(x: bounds.width / 2 - roster.homeX, y: bounds.height / 2 - roster.height / 2)
            .frame(width: bounds.width, height: bounds.height, alignment: .topLeading).clipped()
            .background(PhoneTheme.background).environment(\.colorScheme, .dark)
            .environment(\.characterEvidenceSource, source))
        window.makeKeyAndVisible()
        _ = try await recordNativeSceneCadence(window: window, state: state, source: source, drawing: .scene, reaction: reply.map { (character, $0) })
    }

    /// INF-2566, the captain's approved direction B: "the scene on its own render thread". While the main thread is
    /// held, as a busy board read or a card's web view once held it, the crowded scene keeps drawing and moving.
    private func drawThroughMainThreadStall(_ roster: PhoneSceneRoster) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene), renderer = PhoneSceneRenderer()
        defer { window.isHidden = true; window.rootViewController = nil }
        CharacterCues.greetingPending = false
        let source = "crowded-stall"
        window.rootViewController = UIHostingController(rootView: PhoneSceneSurface(
            renderer: renderer, roster: roster, state: .working, still: false, running: true)
            .frame(width: roster.width, height: roster.height)
            .background(PhoneTheme.background).environment(\.colorScheme, .dark)
            .environment(\.characterEvidenceSource, source))
        window.makeKeyAndVisible()
        let warmup = DisplaySample(ticks: 30)
        let warmed = await warmup.complete(within: 20)
        XCTAssertEqual(warmed, .completed, "The display warms up before the stall")
        warmup.stop()
        CharacterFrameMetrics.shared.start(source: source, drawing: .scene)
        // Hold the main thread for a second, as a long synchronous main-thread job would.
        let held = ProcessInfo.processInfo.systemUptime
        usleep(1_000_000)
        let released = ProcessInfo.processInfo.systemUptime
        let after = DisplaySample(ticks: 10)
        _ = await after.complete(within: 20)
        after.stop()
        let frames = CharacterFrameMetrics.shared.finish()
        let during = frames.filter { $0.timestamp > held && $0.timestamp < released }
        let summary = "frames=\(frames.count) during_stall=\(during.count) stall_s=\(released - held)"
        print("NATIVE_SCENE_STALL \(summary)")
        XCTAssertGreaterThan(during.count, 1, "The scene draws while the main thread is held; \(summary)")
        XCTAssertNotEqual(during.first?.rotation, during.last?.rotation, "The scene moves while the main thread is held; \(summary)")
    }

    /// Approved batch gate: real task delivery facts name the batch; the native painter turns only an active batch.
    /// Disposable paired home, no provider or external forge. Completion is the roster, row words and rendered pixels.
    func testBatchGateMatchesTheDesktopAndOnlyAnActiveBatchTurns() async throws {
        for state in ["waiting", "in-batch", "paused"] {
            let fixture = try await home("scene-batch-" + state)
            do {
                let board = try JSONDecoder().decode(PhoneBoard.self, from: JSONSerialization.data(withJSONObject: XCTUnwrap(fixture["board"])))
                let computers = try JSONDecoder().decode([PhoneComputerPresence].self, from: JSONSerialization.data(withJSONObject: XCTUnwrap(fixture["computers"])))
                let id = try XCTUnwrap(fixture["checks"] as? String)
                let roster = PhoneSceneRoster(board: board, presence: computers, homeName: "Test computer", inReach: true, generation: 1)
                let motion = PhoneSceneMotion()
                let frame = motion.frame(roster: roster, now: 0, settled: true)
                var glyph = try XCTUnwrap(frame.glyphs.first { $0.task.id == id })
                XCTAssertTrue(glyph.batch); XCTAssertEqual(glyph.batchRunning, state == "in-batch")
                XCTAssertEqual(glyph.wait, 1); XCTAssertEqual(glyph.work, 0); XCTAssertEqual(glyph.job, 0)
                let status = PhoneTaskFacts.status(glyph.task)
                XCTAssertEqual(status.label, "Working · Waiting for the batch check")
                XCTAssertEqual(PhoneTaskList.word(glyph.task), PhoneTaskRowWords.batch)
                XCTAssertEqual(glyph.task.group, .working)
                if state == "waiting" {
                    let cache = CharacterPainter.Cache()
                    let renderer = ImageRenderer(content: Canvas { context, _ in
                        PhoneCrewPainter.draw(frame, roster: roster, now: 0, still: true, in: &context, palette: cache.palette(context.environment))
                        var center = context; center.translateBy(x: roster.homeX - 140, y: roster.height / 2 - 140)
                        CharacterPainter.draw(.still(.idle, at: 0), in: &center, size: CGSize(width: 280, height: 280), cache: cache)
                    }.frame(width: roster.width, height: roster.height).background(PhoneTheme.background).environment(\.colorScheme, .dark))
                    renderer.scale = 1
                    let picture = XCTAttachment(image: try XCTUnwrap(renderer.uiImage))
                    picture.name = "native-scene-batch-gate-formations-dark"
                    picture.lifetime = .keepAlways; add(picture)
                }
                // Freeze solid orientation and placement so any pixel difference comes from the batch gate alone.
                glyph.point = CGPoint(x: 60, y: 60); glyph.spin = 0
                let fixed = glyph
                func picture(_ at: Double, _ still: Bool, _ theme: ColorScheme) throws -> UIImage {
                    let cache = CharacterPainter.Cache()
                    let renderer = ImageRenderer(content: VStack(spacing: 8) {
                        Canvas { context, _ in
                            PhoneCrewPainter.draw(PhoneSceneMotion.Frame(glyphs: [fixed], marks: [], packets: [], links: []), roster: roster,
                                                  now: at, still: still, in: &context, palette: cache.palette(context.environment))
                        }.frame(width: 120, height: 120)
                        HStack { PhoneTaskMark(status: status); Text(PhoneTaskRowWords.batch).font(PhoneFont.micro).foregroundStyle(PhoneTheme.secondary) }
                    }.padding(12).background(PhoneTheme.background).environment(\.colorScheme, theme))
                    renderer.scale = 3
                    return try XCTUnwrap(renderer.uiImage)
                }
                let start = try picture(0, false, .dark), later = try picture(2, false, .dark)
                if state == "in-batch" { XCTAssertNotEqual(start.pngData(), later.pngData()) }
                else { XCTAssertEqual(start.pngData(), later.pngData()) }
                XCTAssertEqual(try picture(0, true, .dark).pngData(), try picture(2, true, .dark).pngData())
                for theme in [ColorScheme.dark, .light] {
                    let attachment = XCTAttachment(image: try picture(0, true, theme))
                    attachment.name = "native-batch-gate-\(state)-\(theme == .dark ? "dark" : "light")"
                    attachment.lifetime = .keepAlways; add(attachment)
                }
            } catch { _ = try? await home("scene-cleanup"); throw error }
            _ = try await home("scene-cleanup")
        }
    }

    func testPublicFactsKeepEveryLiveGlyphAndSettleReconnects() async throws {
        let fixture = try await home("scene-fixture")
        do {
            let board = try JSONDecoder().decode(PhoneBoard.self, from: JSONSerialization.data(withJSONObject: XCTUnwrap(fixture["board"])))
            let computers = try JSONDecoder().decode([PhoneComputerPresence].self, from: JSONSerialization.data(withJSONObject: XCTUnwrap(fixture["computers"])))
            let programID = try XCTUnwrap(fixture["program"] as? String), remoteID = try XCTUnwrap(fixture["remote"] as? String)
            let plannedID = try XCTUnwrap(fixture["planned"] as? String), finishedID = try XCTUnwrap(fixture["finished"] as? String)
            let cache = PhoneSceneRoster.Cache()
            let roster = cache.read(board: board, presence: computers, homeName: "Test Mac mini", inReach: true, generation: 1, revision: board.seq)
            // INF-1066: loading the real roster must preserve home, not add a second resize-anchor shift.
            let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
            let size = windowScene.coordinateSpace.bounds.size
            func viewport(_ reading: PhoneSceneRoster, _ size: CGSize, generation: Int = 1) -> PhoneSceneViewport {
                PhoneSceneViewport(scene: CGSize(width: reading.width, height: reading.height),
                                   home: CGPoint(x: reading.homeX, y: reading.height / 2), size: size, generation: generation)
            }
            let empty = PhoneSceneRoster(board: nil, presence: [], homeName: "Test Mac mini", inReach: false, generation: 1)
            let before = viewport(empty, size), loaded = viewport(roster, size)
            let initial = loaded.preserving(before.centered, from: before)
            XCTAssertEqual(initial.x, loaded.centered.x, accuracy: 0.000001)
            XCTAssertEqual(initial.y, loaded.centered.y, accuracy: 0.000001)
            let panned = loaded.clamped(CGPoint(x: initial.x + 44, y: initial.y))
            let resized = viewport(roster, CGSize(width: size.height, height: size.width))
            let retained = resized.preserving(panned, from: loaded)
            XCTAssertEqual(retained.x + resized.size.width / 2 - resized.home.x,
                           panned.x + loaded.size.width / 2 - loaded.home.x, accuracy: 0.000001)
            XCTAssertEqual(retained.y + resized.size.height / 2 - resized.home.y,
                           panned.y + loaded.size.height / 2 - loaded.home.y, accuracy: 0.000001)
            let joined = viewport(roster, size, generation: 2)
            XCTAssertEqual(joined.preserving(panned, from: loaded), joined.centered)
            // Compare the native layout to readings from the desktop owner, using this same public task graph.
            let layouts = try XCTUnwrap(fixture["desktopLayouts"] as? [[String: Any]])
            for layout in layouts {
                let computerID = try XCTUnwrap(layout["computerID"] as? String)
                let places = try XCTUnwrap(layout["places"] as? [String: [String: Any]])
                let program = try XCTUnwrap(roster.computers.first { $0.id == computerID }?.programs.first { $0.id == programID })
                XCTAssertEqual(Set(program.branches.map(\.id)), Set(places.keys))
                for branch in program.branches {
                    let expected = try XCTUnwrap(places[branch.id])
                    XCTAssertEqual(cos(branch.angle) * branch.distance, try XCTUnwrap(expected["x"] as? Double), accuracy: 0.000001)
                    XCTAssertEqual(sin(branch.angle) * branch.distance, try XCTUnwrap(expected["y"] as? Double), accuracy: 0.000001)
                }
            }
            let motion = PhoneSceneMotion()
            // The empty view can appear before its first read. That read must still settle, not animate a boot roster.
            _ = motion.frame(roster: PhoneSceneRoster(board: nil, presence: [], homeName: "Test Mac mini", inReach: false, generation: 1), now: 0, settled: false)
            let first = motion.frame(roster: roster, now: 1, settled: false)
            let expected = board.tasks.filter { $0.kind == "work" && $0.status == "active" && $0.program != true }
            XCTAssertEqual(Set(first.glyphs.map(\.task.id)), Set(expected.map(\.id)))
            XCTAssertFalse(first.glyphs.contains { [plannedID, finishedID, programID].contains($0.task.id) })
            XCTAssertTrue(first.glyphs.allSatisfy { $0.alpha == 1 && $0.unfold == 1 }, "The initial roster must not replay arrivals")
            XCTAssertTrue(first.packets.isEmpty)
            XCTAssertEqual(Set(first.marks.map(\.id)).count, first.marks.count, "One program may have real parts on more than one computer")
            XCTAssertEqual(Set(first.marks.flatMap(\.parts)), Set(expected.filter { $0.parentId == programID }.map(\.id)))
            XCTAssertTrue(first.marks.allSatisfy { $0.task.id == programID })
            // INF-1543, the captain's direction A: the crewmate under Waiting on you wears the beacon, and only it.
            let waitingID = try XCTUnwrap(fixture["waiting"] as? String)
            XCTAssertEqual(first.glyphs.filter { $0.captain > 0 }.map(\.task.id), [waitingID])
            XCTAssertEqual(first.glyphs.first { $0.task.id == waitingID }?.task.group, .waiting)
            XCTAssertEqual(first.glyphs.first { $0.task.id == waitingID }?.captain, 1)
            // INF-1777: a background command and a checks watch both rest banked inside the wait ring, ember wires only for the local one.
            let jobID = try XCTUnwrap(fixture["job"] as? String), checksID = try XCTUnwrap(fixture["checks"] as? String)
            XCTAssertEqual(Set(first.glyphs.filter { $0.wait > 0 }.map(\.task.id)), [jobID, checksID])
            let job = try XCTUnwrap(first.glyphs.first { $0.task.id == jobID }), checks = try XCTUnwrap(first.glyphs.first { $0.task.id == checksID })
            XCTAssertEqual(job.wait, 1); XCTAssertEqual(job.job, 1); XCTAssertEqual(job.work, 0)
            XCTAssertEqual(checks.wait, 1); XCTAssertEqual(checks.job, 0); XCTAssertEqual(checks.work, 0)
            let remote = try XCTUnwrap(first.glyphs.first { $0.task.id == remoteID })
            XCTAssertTrue(remote.unknown); XCTAssertEqual(remote.work, 0)
            // INF-1854, the captain's "on desktop i think we shrink them a little": another computer's crew draw at the
            // desktop's cluster glyph, smaller than home's crowded one (computers.ts, orbit.ts), not one size for all.
            let ring = CharacterCatalog.shared.ring
            XCTAssertEqual(remote.px, ring["remoteGlyphPx"]); XCTAssertLessThan(remote.px, try XCTUnwrap(ring["glyphPx"]))
            let homeCrew = first.glyphs.filter { $0.task.executionDeviceId == nil && !$0.programPart }
            XCTAssertFalse(homeCrew.isEmpty); XCTAssertTrue(homeCrew.allSatisfy { $0.px == ring["glyphPx"] })
            let advanced = motion.frame(roster: roster, now: 2, settled: false)
            XCTAssertEqual(advanced.glyphs.first { $0.task.id == remoteID }?.point, remote.point)
            XCTAssertEqual(advanced.glyphs.first { $0.task.id == remoteID }?.spin, remote.spin)
            // INF-2566: the render thread draws on between touch-down and the tap's recognition (the phone check's iPhone
            // rest part missed an orbiting crewmate so), so a tap reads the frame on screen when the finger landed.
            let riding = PhoneSceneMotion()
            _ = riding.frame(roster: empty, now: 0, settled: false)
            let shown = riding.frame(roster: roster, now: 1, settled: false)
            let landedAt = ProcessInfo.processInfo.systemUptime
            var drawnOn = shown
            for tick in 1...120 { drawnOn = riding.frame(roster: roster, now: 1 + Double(tick) / 60, settled: false) }
            let touches = PhoneSceneTouchView(crew: riding)
            touches.roster = roster
            let landed = riding.frame(at: landedAt)
            XCTAssertEqual(landed.glyphs.map(\.point), shown.glyphs.map(\.point), "Touch-down reads the frame on screen then")
            func travel(_ glyph: PhoneSceneMotion.Glyph) -> Double {
                guard let later = drawnOn.glyphs.first(where: { $0.task.id == glyph.task.id }) else { return 0 }
                return max(abs(later.point.x - glyph.point.x), abs(later.point.y - glyph.point.y))
            }
            let rider = try XCTUnwrap(shown.glyphs.filter { $0.task.executionDeviceId == nil && !$0.programPart }.max { travel($0) < travel($1) })
            XCTAssertGreaterThan(travel(rider), 22, "\(rider.task.title) leaves its 44-point square over two seconds of frames")
            XCTAssertEqual(touches.target(at: rider.point, in: landed)?.id, rider.task.id, "A finger on its drawn place opens it")
            XCTAssertNotEqual(touches.target(at: rider.point)?.id, rider.task.id, "The latest frame no longer has it there")
            // INF-1520: a reachable crewmate whose posture reads unknown/unobserved, the reviewer among them, still orbits as on the desktop.
            let reviewID = try XCTUnwrap(fixture["review"] as? String)
            let unobserved = first.glyphs.filter { $0.task.executionDeviceId == nil && $0.task.workPosture?.state == "unknown" }
            XCTAssertTrue(unobserved.contains { $0.task.id == reviewID }, "The fixture's reviewer must read unknown/unobserved")
            for glyph in unobserved {
                let moved = try XCTUnwrap(advanced.glyphs.first { $0.task.id == glyph.task.id })
                XCTAssertFalse(moved.unknown, "\(glyph.task.title) is on a reachable computer")
                XCTAssertNotEqual(moved.point, glyph.point, "\(glyph.task.title) must keep orbiting")
            }
            let lost = PhoneSceneRoster(board: board, presence: computers, homeName: "Test Mac mini", inReach: false, generation: 1)
            let disconnected = motion.frame(roster: lost, now: 3, settled: false)
            let later = motion.frame(roster: lost, now: 4, settled: false)
            for glyph in disconnected.glyphs {
                XCTAssertTrue(glyph.unknown)
                XCTAssertEqual(later.glyphs.first { $0.task.id == glyph.task.id }?.point, glyph.point, "Unknown activity stays frozen across later callbacks")
            }
            let resumed = motion.frame(roster: PhoneSceneRoster(board: board, presence: computers, homeName: "Test Mac mini", inReach: true, generation: 2), now: 5, settled: false)
            XCTAssertTrue(resumed.glyphs.allSatisfy { $0.alpha == 1 && $0.unfold == 1 })
            XCTAssertTrue(resumed.packets.isEmpty)
            // Reduced Motion produces one legible still in both themes, with every tier and live program part.
            let still = motion.frame(roster: roster, now: 0, settled: true)
            for theme in [ColorScheme.dark, .light] {
                let cache = CharacterPainter.Cache()
                let renderer = ImageRenderer(content: Canvas { context, _ in
                    PhoneCrewPainter.draw(still, roster: roster, now: 0, still: true, in: &context, palette: cache.palette(context.environment))
                    var center = context; center.translateBy(x: roster.homeX - 140, y: roster.height / 2 - 140)
                    CharacterPainter.draw(.still(.idle, at: 0), in: &center, size: CGSize(width: 280, height: 280), cache: cache)
                }.frame(width: roster.width, height: roster.height).background(PhoneTheme.background).environment(\.colorScheme, theme))
                renderer.scale = 1
                let picture = XCTAttachment(image: try XCTUnwrap(renderer.uiImage))
                picture.name = "native-scene-complete-formations-\(theme == .dark ? "dark" : "light")"
                picture.lifetime = .keepAlways; add(picture)
            }
            // INF-1543: the beacon up close, at its brightest and on the still frame, in both themes.
            let beacon = try XCTUnwrap(still.glyphs.first { $0.task.id == waitingID })
            for (name, at, settled) in [("bright", 1.6, false), ("still", 0.0, true)] {
                var lit = beacon; lit.captainSince = 0
                let frame = PhoneSceneMotion.Frame(glyphs: [lit], marks: [], packets: [], links: [])
                for theme in [ColorScheme.dark, .light] {
                    let cache = CharacterPainter.Cache()
                    let renderer = ImageRenderer(content: Canvas { context, _ in
                        context.translateBy(x: 60 - beacon.point.x, y: 60 - beacon.point.y)
                        PhoneCrewPainter.draw(frame, roster: roster, now: at, still: settled, in: &context, palette: cache.palette(context.environment))
                    }.frame(width: 120, height: 120).background(PhoneTheme.background).environment(\.colorScheme, theme))
                    renderer.scale = 3
                    let picture = XCTAttachment(image: try XCTUnwrap(renderer.uiImage))
                    picture.name = "native-scene-waiting-on-you-\(name)-\(theme == .dark ? "dark" : "light")"
                    picture.lifetime = .keepAlways; add(picture)
                }
            }
            // Include the production scene's glyph targets, shared drawing and full real task roster in its cadence evidence.
            try await captureCrowdedScene(roster, state: .working)
            try await captureCrowdedScene(roster, state: .idle, reply: .salute)
            try await drawThroughMainThreadStall(roster)
            let stage = try await home("scene-stage-finished")
            let finishedBoard = try JSONDecoder().decode(PhoneBoard.self, from: JSONSerialization.data(withJSONObject: XCTUnwrap(stage["board"])))
            let between = cache.read(board: finishedBoard, presence: computers, homeName: "Test Mac mini", inReach: true, generation: 1, revision: finishedBoard.seq)
            let waiting = motion.frame(roster: between, now: 0, settled: true)
            XCTAssertEqual(Set(waiting.marks.map(\.id)), Set(first.marks.map(\.id)), "Each seen computer keeps its program ring between stages")
            XCTAssertTrue(waiting.marks.allSatisfy { $0.parts.isEmpty }, "A retained ring invents no finished, planned or remote placeholder dots")
            let fresh = PhoneSceneRoster.Cache().read(board: finishedBoard, presence: computers, homeName: "Test Mac mini", inReach: true, generation: 1, revision: finishedBoard.seq)
            XCTAssertTrue(fresh.computers.allSatisfy { $0.programs.isEmpty }, "A new scene never reconstructs a program it has not seen run")
        } catch { _ = try? await home("scene-cleanup"); throw error }
        _ = try await home("scene-cleanup")
    }
}
