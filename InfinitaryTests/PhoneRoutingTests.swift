import Foundation
import XCTest
@testable import InfinitaryKit

/// INF-1156 accepted option A: disposable real TLS/core, no personal route or account.
/// The simulator's own identity and home are owned by phone.yml's rest part.
@MainActor final class PhoneRoutingTests: XCTestCase {
    private func home(_ command: String, method: String = "POST") async throws -> [String: Any] {
        let control = try XCTUnwrap(ProcessInfo.processInfo.environment["PHONE_TEST_HOME"])
        var request = URLRequest(url: try XCTUnwrap(URL(string: control + "/" + command)))
        request.httpMethod = method
        let (data, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func ready(_ session: ReadOnlySession) async throws {
        // The real session waits for all four initial reads before sending this harmless read.
        _ = try await session.read(.past, [.string("no-such-routing-card")])
        XCTAssertEqual(session.contact, "in-reach")
    }

    func testPinnedPreflightFallbackRefreshPersistenceAndOlderHome() async throws {
        #if !targetEnvironment(simulator)
        throw PhoneError.refused("Routing checks require a disposable simulator.")
        #endif
        _ = try await home("remove")
        _ = try await home("routing-reset")
        let phone = try PhoneIdentity.loadOrCreate()
        let phonePin = PhoneIdentity.pin(of: phone.certificate)
        let invitation = try await home("routing-link")
        let link = try JoinLink(XCTUnwrap(invitation["link"] as? String))
        let transport = PinnedTransport(pin: link.pin, phone: phone, purpose: .pairing)
        defer { transport.close() }
        let mac = try await transport.pair(link, name: "Routing test phone")
        let state = try await home("routing-state", method: "GET")
        XCTAssertEqual(state["pairCalls"] as? Int, 1, "A stalled preflight spends no invitation")
        XCTAssertEqual((state["devices"] as? [Any])?.count, 1)
        XCTAssertEqual(mac.addresses.count, link.addresses.count, "Pairing retains every fallback")

        // A local-only saved phone learns another usable route through an authenticated welcome.
        let at = try XCTUnwrap(invitation["at"] as? String)
        let localOnly = JoinedMac(addresses: [at], pin: mac.pin, deviceID: mac.deviceID, name: mac.name)
        let offered = try await home("routing-refresh")
        let advertised = try XCTUnwrap(offered["addresses"] as? [String])
        let privateAlternative = try XCTUnwrap(advertised.first)
        let alternative = try XCTUnwrap(advertised.last)
        let session = ReadOnlySession(mac: localOnly, phone: phone)
        let saved = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: saved) }
        session.onMacChanged = { updated in
            do { try JSONEncoder().encode(updated).write(to: saved, options: .atomic) }
            catch { XCTFail("Could not persist the refreshed record: \(error)") }
        }
        session.start()
        defer { session.stop() }
        try await ready(session)
        XCTAssertTrue(session.mac.addresses.contains(alternative))
        XCTAssertEqual(session.mac.addresses.first, privateAlternative)
        XCTAssertTrue(session.mac.addresses.contains(at))
        XCTAssertEqual(session.reachedAddress, at, "The working route is not the refreshed preference")
        let refreshed = try JSONDecoder().decode(JoinedMac.self, from: Data(contentsOf: saved))
        XCTAssertEqual(refreshed.pin, mac.pin)
        XCTAssertEqual(refreshed.deviceID, mac.deviceID)
        let before = try await home("routing-state", method: "GET")
        try await ready(session)
        let after = try await home("routing-state", method: "GET")
        XCTAssertEqual((before["readings"] as? [String: Int])?["connections"],
                       (after["readings"] as? [String: Int])?["connections"], "Refresh does not interrupt the socket")
        session.stop()

        // Omission by an old home leaves persisted alternatives intact across restoration.
        _ = try await home("routing-legacy")
        // Never dial the illustrative private address on the runner's actual network.
        // The package test owns private-first restoration; this live return owns old-home omission.
        var localRestoration = refreshed
        localRestoration.addresses = refreshed.addresses.filter { !PhoneAddresses.isPrivate($0) }
        let restored = ReadOnlySession(mac: localRestoration, phone: phone)
        restored.start(); defer { restored.stop() }
        try await ready(restored)
        XCTAssertEqual(restored.mac.addresses, localRestoration.addresses)
        // INF-2157: a reopen dials the saved addresses together, so either restored route may be the one that answers.
        XCTAssertTrue(localRestoration.addresses.contains(try XCTUnwrap(restored.reachedAddress)), "A restored saved route answered")
        XCTAssertEqual(PhoneIdentity.pin(of: try PhoneIdentity.loadOrCreate().certificate), phonePin)
        restored.stop()

        // The fixture consumes the invitation, then drops the actual HTTP response.
        _ = try await home("remove")
        _ = try await home("routing-reset")
        let lost = try await home("routing-lost-link")
        let lostLink = try JoinLink(XCTUnwrap(lost["link"] as? String))
        let uncertain = PinnedTransport(pin: lostLink.pin, phone: phone, purpose: .pairing)
        defer { uncertain.close() }
        do { _ = try await uncertain.pair(lostLink, name: "Routing test phone"); XCTFail("A lost reply is not confirmed") }
        catch PhoneError.unavailable { }
        let once = try await home("routing-state", method: "GET")
        XCTAssertEqual(once["pairCalls"] as? Int, 1, "Never repeat an uncertain POST on another advertised route")
        XCTAssertEqual((once["devices"] as? [Any])?.count, 1, "The lost reply really followed a saved join")
        _ = try await home("remove")
        _ = try await home("routing-reset")
    }
}
