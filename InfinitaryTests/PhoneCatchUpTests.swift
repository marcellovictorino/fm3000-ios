import Foundation
import Observation
import XCTest
@testable import InfinitaryKit

/// INF-2773, the captain's pick "keep what they showed, then change once when the catch-up is read": a reopen that
/// replays what the phone missed reads every missed update into its own copy and changes the screens once. A reaction
/// from while the phone was away stays silent (docs/ios.md, the crew scene), and a live one after the catch-up plays.
/// Runs against the disposable real-core home, as `PhoneReopenTests` does.
@MainActor final class PhoneCatchUpTests: XCTestCase {
    private func home(_ command: String) async throws -> [String: Any] {
        let control = try XCTUnwrap(ProcessInfo.processInfo.environment["PHONE_TEST_HOME"])
        var request = URLRequest(url: try XCTUnwrap(URL(string: control + "/" + command)))
        request.httpMethod = "POST"
        let (data, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200, String(decoding: data, as: UTF8.self))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func until(_ what: String, _ done: () -> Bool) async throws {
        var deadline = PhoneWaitDeadline(30)
        while !done() {
            if deadline.expired() { throw PhoneError.refused("Never saw: \(what)") }
            try await Task.sleep(for: .seconds(PhoneWaitDeadline.tick))
        }
    }

    /// Each change the screens are told of: every assignment of the shown board or cards, as SwiftUI observes them.
    @MainActor private final class Shown {
        private(set) var boards = 0
        private(set) var cards = 0
        private let session: ReadOnlySession
        init(_ session: ReadOnlySession) { self.session = session; watchBoard(); watchCards() }
        private func watchBoard() {
            withObservationTracking { _ = session.board } onChange: { [weak self] in
                Task { @MainActor in self?.boards += 1; self?.watchBoard() }
            }
        }
        private func watchCards() {
            withObservationTracking { _ = session.cards } onChange: { [weak self] in
                Task { @MainActor in self?.cards += 1; self?.watchCards() }
            }
        }
    }

    func testACatchUpChangesTheScreensOnceAndPlaysNoReactionFromWhileAway() async throws {
        #if !targetEnvironment(simulator)
        throw PhoneError.refused("This check requires a disposable simulator.")
        #endif
        _ = try await home("remove")
        let invitation = try await home("link")
        let link = try JoinLink(XCTUnwrap(invitation["link"] as? String))
        let phone = try PhoneIdentity.loadOrCreate()
        let transport = PinnedTransport(pin: link.pin, phone: phone, purpose: .pairing)
        let mac = try await transport.pair(link, name: "Catch-up test phone")
        transport.close()
        let session = ReadOnlySession(mac: mac, phone: phone)
        var emotes: [String] = []
        session.onEmote = { emotes.append($0) }
        session.start()
        defer { session.stop() }
        // The harmless read waits for every first read, so the next welcome replays rather than reading again.
        _ = try await session.read(.past, [.string("no-such-catch-up-card")])
        XCTAssertEqual(session.contact, "in-reach")

        // Away: the connection is closed while the computer adds six tasks, one board update each, two cards, one card
        // list each, and a reaction. One at a time, the screens would change six times and twice.
        session.stop()
        let away = try await home("away-traffic")
        let added = try XCTUnwrap(away["ids"] as? [String])
        let cards = try XCTUnwrap(away["cards"] as? [String])
        XCTAssertEqual(cards.count, 2)
        let shown = Shown(session)
        session.start()
        try await until("the board and cards from while away") {
            let ids = Set(session.board?.tasks.map(\.id) ?? [])
            let shownCards = Set(session.cards.map(\.id))
            return added.allSatisfy(ids.contains) && cards.allSatisfy(shownCards.contains)
        }
        XCTAssertEqual(shown.boards, 1, "The catch-up of six board updates changed the shown board once")
        XCTAssertEqual(shown.cards, 1, "The catch-up of two card lists changed the shown cards once")
        XCTAssertEqual(emotes, [], "A reaction from while the phone was away did not play")

        // The board read into the held copy is the one the computer reads fresh.
        let fresh = try await session.request(.board, as: PhoneBoard.self)
        try await until("the board at the fresh read's version") { (session.board?.seq ?? -1) >= fresh.seq }
        XCTAssertEqual(session.board?.seq, fresh.seq)
        XCTAssertEqual(session.board?.tasks.map(\.id), fresh.tasks.map(\.id))
        XCTAssertEqual(session.board?.tasks.map(\.status), fresh.tasks.map(\.status))

        _ = try await home("emote")
        try await until("the live reaction") { emotes == ["ponder"] }
        _ = try await home("away-cleanup")
        _ = try await home("remove")
    }
}
