import SwiftUI
import XCTest
@testable import Infinitary
@testable import InfinitaryKit

/// INF-2764, the captain: "after i reopen the app from background, the first 10+ seconds the app was super jittery".
/// The tab controller keeps the Tasks tab while Home shows, and its list re-sorted the whole board on the main thread
/// for every board update the reopen caught up on. A hidden Tasks list builds nothing until it shows again.
/// Runs against the disposable real-core home, as `PhoneReopenTests` does.
@MainActor final class PhoneTasksHiddenTests: XCTestCase {
    private func home(_ command: String) async throws -> [String: Any] {
        let control = try XCTUnwrap(ProcessInfo.processInfo.environment["PHONE_TEST_HOME"])
        var request = URLRequest(url: try XCTUnwrap(URL(string: control + "/" + command)))
        request.httpMethod = "POST"
        let (data, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func until(_ what: String, _ done: () -> Bool) async throws {
        var deadline = PhoneWaitDeadline(30)
        while !done() {
            if deadline.expired() { throw PhoneError.refused("Never saw: \(what)") }
            try await Task.sleep(for: .seconds(PhoneWaitDeadline.tick))
        }
    }

    func testAHiddenTasksListBuildsNothingOnABoardUpdate() async throws {
        #if !targetEnvironment(simulator)
        throw PhoneError.refused("This check requires a disposable simulator.")
        #endif
        _ = try await home("remove")
        let invitation = try await home("link")
        let link = try JoinLink(XCTUnwrap(invitation["link"] as? String))
        let phone = try PhoneIdentity.loadOrCreate()
        let transport = PinnedTransport(pin: link.pin, phone: phone, purpose: .pairing)
        let mac = try await transport.pair(link, name: "Hidden tasks test phone")
        transport.close()
        let session = ReadOnlySession(mac: mac, phone: phone)
        session.start()
        defer { session.stop() }
        try await until("the board") { session.board?.tasks.contains { $0.id == "phone-fixture" } == true }

        // The workspace opens on Home with its Tasks tab kept behind it; a second list beside it shows, so its builds
        // witness that SwiftUI drew each board the session took.
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        defer { window.isHidden = true; window.rootViewController = nil }
        window.rootViewController = UIHostingController(rootView: VStack(spacing: 0) {
            NavigationStack {
                PhoneWorkspace(session: session, stage: Color.clear, tasks: PhoneTasks(session: session), composer: nil as EmptyView?)
            }
            PhoneTasks(session: session).environment(PhoneMessageContext()).frame(height: 200)
        })
        window.makeKeyAndVisible()
        let drawn = { PhoneTasksKept.shownSeq != nil && PhoneTasksKept.shownSeq == session.board?.seq }
        try await until("the kept Tasks list's first build") { PhoneTasksKept.hiddenBuilds > 0 && drawn() }
        let hidden = PhoneTasksKept.hiddenBuilds

        var added: [String] = []
        for _ in 0..<3 {
            let reply = try await home("board-task")
            added.append(try XCTUnwrap(reply["id"] as? String))
        }
        try await until("the shown list drawing the new tasks") {
            let ids = Set(session.board?.tasks.map(\.id) ?? [])
            return added.allSatisfy(ids.contains) && drawn()
        }
        XCTAssertEqual(PhoneTasksKept.hiddenBuilds, hidden, "The Tasks list behind Home rebuilt on a board update")
        _ = try await home("remove")
    }
}
