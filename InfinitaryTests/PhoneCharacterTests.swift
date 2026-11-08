import XCTest
@testable import Infinitary

/// INF-589 item 18, approved by the captain: the phone's character greets when the app opens or joins,
/// and nods when a reply is sent, with the Mac character's own rules (src/renderer/src/character/machine.ts).
/// INF-1066 expands the approved repertoire, retaining greeting, interruption and live-only coverage.
/// Inputs replay what the phone hears in a real turn:
/// firstmate_state busy, the first mate's firstmate_emote nod during the turn, then busy ending.
@MainActor final class PhoneCharacterTests: XCTestCase {
    func testGreetsOnceOnFirstSightAndAgainAfterAJoin() {
        CharacterCues.greetingPending = true
        let opened = CharacterMotion()
        XCTAssertEqual(opened.advance(to: 100, state: .idle).mode, .greet, "The first character seen after opening greets")
        XCTAssertEqual(opened.advance(to: 101, state: .idle).mode, .greet)
        XCTAssertEqual(opened.advance(to: 102.2, state: .idle).mode, .idle, "The greeting lasts the Mac's 2.1 seconds")
        XCTAssertEqual(CharacterMotion().advance(to: 103, state: .idle).mode, .idle, "Another screen's character does not greet again")
        CharacterCues.greetOnNextSight()
        XCTAssertEqual(CharacterMotion().advance(to: 104, state: .idle).mode, .greet, "Joining a computer greets once more")
    }

    func testACharacterLeavingMidGreetingHandsTheGreetingOn() {
        CharacterCues.greetOnNextSight()
        let flashed = CharacterMotion()
        CharacterCues.shown.add(flashed)
        XCTAssertEqual(flashed.advance(to: 0, state: .idle).mode, .greet)
        CharacterCues.left(flashed)
        XCTAssertEqual(CharacterMotion().advance(to: 0.5, state: .idle).mode, .greet,
                       "The empty stage a join flashes before its cards arrive does not use up the greeting")
        CharacterCues.greetOnNextSight()
        let greeted = CharacterMotion()
        XCTAssertEqual(greeted.advance(to: 1, state: .idle).mode, .greet)
        XCTAssertEqual(greeted.advance(to: 3.2, state: .idle).mode, .idle)
        CharacterCues.left(greeted)
        XCTAssertFalse(CharacterCues.greetingPending, "A finished greeting is not played again")
    }

    func testReplyNodWaitsForTheTurnToEnd() {
        var machine = CharacterMachine(now: 0)
        machine.setInputs(listening: false, busy: true, now: 1)
        XCTAssertEqual(machine.update(now: 1).mode, .working)
        XCTAssertTrue(machine.request(.nod, now: 2))
        XCTAssertEqual(machine.update(now: 2).mode, .working, "A nod during the turn is held, not played over the work")
        machine.setInputs(listening: false, busy: false, now: 5)
        XCTAssertEqual(machine.update(now: 5).mode, .nod, "The held nod plays as the turn ends")
        XCTAssertEqual(machine.update(now: 6.5).mode, .idle, "The nod lasts the Mac's 1.4 seconds, then rests")
        machine.setInputs(listening: false, busy: true, now: 7)
        machine.setInputs(listening: false, busy: false, now: 8)
        XCTAssertEqual(machine.update(now: 8).mode, .idle, "A turn with no reply ends without a nod")
    }

    /// INF-790: a starting turn keeps the emote playing and the ember shows the turn, as on the Mac.
    func testATurnHeatsAnEmoteAndListeningInterruptsIt() {
        var machine = CharacterMachine(now: 0)
        machine.request(.greet, now: 0)
        machine.setInputs(listening: false, busy: true, now: 0.5)
        XCTAssertEqual(machine.update(now: 0.5).mode, .greet, "A starting turn lets the greeting play on")
        XCTAssertEqual(machine.update(now: 2.2).mode, .working, "The greeting ends into work")
        machine.setInputs(listening: false, busy: false, now: 3)
        machine.request(.nod, now: 3)
        machine.setInputs(listening: true, busy: false, now: 3.2)
        XCTAssertEqual(machine.update(now: 3.2).mode, .listening, "Attention interrupts the nod")
        XCTAssertFalse(machine.request(.nod, now: 3.3), "No emote plays over listening")
    }

    func testEveryApprovedEmoteReachesOnlyCharactersOnScreen() {
        CharacterCues.greetingPending = false
        for emote in CharacterMachine.Emote.allCases where CharacterMachine.seconds(emote) != nil {
            let shown = CharacterMotion(), hidden = CharacterMotion()
            _ = shown.advance(to: 0, state: .idle); _ = hidden.advance(to: 0, state: .idle)
            CharacterCues.shown.add(shown)
            CharacterCues.reacted(emote.rawValue)
            XCTAssertEqual(shown.advance(to: 0.1, state: .idle).mode, emote)
            XCTAssertEqual(hidden.advance(to: 0.1, state: .idle).mode, .idle, "Off-screen characters save no reactions")
            CharacterCues.shown.remove(shown)
        }
    }

    func testEveryReplyWaitsForTheTurnAndFirstReplyWins() {
        for emote in CharacterMachine.Emote.allCases where emote.reply {
            var machine = CharacterMachine(now: 0)
            machine.setInputs(listening: false, busy: true, now: 0)
            XCTAssertTrue(machine.request(emote, now: 0.1))
            XCTAssertFalse(machine.request(emote == .nod ? .tick : .nod, now: 0.2))
            XCTAssertEqual(machine.update(now: 0.3).mode, .working)
            machine.setInputs(listening: false, busy: false, now: 1)
            XCTAssertEqual(machine.update(now: 1).mode, emote)
            XCTAssertEqual(machine.update(now: 1 + CharacterMachine.seconds(emote)! + 0.01).mode, .idle)
        }
    }

    func testNativeRepliesMatchDesktopChoreographyReadings() throws {
        struct Trace: Decodable { let emote: String; let progress: Double; let frame: CharacterReply }
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "PhoneSceneTraces.generated", withExtension: "json"))
        let traces = try JSONDecoder().decode([Trace].self, from: Data(contentsOf: url))
        for trace in traces {
            let frame = CharacterReply.frame(try XCTUnwrap(CharacterMachine.Mode(rawValue: trace.emote)), trace.progress)
            let expected = trace.frame
            for key in [\CharacterReply.pitch, \.spin, \.rot, \.tx, \.ty, \.sx, \.sy, \.lid, \.happy, \.glow] {
                XCTAssertEqual(frame[keyPath: key], expected[keyPath: key], accuracy: 0.000000001, "\(trace.emote) at \(trace.progress)")
            }
            XCTAssertEqual(frame.gaze?.x ?? 0, expected.gaze?.x ?? 0, accuracy: 0.000000001)
            XCTAssertEqual(frame.gaze?.y ?? 0, expected.gaze?.y ?? 0, accuracy: 0.000000001)
            XCTAssertEqual(frame.pointer, expected.pointer)
            XCTAssertEqual(frame.suppressBlink, expected.suppressBlink)
        }
    }

    /// INF-3011, the captain's pick: the cinch plays for the whole shortening, as the Mac's does, its numbers the Mac's.
    func testNativeCinchMatchesDesktopReadings() throws {
        struct Reading: Decodable {
            struct Frame: Decodable { let phase: String; let k, vis, lift, holdS, u: Double }
            struct Mote: Decodable { let slot: Int; let u: Double }
            let endedAt: Double?; let t: Double; let frame: Frame?; let motes: [Mote]; let arrival: Double
        }
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "PhoneCinchTraces.generated", withExtension: "json"))
        let readings = try JSONDecoder().decode([Reading].self, from: Data(contentsOf: url))
        for reading in readings {
            let ended: String = reading.endedAt.map { "\($0)" } ?? "never"
            let label = "ended \(ended) at \(reading.t)"
            let frame = CharacterCinch.frame(reading.t, endedAt: reading.endedAt)
            guard let expected = reading.frame else { XCTAssertNil(frame, label); continue }
            let native = try XCTUnwrap(frame, label)
            XCTAssertEqual(native.phase.rawValue, expected.phase, label)
            let pairs: [(Double, Double)] = [(native.k, expected.k), (native.vis, expected.vis), (native.lift, expected.lift),
                                             (native.holdS, expected.holdS), (native.u, expected.u)]
            for (mine, theirs) in pairs { XCTAssertEqual(mine, theirs, accuracy: 0.000001, label) }
            let flight = CharacterCinch.motes(native)
            let nativeSlots: [Int] = flight.motes.map { $0.slot }, desktopSlots: [Int] = reading.motes.map { $0.slot }
            XCTAssertEqual(nativeSlots, desktopSlots, label)
            for (mine, theirs) in zip(flight.motes, reading.motes) { XCTAssertEqual(mine.u, theirs.u, accuracy: 0.000001, label) }
            XCTAssertEqual(flight.arrival, reading.arrival, accuracy: 0.000001, label)
        }
    }

    /// Inputs replay what the phone hears: firstmate_state busy, folding rising and falling inside the turn, then busy ending.
    func testShorteningDrawsTheWorkingBodyTightWithoutChangingItsState() {
        CharacterCues.greetingPending = false
        let motion = CharacterMotion()
        var fold = CharacterFold()
        var time = 0.0
        func run(to end: Double, _ state: PhoneCharacter.State) -> CharacterPose {
            var pose = motion.advance(to: time, state: state, fold: fold)
            while time < end { time += 1 / 60; pose = motion.advance(to: time, state: state, fold: fold) }
            return pose
        }
        XCTAssertNil(run(to: 1, .working).cinch, "A turn with no shortening plays no cinch")
        fold = CharacterFold(folding: true, starts: 1)
        let tight = run(to: 3, .working)
        XCTAssertEqual(tight.mode, .working, "The cinch is a look over working, never a state")
        XCTAssertEqual(tight.cinch?.phase, .hold)
        XCTAssertGreaterThan(tight.cinchK, 0.85, "Drawn tight while the shortening runs")
        fold.folding = false
        XCTAssertEqual(run(to: 3.3, .working).cinch?.phase, .out, "The ring loosens once the shortening ends")
        XCTAssertNil(run(to: 4.5, .working).cinch, "Then the body is back at rest")
        // One heard starting and ending at once still plays: the start, then the end.
        fold = CharacterFold(folding: false, starts: 2)
        XCTAssertEqual(run(to: 4.8, .working).cinch?.phase, .in)
        XCTAssertEqual(run(to: 5.7, .working).cinch?.phase, .out)
        XCTAssertNil(run(to: 6.7, .working).cinch)
    }

    func testReduceMotionHoldsTheTightPoseWhileTheShorteningRuns() {
        let still = CharacterPose.still(.working, folding: true, at: 0)
        XCTAssertEqual(still.cinchK, 1)
        XCTAssertEqual(CharacterCinch.body(still.cinchK).scale, CharacterCatalog.shared.cinch["tightness"]!, accuracy: 0.000001)
        XCTAssertNil(CharacterPose.still(.working, at: 0).cinch)
    }

    func testFidgetsUseDesktopDurationsAndDoNotRepeatTheLastPick() {
        for variant in CharacterMachine.Fidget.allCases {
            var machine = CharacterMachine(now: 0, random: { 0 })
            XCTAssertTrue(machine.request(.fidget, now: 0, variant: variant))
            XCTAssertEqual(machine.variant, variant)
            let duration = CharacterCatalog.shared.fidgets[variant.rawValue]! / 1000
            XCTAssertEqual(machine.update(now: duration / 2).progress, 0.5, accuracy: 0.000001)
            XCTAssertEqual(machine.update(now: duration).mode, .idle)
            _ = machine.update(now: duration + 9)
            XCTAssertEqual(machine.mode, .fidget)
            XCTAssertNotEqual(machine.variant, variant)
        }
    }

    func testDisplayClockExcludesStoppedTime() {
        let clock = CharacterDisplayClock()
        clock.setRunning(true)
        clock.advance(timestamp: 10); clock.advance(timestamp: 10.01)
        XCTAssertEqual(clock.now, 0.01, accuracy: 0.000001)
        clock.setRunning(false)
        XCTAssertFalse(clock.running)
        clock.setRunning(true)
        clock.advance(timestamp: 100); clock.advance(timestamp: 100.02)
        XCTAssertEqual(clock.now, 0.03, accuracy: 0.000001)
        clock.setRunning(false)
    }
}
