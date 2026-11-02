import Foundation
import XCTest
@testable import InfinitaryKit

/// INF-1903: a phone on mobile data reaches its Mac at a Tailscale address (100.64.0.0/10), which iOS's
/// transport security does not count as local, so it ran its own trust check on the Mac's self-signed
/// certificate after the pin matched and reset every connection. `127.1` is the test home's loopback
/// written in a form iOS likewise does not count as local, so this app-hosted test, under the app's own
/// Info.plist, joins and reconnects through the same rule a Tailscale address meets.
@MainActor final class PhoneTransportSecurityTests: XCTestCase {
    private func home(_ command: String) async throws -> [String: Any] {
        let control = try XCTUnwrap(ProcessInfo.processInfo.environment["PHONE_TEST_HOME"])
        var request = URLRequest(url: try XCTUnwrap(URL(string: control + "/" + command)))
        request.httpMethod = "POST"
        let (data, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testJoinsAndReconnectsAtAnAddressIOSDoesNotCountAsLocal() async throws {
        #if !targetEnvironment(simulator)
        throw PhoneError.refused("Transport security checks require a disposable simulator.")
        #endif
        _ = try await home("remove")
        _ = try await home("routing-reset")
        let invitation = try await home("routing-link")
        let port = try XCTUnwrap(URLComponents(string: "https://" + XCTUnwrap(invitation["at"] as? String))?.port)
        let address = "127.1:\(port)"
        var only = try XCTUnwrap(URLComponents(string: XCTUnwrap(invitation["link"] as? String)))
        only.queryItems = only.queryItems?.filter { $0.name != "also" }
            .map { $0.name == "at" ? URLQueryItem(name: "at", value: address) : $0 }
        let link = try JoinLink(XCTUnwrap(only.string))
        XCTAssertEqual(link.addresses, [address])

        let phone = try PhoneIdentity.loadOrCreate()
        let transport = PinnedTransport(pin: link.pin, phone: phone, purpose: .pairing)
        defer { transport.close() }
        let mac = try await transport.pair(link, name: "Transport security test phone")

        let session = ReadOnlySession(mac: JoinedMac(addresses: [address], pin: mac.pin,
            deviceID: mac.deviceID, name: mac.name), phone: phone)
        session.start()
        defer { session.stop() }
        // The real session waits for all four initial reads before sending this harmless read.
        _ = try await session.read(.past, [.string("no-such-transport-card")])
        XCTAssertEqual(session.contact, "in-reach")
        XCTAssertEqual(session.reachedAddress, address)
    }
}
