import Foundation
import Security
import XCTest
@testable import InfinitaryKit

/// INF-1109's review of the phone's approval key, repaired by INF-1250, on the disposable simulator's own
/// Keychain: a new key replaces the kept record in place, under the same device name, and the phone reads it back.
final class ApprovalKeyTests: XCTestCase {
    /// Where the cleanup believes it runs. It can only narrow what the build allows, never widen it.
    private var platform = ApprovalKey.Platform.current

    override func setUpWithError() throws {
        #if targetEnvironment(simulator)
        forget()
        #else
        throw PhoneError.refused("Approval key tests require a disposable simulator.")
        #endif
    }

    override func tearDownWithError() throws { forget() }

    /// XCTest still calls teardown after setup throws, so the cleanup checks the build itself: outside the
    /// disposable simulator the approval record is the person's own, and nothing is deleted.
    private func forget() {
        #if targetEnvironment(simulator)
        guard platform == .simulator else { return }
        let status = SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: ApprovalKey.service,
            kSecAttrAccount as String: ApprovalKey.account, kSecAttrSynchronizable as String: false] as CFDictionary)
        XCTAssertTrue(status == errSecSuccess || status == errSecItemNotFound, "\(status)")
        #endif
    }

    func testReplacingTheKeyKeepsItsDeviceAndReadsTheNewKey() throws {
        XCTAssertNil(try ApprovalKey.load())
        let first = try ApprovalKey.create()
        XCTAssertEqual(try ApprovalKey.load(), first)
        let second = try ApprovalKey.create()
        XCTAssertEqual(second.device, first.device)
        XCTAssertNotEqual(second.publicKey, first.publicKey)
        XCTAssertEqual(try ApprovalKey.load(), second)
    }

    /// The captain's ask on INF-1250's test: teardown on a physical iPhone or iPad leaves its approval record alone.
    func testTeardownDeletesNothingOutsideTheSimulator() throws {
        let kept = try ApprovalKey.create()
        platform = .device
        defer { platform = .current }
        try tearDownWithError()
        XCTAssertEqual(try ApprovalKey.load(), kept)
    }

    // INF-1109's unsigned device-test build must compile without the simulator-only damage helper.
    // Keep this test and its record reader under the helper's own compilation boundary.
    #if os(iOS) && targetEnvironment(simulator)
    /// INF-1109's decision on a damaged record, on the disposable simulator's own Keychain: the phone check's
    /// damaged record is refused by load and create alike and stays as it is, and only its own replacement
    /// writes a new key, under a new device name. A device that cannot keep a key leaves it too.
    func testADamagedRecordIsReplacedOnlyByItsOwnRepair() throws {
        let kept = try ApprovalKey.create()
        let original = try XCTUnwrap(record())
        ApprovalKey.damageForPhoneCheck()
        let damaged = try XCTUnwrap(record())
        // The simulator branch must still exercise the actual destructive fixture, not merely compile it.
        XCTAssertFalse(damaged.isEmpty)
        XCTAssertLessThan(damaged.count, original.count)
        XCTAssertEqual(damaged, original.prefix(damaged.count))
        var damage: ApprovalKey.Damage?
        XCTAssertThrowsError(try ApprovalKey.load()) { error in
            if case PhoneError.damagedApproval(let found) = error { damage = found }
        }
        XCTAssertEqual(damage, ApprovalKey.Damage(damaged))
        XCTAssertThrowsError(try ApprovalKey.create())
        XCTAssertEqual(record(), damaged)
        let found = try XCTUnwrap(damage)
        XCTAssertThrowsError(try ApprovalKey.replace(found, on: .device, in: DeviceKeychain()))
        XCTAssertEqual(record(), damaged)

        let fresh = try ApprovalKey.replace(found)
        XCTAssertNotEqual(fresh.device, kept.device)
        XCTAssertNotEqual(fresh.publicKey, kept.publicKey)
        XCTAssertEqual(try ApprovalKey.load(), fresh)
        XCTAssertThrowsError(try ApprovalKey.replace(found), "The damaged record is gone, so the same choice replaces nothing")
        XCTAssertEqual(try ApprovalKey.load(), fresh)
    }

    /// The approval record's bytes as the simulator's Keychain keeps them.
    private func record() -> Data? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: ApprovalKey.service,
            kSecAttrAccount as String: ApprovalKey.account, kSecAttrSynchronizable as String: false,
            kSecReturnData as String: true] as CFDictionary, &item)
        return status == errSecSuccess ? item as? Data : nil
    }
    #endif
}
