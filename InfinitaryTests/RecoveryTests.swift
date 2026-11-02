import Foundation
import Security
import XCTest
@testable import Infinitary
@testable import InfinitaryKit

/// INF-136 #5/#8. App-hosted tests use only the fresh simulator owned by test-phone.ts.
@MainActor final class RecoveryTests: XCTestCase {
    override func setUpWithError() throws {
        #if !targetEnvironment(simulator)
        throw PhoneError.refused("Identity recovery tests require a disposable simulator.")
        #endif
    }

    // INF-136 re-review #1: only evidence of protection should suggest unlocking.
    func testSavedMacErrorsDistinguishProtectionFromOtherReadFailures() throws {
        for (code, available, unlock) in [
            (CocoaError.Code.fileReadNoPermission, true, true),
            (.fileReadUnknown, false, true),
            (.fileReadUnknown, true, false)
        ] {
            let model = PhoneModel(readMac: { throw CocoaError(code) }, protectedDataAvailable: { available })
            XCTAssertFalse(model.restore())
            XCTAssertNotNil(model.problem)
            XCTAssertEqual(model.problem?.contains("Unlock"), unlock)
        }
    }

    func testInvalidSavedMacDoesNotBecomeAConnection() async throws {
        let control = try XCTUnwrap(ProcessInfo.processInfo.environment["PHONE_TEST_HOME"])
        var request = URLRequest(url: try XCTUnwrap(URL(string: control + "/link")))
        request.httpMethod = "POST"
        let (data, _) = try await URLSession.shared.data(for: request)
        let invitation = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let link = try JoinLink(XCTUnwrap(invitation["link"] as? String))
        let badPin = JoinedMac(addresses: link.addresses, pin: "", deviceID: "phone-fixture", name: "Test Mac mini")
        let badAddress = JoinedMac(addresses: ["not an address"], pin: link.pin, deviceID: "phone-fixture", name: "Test Mac mini")
        for record in [badPin, badAddress] {
            let model = PhoneModel(readMac: { record }, protectedDataAvailable: { true })
            XCTAssertTrue(model.restore())
            XCTAssertNil(model.connection)
            XCTAssertFalse(model.problem?.contains("Unlock") == true)
            model.propose(try XCTUnwrap(invitation["link"] as? String))
            XCTAssertNotNil(model.proposal)
        }
    }

    func testMissingCertificateReusesTheStoredKey() throws {
        let original = try PhoneIdentity.loadOrCreate()
        let pin = try XCTUnwrap(PhoneIdentity.pin(of: original.certificate))
        XCTAssertEqual(SecItemDelete([kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: PhoneIdentity.label] as CFDictionary), errSecSuccess)
        let recovered = try PhoneIdentity.loadOrCreate()
        XCTAssertEqual(PhoneIdentity.pin(of: recovered.certificate), pin)
        XCTAssertEqual(PhoneIdentity.pin(of: try PhoneIdentity.loadOrCreate().certificate), pin)
    }

    func testLockedIdentityExplainsJoinAndCanBeReadAfterUnlock() async throws {
        var unlocked = false
        var reads = 0
        let model = PhoneModel(loadIdentity: {
            reads += 1
            guard unlocked else { throw PhoneError.refused("Unlock your phone to read its identity.") }
            return try PhoneIdentity.loadOrCreate()
        }, readMac: { nil })
        XCTAssertFalse(model.restore())
        XCTAssertNotNil(model.problem)
        // The real fixture supplies a real invitation, but no pairing starts while its key is unreadable.
        let control = try XCTUnwrap(ProcessInfo.processInfo.environment["PHONE_TEST_HOME"])
        var request = URLRequest(url: try XCTUnwrap(URL(string: control + "/link")))
        request.httpMethod = "POST"
        let (data, _) = try await URLSession.shared.data(for: request)
        let invitation = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        model.propose(try XCTUnwrap(invitation["link"] as? String))
        model.join()
        XCTAssertFalse(model.busy)
        XCTAssertNotNil(model.problem)
        XCTAssertNil(model.proposal)
        unlocked = true
        XCTAssertTrue(model.restore())
        XCTAssertNil(model.problem)
        XCTAssertEqual(reads, 3)
    }

    func testProtectedMacRecordIsRetriedWithoutReplacingTheIdentity() throws {
        var readable = false
        var identityReads = 0
        var recordReads = 0
        let model = PhoneModel(loadIdentity: {
            identityReads += 1
            return try PhoneIdentity.loadOrCreate()
        }, readMac: {
            recordReads += 1
            guard readable else { throw CocoaError(.fileReadNoPermission) }
            return nil
        })
        XCTAssertFalse(model.restore())
        XCTAssertNotNil(model.problem)
        readable = true
        XCTAssertTrue(model.restore())
        XCTAssertNil(model.problem)
        XCTAssertEqual(recordReads, 2)
        XCTAssertEqual(identityReads, 1)
    }
}
