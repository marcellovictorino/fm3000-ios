import CoreFoundation
import SwiftUI
import XCTest
@testable import Infinitary

/// INF-1066: the captain asked for smooth native motion and CI before/after frame timing.
/// Observe the actual PhoneCharacter in a visible host window on each disposable simulator.
/// Timing is evidence, not a wall-clock pass/fail budget on a shared CI computer: each sample's
/// callbacks are due on the load clock, which counts the app's own progress (INF-1506).
@MainActor final class PhoneSceneEvidenceTests: XCTestCase {
    /// INF-1066: photographs of every approved native form, using the same painter as the running scene.
    func testEveryNativeFormHasAVisibleDrawing() throws {
        let modes = CharacterMachine.Mode.allCases.filter { $0 != .fidget }
        let forms: [(CharacterMachine.Mode, CharacterMachine.Fidget?)] = modes.map { ($0, nil) }
            + CharacterMachine.Fidget.allCases.map { (.fidget, $0) }
        for theme in [ColorScheme.dark, .light] {
            var drawings = Set<Data>()
            for (mode, variant) in forms {
                var pose = CharacterPose(mode: mode, progress: 0.4, variant: variant, cur: .of(mode), heat: mode == .working ? 1 : 0, milliseconds: 2200)
                pose.lid = pose.cur.lidBase
                let reply = CharacterReply.frame(mode, pose.progress)
                pose.happy = reply.happy; pose.lid = max(pose.lid, reply.lid)
                let frame = pose
                let renderer = ImageRenderer(content: Canvas { context, size in CharacterPainter.draw(frame, in: &context, size: size) }
                    .frame(width: 280, height: 280).padding(16).background(PhoneTheme.background).environment(\.colorScheme, theme))
                renderer.scale = 2
                let image = try XCTUnwrap(renderer.uiImage), png = try XCTUnwrap(image.pngData())
                drawings.insert(png)
                let picture = XCTAttachment(image: image)
                picture.name = "native-scene-\(variant?.rawValue ?? mode.rawValue)-\(theme == .dark ? "dark" : "light")"
                picture.lifetime = .keepAlways; add(picture)
            }
            XCTAssertEqual(drawings.count, forms.count, "Every approved form has its own rendered geometry")
        }
    }

    /// INF-1066: a full-scene timing sample must not count its nested first-mate draw twice.
    func testFrameSamplesKeepTheirDrawingScopeAndSource() {
        let metrics = CharacterFrameMetrics()
        let pose = CharacterPose.still(.idle, at: 0)
        func record(_ drawing: CharacterFrameMetrics.Drawing, source: String = "visible-scene") {
            metrics.record(start: ProcessInfo.processInfo.systemUptime, source: source,
                           mode: pose.mode.rawValue, heat: pose.heat, rotation: pose.a, drawing: drawing)
        }
        metrics.start(source: "visible-scene", drawing: .scene)
        record(.character); record(.scene); record(.scene, source: "another-window")
        XCTAssertEqual(metrics.finish().count, 1, "Only the complete drawing from the selected scene enters its sample")
        metrics.start(source: "visible-scene")
        record(.scene); record(.character)
        XCTAssertEqual(metrics.finish().count, 1, "The isolated first-mate sample still selects its own painter")
    }

    /// INF-1143 asks for evidence of main-thread progress, not an assumption from missing display ticks.
    func testWarmupTraceRecordsActualMainRunLoopProgress() async {
        let trace = NativeSceneRunLoopTrace()
        let serviced = XCTestExpectation(description: "The main run loop reaches its source phase")
        guard let witness = CFRunLoopObserverCreateWithHandler(nil, CFRunLoopActivity.beforeSources.rawValue, false, 1, { _, _ in serviced.fulfill() }) else {
            _ = trace.finish()
            XCTFail("The test could not observe the main run loop")
            return
        }
        // Observe that phase after the trace's order-zero observer, rather than assuming which turn
        // services a queued block. The completion witness is the actual run-loop event.
        CFRunLoopAddObserver(CFRunLoopGetMain(), witness, .commonModes)
        defer { CFRunLoopRemoveObserver(CFRunLoopGetMain(), witness, .commonModes) }
        let result = await XCTWaiter.fulfillment(of: [serviced], timeout: 5)
        let entries = trace.finish()
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(entries.first?.event, "warmup-start")
        XCTAssertEqual(entries.last?.event, "warmup-end")
        XCTAssertTrue(entries.contains { $0.event == "before-sources" })
        XCTAssertTrue(entries.allSatisfy(\.mainThread))
        XCTAssertEqual(entries.map(\.uptime), entries.map(\.uptime).sorted())
    }

    /// INF-1378: a missing display callback must name the phase and actual progress, not an enum mismatch.
    func testStoppedDisplaySampleNamesMissingCallbacks() async {
        let trace = NativeSceneRunLoopTrace(phase: "sample")
        let sample = DisplaySample(ticks: 2)
        sample.stop() // The display link cannot deliver any callbacks, independent of host load.
        // INF-1506: the load clock still ends a wait whose callbacks never come, by its wall cap at most.
        let budget: TimeInterval = 0.05, started = ProcessInfo.processInfo.systemUptime
        let result = await sample.complete(within: budget, graded: false)
        let elapsed = ProcessInfo.processInfo.systemUptime - started
        let entries = trace.finish()
        let diagnostic = sample.diagnostic(phase: "sample", result: result, heartbeat: entries)
        XCTAssertEqual(result, .timedOut)
        // One polling turn of scheduling tolerance, as PhoneWaitsTests allows its missing file.
        XCTAssertLessThanOrEqual(elapsed, phoneRequestBudget(budget) + 0.3, diagnostic)
        XCTAssertTrue(sample.timestamps.isEmpty)
        XCTAssertTrue(diagnostic.contains("phase=sample result=timed-out callbacks=0/2"), diagnostic)
        XCTAssertTrue(diagnostic.contains("callback_gap_max_s="), diagnostic)
        XCTAssertTrue(diagnostic.contains("run_loop_gap_max_s="), diagnostic)
        XCTAssertEqual(entries.first?.event, "sample-start")
        XCTAssertEqual(entries.last?.event, "sample-end")
        print("NATIVE_SCENE_DIAGNOSTIC_CONTROL \(diagnostic)")
    }

    /// INF-1506: run 40423926011's iPhone idle sample timed out with a 2.37-second gap between
    /// callbacks and a 2.36-second main-run-loop gap on a busy Mac mini, while the same code passed
    /// on main 20 minutes later. A stall of the app's own main thread is the host's load, not a
    /// missing screen update, so it must not spend the callbacks' budget.
    func testMainThreadStallDoesNotSpendTheDisplayBudget() async {
        let stall: TimeInterval = 2.37, budget: TimeInterval = 2
        let sample = DisplaySample(ticks: 6)
        // Queued behind this turn, so it stops the main thread after the wait has started.
        DispatchQueue.main.async { Thread.sleep(forTimeInterval: stall) }
        let started = ProcessInfo.processInfo.systemUptime
        let result = await sample.complete(within: budget, graded: false)
        let elapsed = ProcessInfo.processInfo.systemUptime - started
        let diagnostic = sample.diagnostic(phase: "stalled", result: result, heartbeat: [])
        XCTAssertGreaterThanOrEqual(elapsed, stall, "The stall happened during the wait, so a wall-clock budget would have expired; \(diagnostic)")
        XCTAssertEqual(result, .completed, "The display delivers its callbacks after the stall; \(diagnostic)")
        print("NATIVE_SCENE_DIAGNOSTIC_CONTROL \(diagnostic)")
    }

    /// INF-1378: replay the elapsed time in run 942's idle sample through the real motion owner.
    /// Its warmup ran from 3206.08689925 to 3212.570454041667; its sample reached 19.86 seconds.
    /// A long idle sample can reach an automatic fidget without any other window contaminating it.
    func testLongIdleSampleNamesTheActualUnexpectedMode() {
        let greeting = CharacterCues.greetingPending
        CharacterCues.greetingPending = false
        defer { CharacterCues.greetingPending = greeting }
        let motion = CharacterMotion(), metrics = CharacterFrameMetrics()
        _ = motion.advance(to: 0, state: .idle)
        let warmup = 3212.570454041667 - 3206.08689925
        let before = motion.advance(to: warmup, state: .idle)
        let after = motion.advance(to: warmup + 19.86, state: .idle)
        XCTAssertEqual(before.mode, .idle)
        XCTAssertEqual(after.mode, .fidget)
        metrics.start(source: "idle")
        for pose in [before, after] {
            metrics.record(start: ProcessInfo.processInfo.systemUptime, source: "idle",
                           mode: pose.mode.rawValue, heat: pose.heat, rotation: pose.a)
        }
        let frames = metrics.finish()
        let diagnostic = nativeSceneFrameDiagnostic(frames, expectedModes: [PhoneCharacter.State.idle.rawValue])
        XCTAssertFalse(frames.allSatisfy { $0.mode == PhoneCharacter.State.idle.rawValue },
                       "The former idle-only expectation rejects this sample")
        XCTAssertTrue(diagnostic.contains("modes=fidget:1,idle:1"), diagnostic)
        XCTAssertTrue(diagnostic.contains("unexpected=fidget:1"), diagnostic)
        XCTAssertTrue(diagnostic.contains("first_unexpected=fidget"), diagnostic)
        print("NATIVE_SCENE_DIAGNOSTIC_CONTROL \(diagnostic)")

        // INF-1378, captain-approved: accept automatic fidgets only in idle samples.
        let idleModes = nativeSceneExpectedModes(state: .idle)
        XCTAssertTrue(frames.allSatisfy { idleModes.contains($0.mode) })
        XCTAssertEqual(idleModes, Set([CharacterMachine.Mode.idle.rawValue, CharacterMachine.Mode.fidget.rawValue]))
        XCTAssertEqual(nativeSceneExpectedModes(state: .idle, reaction: .salute), idleModes.union([CharacterMachine.Mode.salute.rawValue]))
        for state in [PhoneCharacter.State.working, .listening] {
            let expected = nativeSceneExpectedModes(state: state)
            XCTAssertEqual(expected, Set([state.rawValue]), "No automatic fidget exception outside idle")
            XCTAssertFalse(frames.allSatisfy { expected.contains($0.mode) }, "Idle and fidget drawings cannot prove \(state.rawValue)")
        }
        let accepted = nativeSceneFrameDiagnostic(frames, expectedModes: idleModes)
        XCTAssertTrue(accepted.contains("unexpected=none"), accepted)
        print("NATIVE_SCENE_IDLE_FIDGET_CONTROL \(accepted)")
    }

    func testNativeSceneCadenceEvidence() async throws {
        #if targetEnvironment(simulator)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        defer { window.isHidden = true; window.rootViewController = nil }
        var pictures = Set<Data>()
        for state in [PhoneCharacter.State.idle, .working] {
            CharacterCues.greetingPending = false
            window.rootViewController = UIHostingController(rootView: PhoneCharacter(state: state)
                .frame(width: 200, height: 200).frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(PhoneTheme.background).environment(\.colorScheme, .dark)
                .environment(\.scenePhase, .active).environment(\.characterEvidenceSource, state.rawValue).id(state.rawValue))
            window.makeKeyAndVisible()
            pictures.insert(try await recordNativeSceneCadence(window: window, state: state, source: state.rawValue))
        }
        XCTAssertEqual(pictures.count, 2, "Idle and working captures must show different target states")
        #else
        throw XCTSkip("This evidence uses only a disposable simulator")
        #endif
    }
}

@MainActor extension XCTestCase {
    /// The same display-tick sample observes the isolated first mate and the production crowded scene.
    func recordNativeSceneCadence(window: UIWindow, state: PhoneCharacter.State, source: String,
                                  drawing: CharacterFrameMetrics.Drawing = .character,
                                  reaction: (CharacterMotion, CharacterMachine.Emote)? = nil) async throws -> Data {
        // Warmup and sample end on display callbacks, not a sleeping guess about when drawing starts.
        // A static waiter does not send this shared XCTestCase extension's non-Sendable self.
        let runLoop = NativeSceneRunLoopTrace()
        let warmup = DisplaySample(ticks: 60)
        let warmupResult = await warmup.complete(within: 20)
        warmup.stop()
        let heartbeat = runLoop.finish()
        let warmupDiagnostic = "source=\(source) " + warmup.diagnostic(phase: "warmup", result: warmupResult, heartbeat: heartbeat)
        XCTAssertEqual(warmupResult, .completed, "The display completes the warmup callbacks; \(warmupDiagnostic)")
        let sampleRunLoop = NativeSceneRunLoopTrace(phase: "sample")
        CharacterFrameMetrics.shared.start(source: source, drawing: drawing)
        if let (character, emote) = reaction { character.request(emote) }
        let sample = DisplaySample(ticks: 240)
        let sampleResult = await sample.complete(within: 20)
        sample.stop()
        let frames = CharacterFrameMetrics.shared.finish()
        let sampleHeartbeat = sampleRunLoop.finish()
        let expectedModes = nativeSceneExpectedModes(state: state, reaction: reaction?.1)
        let sampleDiagnostic = "source=\(source) " + sample.diagnostic(phase: "sample", result: sampleResult, heartbeat: sampleHeartbeat)
            + " " + nativeSceneFrameDiagnostic(frames, expectedModes: expectedModes)
        // INF-1378 changed only the captain-approved idle-fidget expectation, and INF-1506 only the
        // clock the 20-second budgets run on. Every other predicate stays, naming missing callbacks,
        // a missing drawing or an unexpected animation mode.
        XCTAssertEqual(sampleResult, .completed, "The display completes the sampled callbacks; \(sampleDiagnostic)")
        XCTAssertGreaterThan(frames.count, 1, "The visible native character actually draws; \(sampleDiagnostic)")
        XCTAssertTrue(frames.allSatisfy { expectedModes.contains($0.mode) }, "Only the named target Canvas's expected states enter the sample; \(sampleDiagnostic)")
        if let (_, emote) = reaction {
            XCTAssertTrue(frames.contains { $0.mode == emote.rawValue }, "The native drawing must actually play the requested emote; \(sampleDiagnostic)")
        }
        if state == .working { XCTAssertTrue(frames.allSatisfy { $0.heat > 0.8 }, "Working proof includes its warmed ember, not another window's idle drawing; \(sampleDiagnostic)") }
        XCTAssertNotEqual(frames.first?.rotation, frames.last?.rotation, "The sampled target actually advances its pose; \(sampleDiagnostic)")
        let intervals = zip(frames.dropFirst(), frames).map { $0.timestamp - $1.timestamp }.sorted()
        let displayIntervals = zip(sample.timestamps.dropFirst(), sample.timestamps).map { $0 - $1 }.sorted()
        let work = frames.map(\.work).sorted()
        let duration = (frames.last?.timestamp ?? 0) - (frames.first?.timestamp ?? 0)
        func p95(_ values: [Double]) -> Double { values.isEmpty ? 0 : values[min(values.count - 1, Int(Double(values.count) * 0.95))] }
        let summary = "source=\(source) state=\(state.rawValue) frames=\(frames.count) fps=\(Double(max(0, frames.count - 1)) / max(duration, 0.001)) interval_p95_ms=\(p95(intervals) * 1000) interval_max_ms=\((intervals.last ?? 0) * 1000) draw_p95_ms=\(p95(work) * 1000) display_p95_ms=\(p95(displayIntervals) * 1000) display_ticks=\(sample.timestamps.count)"
        let minimumHeat = frames.map(\.heat).min().map { String($0) } ?? "unknown"
        let warmupSummary = "source=\(source) ticks=\(warmup.timestamps.count) completed=\(warmupResult == .completed) sample_completed=\(sampleResult == .completed) minimum_heat=\(minimumHeat)"
        print("NATIVE_SCENE_WARMUP \(warmupSummary)")
        let warmupProof = XCTAttachment(string: warmupSummary + "\ntimestamp\n" + warmup.timestamps.map { String($0) }.joined(separator: "\n"))
        warmupProof.name = "native-scene-\(source)-warmup"; warmupProof.lifetime = .keepAlways; add(warmupProof)
        let heartbeatProof = XCTAttachment(string: "uptime,event,main_thread\n" + heartbeat.map { "\($0.uptime),\($0.event),\($0.mainThread)" }.joined(separator: "\n"))
        heartbeatProof.name = "native-scene-\(source)-main-run-loop"; heartbeatProof.lifetime = .keepAlways; add(heartbeatProof)
        print("NATIVE_SCENE_RUN_LOOP source=\(source) events=\(heartbeat.count) start=\(heartbeat.first?.uptime ?? 0) end=\(heartbeat.last?.uptime ?? 0)")
        print("NATIVE_SCENE_DIAGNOSTIC \(warmupDiagnostic)")
        print("NATIVE_SCENE_DIAGNOSTIC \(sampleDiagnostic)")
        let sampleProof = XCTAttachment(string: sampleDiagnostic + "\nuptime,event,main_thread\n"
            + sampleHeartbeat.map { "\($0.uptime),\($0.event),\($0.mainThread)" }.joined(separator: "\n"))
        sampleProof.name = "native-scene-\(source)-sample-main-run-loop"; sampleProof.lifetime = .keepAlways; add(sampleProof)
        let displayProof = XCTAttachment(string: sampleDiagnostic + "\ntimestamp\n" + sample.timestamps.map { String($0) }.joined(separator: "\n"))
        displayProof.name = "native-scene-\(source)-display"; displayProof.lifetime = .keepAlways; add(displayProof)
        print("NATIVE_SCENE_TIMING \(summary)")
        let csv = summary + "\ntimestamp,draw_seconds,mode,heat,rotation\n" + frames.map { "\($0.timestamp),\($0.work),\($0.mode),\($0.heat),\($0.rotation)" }.joined(separator: "\n")
        let attachment = XCTAttachment(string: csv)
        attachment.name = "native-scene-\(source)-timing"; attachment.lifetime = .keepAlways; add(attachment)
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let png = try XCTUnwrap(image.pngData())
        let picture = XCTAttachment(image: image)
        picture.name = "native-scene-\(source)"; picture.lifetime = .keepAlways; add(picture)
        return png
    }
}

@MainActor final class DisplaySample: NSObject {
    private let requested: Int
    private var remaining: Int
    private var link: CADisplayLink?
    private let started = ProcessInfo.processInfo.systemUptime
    private var received: [Double] = []
    private(set) var timestamps: [Double] = []
    init(ticks: Int) {
        requested = ticks
        remaining = ticks
        super.init()
        let link = CADisplayLink(target: self, selector: #selector(tick))
        self.link = link
        link.add(to: .main, forMode: .common)
    }
    @objc private func tick(_ link: CADisplayLink) {
        received.append(ProcessInfo.processInfo.systemUptime)
        timestamps.append(link.timestamp); remaining -= 1
        if remaining == 0 { stop() }
    }
    func stop() { link?.invalidate(); link = nil }

    /// INF-1506: the requested callbacks are due within `budget` on the load clock, read on the
    /// main thread that receives them. A stalled or starved app counts at most two ticks per
    /// stall, so a busy host does not spend the budget; a display link that stops delivering
    /// while the app runs still fails within it, and every wait still ends by its wall cap.
    func complete(within budget: TimeInterval, graded: Bool = gradesBudgets) async -> XCTWaiter.Result {
        var deadline = PhoneWaitDeadline(budget, graded: graded)
        while remaining > 0 {
            if deadline.expired() { return .timedOut }
            do { try await Task.sleep(for: .seconds(PhoneWaitDeadline.tick)) } catch { return .interrupted }
        }
        return .completed
    }

    func diagnostic(phase: String, result: XCTWaiter.Result, heartbeat: [NativeSceneRunLoopTrace.Entry]) -> String {
        let ended = ProcessInfo.processInfo.systemUptime
        let outcome: String
        switch result {
        case .completed: outcome = "completed"
        case .timedOut: outcome = "timed-out"
        case .incorrectOrder: outcome = "incorrect-order"
        case .invertedFulfillment: outcome = "inverted-fulfillment"
        case .interrupted: outcome = "interrupted"
        @unknown default: outcome = "unknown-\(result.rawValue)"
        }
        // Include the unsampled tails: no callback at all is a whole-wait gap, never a zero gap.
        func largestGap(_ times: [Double]) -> Double {
            zip(times.dropFirst(), times).map { $0 - $1 }.max() ?? 0
        }
        let callbackGap = largestGap([started] + received + [ended])
        let runLoopGap = largestGap(heartbeat.map(\.uptime))
        let serviced = heartbeat.filter { $0.event == "before-sources" }.count
        return "phase=\(phase) result=\(outcome) callbacks=\(timestamps.count)/\(requested) elapsed_s=\(ended - started) callback_gap_max_s=\(callbackGap) run_loop_source_phases=\(serviced) run_loop_gap_max_s=\(runLoopGap)"
    }
}

/// INF-1378, captain-approved: a slow idle sample may reach the character's automatic fidget.
/// Requested reactions remain explicit; working and listening gain no automatic mode exception.
private func nativeSceneExpectedModes(state: PhoneCharacter.State, reaction: CharacterMachine.Emote? = nil) -> Set<String> {
    var modes: Set<String> = [state.rawValue]
    if state == .idle { modes.insert(CharacterMachine.Mode.fidget.rawValue) }
    if let reaction { modes.insert(reaction.rawValue) }
    return modes
}

/// Facts only: a mode mismatch does not establish another window's draw, and a gap does not prove load.
private func nativeSceneFrameDiagnostic(_ frames: [CharacterFrameMetrics.Frame], expectedModes: Set<String>) -> String {
    func counts(_ frames: [CharacterFrameMetrics.Frame]) -> String {
        let grouped = Dictionary(grouping: frames, by: \.mode)
        return grouped.keys.sorted().map { "\($0):\(grouped[$0]!.count)" }.joined(separator: ",")
    }
    let unexpected = frames.filter { !expectedModes.contains($0.mode) }
    let firstUnexpected = unexpected.first.map { "\($0.mode) at_offset_s=\($0.timestamp - (frames.first?.timestamp ?? $0.timestamp))" } ?? "none"
    let heat = frames.map(\.heat).min().map { String($0) } ?? "unknown"
    let rotation = "\(frames.first.map { String($0.rotation) } ?? "unknown")..\(frames.last.map { String($0.rotation) } ?? "unknown")"
    return "frames=\(frames.count) expected=\(expectedModes.sorted().joined(separator: ",")) modes=\(counts(frames)) unexpected=\(unexpected.isEmpty ? "none" : counts(unexpected)) first_unexpected=\(firstUnexpected) minimum_heat=\(heat) rotation=\(rotation)"
}
