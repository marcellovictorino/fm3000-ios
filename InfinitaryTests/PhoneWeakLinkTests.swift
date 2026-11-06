import Foundation
import XCTest
@testable import InfinitaryKit

/// INF-2668, the captain: "i feel the ios app’s connection to the home has been flaky sometimes. it would flip between
/// out of reach and reaching a few times. this is especially prominent when the network condition is not strong like
/// when i’m out on mobile." Each test is one of the seven checks of INF-2666's direction B, run against the disposable
/// real-core home through its relay, which shapes the path as a weak cell does. Every connection dials the relay only.
@MainActor final class PhoneWeakLinkTests: XCTestCase {
    private func home(_ command: String, _ body: [String: Any]? = nil, method: String = "POST") async throws -> [String: Any] {
        let control = try XCTUnwrap(ProcessInfo.processInfo.environment["PHONE_TEST_HOME"])
        var request = URLRequest(url: try XCTUnwrap(URL(string: control + "/" + command)))
        request.httpMethod = method
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200, String(decoding: data, as: UTF8.self))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    /// The relay's connections so far, each with the bytes it carried down to the phone, and the ones it refused.
    private func readings() async throws -> (dials: [[String: Any]], refused: Int) {
        let read = try await home("relay-readings", method: "GET")
        return (try XCTUnwrap(read["dials"] as? [[String: Any]]), try XCTUnwrap(read["refused"] as? Int))
    }

    private func shape(bytesPerSec: Int, delayMs: Int) async throws {
        _ = try await home("relay-shape", ["bytesPerSec": bytesPerSec, "delayMs": delayMs])
    }

    /// A phone joined to a fresh home whose welcome names no address of its own, so every dial goes through the relay.
    private func joined() async throws -> ReadOnlySession {
        #if !targetEnvironment(simulator)
        throw PhoneError.refused("Weak link checks require a disposable simulator.")
        #endif
        _ = try await home("remove")
        _ = try await home("routing-reset")
        _ = try await home("routing-legacy")
        let relay = try await home("relay-thaw")
        let through = try XCTUnwrap(relay["address"] as? String)
        let invitation = try await home("link")
        let link = try JoinLink(XCTUnwrap(invitation["link"] as? String))
        let phone = try PhoneIdentity.loadOrCreate()
        let transport = PinnedTransport(pin: link.pin, phone: phone, purpose: .pairing)
        defer { transport.close() }
        let mac = try await transport.pair(link, name: "Weak link test phone")
        return ReadOnlySession(mac: JoinedMac(addresses: [through], pin: mac.pin, deviceID: mac.deviceID, name: mac.name),
                               phone: phone)
    }

    private func finish(_ session: ReadOnlySession) async throws {
        session.stop()
        _ = try await home("relay-thaw")
        _ = try await home("remove")
    }

    /// Every change of the words, the connection and the buzz count, polled as the screens would see them.
    @MainActor final class Watch {
        struct Seen { let at: Double; let reach: String; let contact: String; let returns: Int }
        private(set) var seen: [Seen] = []
        private var poll: Task<Void, Never>?
        let started = ContinuousClock.now
        var now: Double { Double((ContinuousClock.now - started).components.attoseconds) / 1e18
            + Double((ContinuousClock.now - started).components.seconds) }

        init(_ session: ReadOnlySession) {
            poll = Task { @MainActor [weak self] in
                while !Task.isCancelled, let self {
                    let last = self.seen.last
                    if last?.reach != session.reach || last?.contact != session.contact || last?.returns != session.returns {
                        self.seen.append(Seen(at: self.now, reach: session.reach, contact: session.contact, returns: session.returns))
                    }
                    try? await Task.sleep(for: .milliseconds(10))
                }
            }
        }
        deinit { poll?.cancel() }

        /// How many times the words turned to `words` at or after `since`.
        func said(_ words: String, since: Double = 0) -> Int {
            zip([nil] + seen.map(Optional.some), seen).filter { before, now in
                now.at >= since && now.reach == words && before?.reach != words
            }.count
        }

        /// Waits until `condition` holds, failing after `seconds`.
        func until(_ seconds: Double, _ what: String, _ condition: () -> Bool) async throws {
            let deadline = now + seconds
            while !condition() {
                if now > deadline { XCTFail("Not within \(seconds) s: \(what)"); throw PhoneError.unavailable }
                try await Task.sleep(for: .milliseconds(20))
            }
        }

        /// When, on this watch's clock, the phone last heard the computer.
        func quietSince(_ session: ReadOnlySession) throws -> Double {
            now - Date().timeIntervalSince(try XCTUnwrap(session.heardAt))
        }

        func hold(_ seconds: Double) async throws { try await Task.sleep(for: .milliseconds(Int(seconds * 1000))) }
    }

    private func inReach(_ session: ReadOnlySession, _ watch: Watch, within seconds: Double) async throws {
        try await watch.until(seconds, "in reach") { session.contact == "in-reach" }
    }

    /// Waits for the phone to be in reach on the relay's `dials`th connection: a redial can take milliseconds.
    private func inReach(_ session: ReadOnlySession, _ watch: Watch, on dials: Int, within seconds: Double) async throws {
        let deadline = watch.now + seconds
        while true {
            let count = try await readings().dials.count
            if count >= dials, session.contact == "in-reach" { return }
            if watch.now > deadline { XCTFail("Not in reach on connection \(dials) within \(seconds) s"); throw PhoneError.unavailable }
            try await Task.sleep(for: .milliseconds(50))
        }
    }

    /// INF-2666 measured a 1 KB/s link with 300 ms delay flipping between Out of reach and Reaching every 8 to 10 s,
    /// never in reach, since its catch-up could not finish inside a fixed 10 s. The computer itself pings every 30 s and
    /// cuts a phone whose answer has not come by the next ping, and its ping waits behind the catch-up on the same link,
    /// so the link carries this home's whole catch-up in about 40 s: 1 KB/s for a small record, faster for a grown one.
    func testASlowLinkReachesInReachAndStays() async throws {
        let measuring = try await joined()
        let sizing = Watch(measuring)
        measuring.start()
        try await inReach(measuring, sizing, within: 30)
        let measured = try await readings().dials
        let size = try XCTUnwrap(measured.first?["down"] as? Int)
        measuring.stop()
        _ = try await home("relay-thaw")
        // A phone with nothing read yet, so its catch-up is the whole record again.
        let session = ReadOnlySession(mac: measuring.mac, phone: try PhoneIdentity.loadOrCreate())
        try await shape(bytesPerSec: max(1_000, size / 40), delayMs: 300)
        let watch = Watch(session)
        session.start()
        try await inReach(session, watch, within: 60)
        try await watch.hold(30)
        XCTAssertEqual(session.contact, "in-reach")
        XCTAssertEqual(watch.said("lost"), 0, "Out of reach never shows while the slow path stays up")
        let dials = try await readings().dials
        XCTAssertEqual(dials.count, 1, "One dial carried the whole catch-up of \(size) bytes")
        try await finish(session)
    }

    /// INF-2666 measured a record standing in for the captain's, in reach on a good link, then weakened to 4 KB/s and
    /// dropped: six dials, each cut 10 s in, for the whole weak spell, though the welcome replayed nothing missed. The
    /// home's own record is used here, since cards seeded into it would stay for the journeys sharing the home.
    func testADropOnAWeakLinkComesBackFromTheReplay() async throws {
        let session = try await joined()
        let watch = Watch(session)
        session.start()
        try await inReach(session, watch, within: 30)
        // The home goes on sending what its seeding started after the phone is in reach; drop once it has gone quiet.
        var first = -1
        for _ in 0..<40 {
            let now = try await readings().dials
            let down = try XCTUnwrap(now.first?["down"] as? Int)
            if down == first { break }
            first = down
            try await watch.hold(1)
        }
        try await shape(bytesPerSec: 4_000, delayMs: 300)
        let dropped = watch.now
        _ = try await home("relay-drop")
        try await inReach(session, watch, on: 2, within: 30)
        try await watch.hold(10)
        let dials = try await readings().dials
        XCTAssertEqual(dials.count, 2, "One redial")
        let again = try XCTUnwrap(dials.last?["down"] as? Int)
        XCTAssertLessThan(again, first / 2, "The replaying welcome read nothing again: \(again) bytes after \(first)")
        XCTAssertLessThanOrEqual(watch.said("reaching", since: dropped), 1, "Reaching shows at most once")
        XCTAssertEqual(watch.said("lost", since: dropped), 0)
        XCTAssertEqual(session.contact, "in-reach")
        try await finish(session)
    }

    /// INF-2666 measured a 3 s stall with a network change during it: the 2 s check cut the live connection, the line
    /// said Reaching for a second, and the phone buzzed. The network change is `start()` on the running session.
    func testAStallWithANetworkChangeKeepsTheConnection() async throws {
        let session = try await joined()
        let watch = Watch(session)
        session.start()
        try await inReach(session, watch, within: 30)
        let since = watch.now
        _ = try await home("relay-stall", ["ms": 3_000])
        try await watch.hold(0.1)
        session.start()
        try await watch.hold(6)
        let dials = try await readings().dials
        XCTAssertEqual(dials.count, 1, "The kept connection stayed")
        XCTAssertNil(session.lastCut)
        XCTAssertTrue(watch.seen.filter { $0.at >= since }.allSatisfy { $0.reach == "in-reach" }, "The line says nothing")
        XCTAssertEqual(session.returns, 0)
        try await finish(session)
    }

    /// A reopen's check keeps a connection that goes on receiving, but an answer already on its way when the ping left
    /// says nothing about the path after it. Phone check run 41980677158 caught the reopen check skipping its doubt for
    /// such an answer, so a dead path waited for the silence cut instead of being replaced once the check ran out.
    func testAnAnswerAlreadyOnItsWayDoesNotKeepADeadPath() async throws {
        let session = try await joined()
        let relay = try await home("relay-thaw")
        let direct = try XCTUnwrap(relay["at"] as? String)
        let watch = Watch(session)
        session.start()
        try await inReach(session, watch, within: 30)
        session.found(addresses: [direct])
        // A second each way: the read reaches the home after one and its answer is on the way down for the next.
        try await shape(bytesPerSec: 0, delayMs: 1_000)
        let asked = Task { try? await session.read(.past, [.string("no-such-weak-link-card")]) }
        try await watch.hold(1.5)
        _ = try await home("relay-freeze")
        let frozen = Date()
        session.start()
        try await watch.until(30, "the reopen's check replaced the frozen connection") { session.lastCut != nil }
        XCTAssertGreaterThan(try XCTUnwrap(session.heardAt), frozen, "The answer on its way arrived after the reopen's ping")
        XCTAssertEqual(session.lastCut, .unanswered, "The reopen's check, not the silence, cut the frozen connection")
        try await inReach(session, watch, within: 15)
        XCTAssertEqual(session.reachedAddress, direct)
        asked.cancel()
        try await finish(session)
    }

    /// INF-2666 measured a 50 s outage: 12 dials meanwhile, at most 5 s apart. Out of reach is named once the
    /// computer was quiet for the captain's 20 s, and its return buzzes, since the line said Out of reach.
    func testAnOutageDialsSeldomAndFindsTheReturn() async throws {
        let session = try await joined()
        let watch = Watch(session)
        session.start()
        try await inReach(session, watch, within: 30)
        let before = try await readings()
        _ = try await home("relay-offline")
        let gone = watch.now
        let quiet = try watch.quietSince(session)
        try await watch.hold(50)
        let during = try await readings()
        let tries = during.dials.count - before.dials.count + during.refused - before.refused
        XCTAssertLessThanOrEqual(tries, 6, "At most 6 dials in 50 s")
        let named = try XCTUnwrap(watch.seen.first { $0.at > gone && $0.reach == "lost" }, "Out of reach was named")
        XCTAssertEqual(named.at - quiet, 20, accuracy: 1.5, "Named once the computer was quiet for the captain's 20 s")
        _ = try await home("relay-online")
        try await inReach(session, watch, within: 15)
        XCTAssertEqual(session.returns, 1, "One buzz, for a return after Out of reach")
        try await finish(session)
    }

    /// INF-2666 measured a drop that redials in 10 ms: too fast to read, yet the phone buzzed for it.
    func testAnInstantRedialSaysAndBuzzesNothing() async throws {
        let session = try await joined()
        let watch = Watch(session)
        session.start()
        try await inReach(session, watch, within: 30)
        let dropped = watch.now
        _ = try await home("relay-drop")
        try await inReach(session, watch, on: 2, within: 10)
        try await watch.hold(2)
        let dials = try await readings().dials
        XCTAssertEqual(dials.count, 2)
        XCTAssertTrue(watch.seen.filter { $0.at >= dropped }.allSatisfy { $0.reach == "in-reach" }, "The line says nothing")
        XCTAssertEqual(session.returns, 0, "Nothing buzzes")
        try await finish(session)
    }

    /// A dead path is still noticed: a 32 s silence is cut after the captain's 20 s, named, and redialed.
    func testALongSilenceIsStillCutAndRedialed() async throws {
        let session = try await joined()
        let watch = Watch(session)
        session.start()
        try await inReach(session, watch, within: 30)
        _ = try await home("relay-stall", ["ms": 32_000])
        let stalled = watch.now
        let quiet = try watch.quietSince(session)
        try await watch.until(60, "in reach again after the silence") {
            session.contact == "in-reach" && watch.seen.contains { $0.at > stalled && $0.contact != "in-reach" }
        }
        XCTAssertEqual(session.lastCut, .quiet, "Silence cut the connection")
        let left = try XCTUnwrap(watch.seen.first { $0.at > stalled && $0.contact != "in-reach" })
        XCTAssertEqual(left.at - quiet, 20, accuracy: 1.5, "Cut once the computer was quiet for the captain's 20 s")
        let named = try XCTUnwrap(watch.seen.first { $0.at > stalled && $0.reach != "in-reach" }, "The line named it")
        XCTAssertLessThan(named.at - stalled, 30, "within half a minute")
        let dials = try await readings().dials
        XCTAssertGreaterThanOrEqual(dials.count, 2, "Redialed")
        try await finish(session)
    }
}
