import Foundation
import XCTest
@testable import Infinitary
@testable import InfinitaryKit

/// INF-3307's audit, row 13: cancelling a first join by address could save that computer's key as trusted under the
/// next address typed, and that computer's own join was then refused until the app's data was erased. The cancelled
/// sign-in still answered after the next address began, and its answer landed on the next address's sheet.
/// The home is a stand-in for `SSHJoin.link` whose answers the test releases in the order the race needs.
@MainActor final class PhoneAddressJoinTests: XCTestCase {
    /// Two homes' real OpenSSH host keys, as `ssh-keygen -t ecdsa` writes them.
    private let studioKey = SSHHostKey(line: "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCrdZu"
        + "wCkC9Lu74tv+Q5FP2tLIU5AUaUysSElnP5NYbBfGvUbWvIy7eOrKuKzF43OkkS1JZIrp0PeW9+LT7Wd5g=")
    private let officeKey = SSHHostKey(line: "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOxi+J"
        + "GF4p4LOWHW7WWvLU1P7Azx5TBG51oMi761UvyPuEUCgjJn3RwKas9LDX4nxUgwK1mtw8cSFYFUElMRz7U=")
    /// Each sign-in the phone started and has not had its answer, by the address it signed in to.
    private var signingIn: [String: CheckedContinuation<JoinLink, Error>] = [:]

    private var trustedURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TrustedHomes.json")
    }

    override func setUpWithError() throws {
        #if !targetEnvironment(simulator)
        throw PhoneError.refused("Address join tests require a disposable simulator.")
        #endif
        try? FileManager.default.removeItem(at: trustedURL)
    }

    override func tearDownWithError() throws {
        for (_, answer) in signingIn { answer.resume(throwing: CancellationError()) }
        signingIn = [:]
        try? FileManager.default.removeItem(at: trustedURL)
    }

    private func home(_ address: SSHAddress, _ trusted: SSHHostKey?, _ key: PhoneSSHKey) async throws -> JoinLink {
        try await withCheckedThrowingContinuation {
            signingIn.updateValue($0, forKey: address.trustName)?.resume(throwing: CancellationError())
        }
    }

    /// The main actor runs its work in order, so every answer released before this has landed once it returns.
    private func settle() async { await Task { @MainActor in }.value }

    private func answer(_ trustName: String, _ error: Error) throws {
        try XCTUnwrap(signingIn.removeValue(forKey: trustName), "The phone never signed in to \(trustName)").resume(throwing: error)
    }

    private func trusted() throws -> TrustedHomes {
        guard FileManager.default.fileExists(atPath: trustedURL.path) else { return TrustedHomes() }
        return try JSONDecoder().decode(TrustedHomes.self, from: Data(contentsOf: trustedURL))
    }

    func testACancelledJoinsLateAnswerNeverTrustsItsKeyForTheNextAddress() async throws {
        let model = PhoneModel(readMac: { nil }, protectedDataAvailable: { true }, askLink: { try await self.home($0, $1, $2) })
        let office = try SSHAddress("kun@office")

        model.joinByAddress("kun@studio", port: "")
        await settle()
        XCTAssertNotNil(signingIn["studio:22"], "The first join signs in to the studio")
        model.cancelAddressJoin()
        model.joinByAddress("kun@office", port: "")
        await settle()
        XCTAssertNotNil(signingIn["office:22"], "The next join signs in to the office")

        // The cancelled sign-in answers late: the studio is a first sight, so it reports its key.
        try answer("studio:22", SSHJoinError.unknownHost(studioKey))
        await settle()
        XCTAssertEqual(model.addressJoin?.address, office)
        XCTAssertEqual(model.addressJoin?.step, .working, "The office's sheet still waits on the office's own answer")
        // The person says yes to whatever fingerprint the sheet shows now.
        model.trustHome()
        XCTAssertNil(try trusted().key(for: office), "No yes was asked of the office yet, so nothing is kept for it")

        // The office's own answer still lands, and its yes keeps the office's own key.
        try answer("office:22", SSHJoinError.unknownHost(officeKey))
        await settle()
        XCTAssertEqual(model.addressJoin?.step, .trust(officeKey))
        model.trustHome()
        await settle()
        XCTAssertEqual(try trusted().key(for: office), officeKey)
        XCTAssertNil(try trusted().key(for: try SSHAddress("kun@studio")), "The cancelled studio was never trusted")
        model.cancelAddressJoin()
    }
}
