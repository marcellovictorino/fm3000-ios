import CryptoKit
import Foundation
import Security
import Testing
@testable import InfinitaryKit

/// INF-1109's review of the phone's approval key, repaired by INF-1250: a device keeps and signs only Secure
/// Enclave keys, and replacing a key never loses the one the phone keeps. The stand-in answers as the phone's
/// Keychain does, with its own statuses, so no Mac Keychain is touched.
struct ApprovalStorageTests {
    /// One record or none: an add where one is kept is a duplicate, an update where none is kept finds nothing,
    /// and a failing status leaves the record as it was. It counts every write asked of it.
    final class Keychain: ApprovalKeychain {
        var record: Data?
        var accessible: String?
        var reading = errSecSuccess
        var writing = errSecSuccess
        private(set) var writes = 0

        func copy() -> (OSStatus, Data?) {
            guard reading == errSecSuccess else { return (reading, nil) }
            return record.map { (errSecSuccess, $0) } ?? (errSecItemNotFound, nil)
        }

        func add(_ record: Data, accessible: CFString) -> OSStatus {
            writes += 1
            guard writing == errSecSuccess else { return writing }
            guard self.record == nil else { return errSecDuplicateItem }
            self.record = record; self.accessible = accessible as String
            return errSecSuccess
        }

        func update(_ record: Data, accessible: CFString) -> OSStatus {
            writes += 1
            guard writing == errSecSuccess else { return writing }
            guard self.record != nil else { return errSecItemNotFound }
            self.record = record; self.accessible = accessible as String
            return errSecSuccess
        }
    }

    @Test func aDeviceRefusesASoftwareKey() throws {
        let keychain = Keychain()
        let kept = try ApprovalKey.create(on: .simulator, in: keychain)
        #expect(try ApprovalKey.load(on: .simulator, from: keychain) == kept)
        let loaded = #expect(throws: PhoneError.self) { try ApprovalKey.load(on: .device, from: keychain) }
        #expect(loaded?.errorDescription == ApprovalKey.unusable)
        let made = #expect(throws: PhoneError.self) { try ApprovalKey(device: kept.device, signer: kept.signer, platform: .device) }
        #expect(made?.errorDescription == ApprovalKey.unusable)
    }

    @Test func aDeviceWithoutASecureEnclaveKeepsNoSoftwareKey() throws {
        // This Mac build reaches no Secure Enclave, as a device without one.
        let keychain = Keychain()
        let fresh = #expect(throws: PhoneError.self) { try ApprovalKey.create(on: .device, in: keychain) }
        #expect(fresh?.errorDescription == ApprovalKey.unsupported)
        #expect(keychain.record == nil)
        let kept = try ApprovalKey.create(on: .simulator, in: keychain)
        let record = keychain.record
        #expect(throws: PhoneError.self) { try ApprovalKey.create(on: .device, in: keychain) }
        #expect(keychain.record == record)
        #expect(try ApprovalKey.load(on: .simulator, from: keychain) == kept)
    }

    @Test func replacingAKeyKeepsItsDeviceAndTheEarlierKeyUntilSaved() throws {
        let keychain = Keychain()
        let first = try ApprovalKey.create(on: .simulator, in: keychain)
        #expect(keychain.accessible == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
        let second = try ApprovalKey.create(on: .simulator, in: keychain)
        #expect(second.device == first.device)
        #expect(second.publicKey != first.publicKey)
        #expect(try ApprovalKey.load(on: .simulator, from: keychain) == second)

        keychain.writing = errSecInteractionNotAllowed
        let failed = #expect(throws: PhoneError.self) { try ApprovalKey.create(on: .simulator, in: keychain) }
        #expect(failed?.errorDescription == ApprovalKey.notKept)
        #expect(try ApprovalKey.load(on: .simulator, from: keychain) == second)
    }

    @Test func aStoreItCannotReadIsNotAnAbsence() throws {
        let keychain = Keychain()
        let kept = try ApprovalKey.create(on: .simulator, in: keychain)
        let record = try #require(keychain.record)
        let writes = keychain.writes

        keychain.reading = errSecInteractionNotAllowed
        let loaded = #expect(throws: PhoneError.self) { try ApprovalKey.load(on: .simulator, from: keychain) }
        #expect(loaded?.errorDescription == ApprovalKey.notKept)
        let replaced = #expect(throws: PhoneError.self) { try ApprovalKey.create(on: .simulator, in: keychain) }
        #expect(replaced?.errorDescription == ApprovalKey.notKept)
        #expect(keychain.writes == writes, "Nothing is written while the kept record cannot be read")
        keychain.reading = errSecSuccess
        #expect(keychain.record == record)
        #expect(try ApprovalKey.load(on: .simulator, from: keychain) == kept)

        // A record cut short is damaged rather than absent: it is kept as it is, not replaced under a new device name.
        keychain.record = record.prefix(record.count / 2)
        #expect(throws: PhoneError.self) { try ApprovalKey.load(on: .simulator, from: keychain) }
        #expect(throws: PhoneError.self) { try ApprovalKey.create(on: .simulator, in: keychain) }
        #expect(keychain.writes == writes)
        #expect(keychain.record == record.prefix(record.count / 2))
    }

    /// INF-1109's decision on a damaged record: bytes the Keychain gives back that do not decode are their own
    /// fact, never a read that failed, and neither ordinary path writes over them.
    /// The damaged record an error names, if it names one.
    static func damage(_ error: PhoneError?) -> ApprovalKey.Damage? {
        if case .damagedApproval(let found)? = error { return found }
        return nil
    }

    @Test func aDamagedRecordIsNotAFailedRead() throws {
        let keychain = Keychain()
        _ = try ApprovalKey.create(on: .simulator, in: keychain)
        let damaged = try #require(keychain.record).prefix(20)
        keychain.record = damaged
        let writes = keychain.writes

        let loaded = #expect(throws: PhoneError.self) { try ApprovalKey.load(on: .simulator, from: keychain) }
        #expect(Self.damage(loaded) == ApprovalKey.Damage(damaged))
        #expect(loaded?.errorDescription == ApprovalKey.damaged)
        let created = #expect(throws: PhoneError.self) { try ApprovalKey.create(on: .simulator, in: keychain) }
        #expect(Self.damage(created) == ApprovalKey.Damage(damaged))
        #expect(keychain.writes == writes)
        #expect(keychain.record == damaged)

        // The same record while the phone is locked is unreadable for now, not damaged.
        keychain.reading = errSecInteractionNotAllowed
        let locked = #expect(throws: PhoneError.self) { try ApprovalKey.load(on: .simulator, from: keychain) }
        #expect(Self.damage(locked) == nil)
        #expect(locked?.errorDescription == ApprovalKey.notKept)
        let lockedReplace = #expect(throws: PhoneError.self) { try ApprovalKey.replace(ApprovalKey.Damage(damaged), on: .simulator, in: keychain) }
        #expect(lockedReplace?.errorDescription == ApprovalKey.notKept)
        #expect(keychain.writes == writes)
        #expect(keychain.record == damaged)
    }

    @Test func replacingADamagedRecordWritesANewKeyUnderANewDeviceOnce() async throws {
        let keychain = Keychain()
        let kept = try ApprovalKey.create(on: .simulator, in: keychain)
        let damaged = try #require(keychain.record).prefix(20)
        keychain.record = damaged
        let writes = keychain.writes

        let fresh = try ApprovalKey.replace(ApprovalKey.Damage(damaged), on: .simulator, in: keychain)
        #expect(fresh.device != kept.device, "A damaged record's device name is not read back")
        #expect(fresh.publicKey != kept.publicKey)
        #expect(keychain.writes == writes + 1, "One update replaces the record; nothing deletes it first")
        #expect(keychain.accessible == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
        #expect(try ApprovalKey.load(on: .simulator, from: keychain) == fresh)
        let signature = try await fresh.sign("decision", reason: "Check")
        let signed = try P256.Signing.ECDSASignature(derRepresentation: #require(Data(base64Encoded: signature)))
        let publicKey = try P256.Signing.PublicKey(derRepresentation: #require(Data(base64Encoded: fresh.publicKey)))
        #expect(publicKey.isValidSignature(signed, for: Data("decision".utf8)))
    }

    @Test func aRefusedReplacementLeavesTheDamagedRecord() throws {
        let keychain = Keychain()
        let kept = try ApprovalKey.create(on: .simulator, in: keychain)
        let valid = try #require(keychain.record)
        let damaged = valid.prefix(20)
        let damage = ApprovalKey.Damage(damaged)
        keychain.record = damaged
        let writes = keychain.writes

        // This Mac reaches no Secure Enclave, as a device without one: no key is made, and none in software.
        let unsupported = #expect(throws: PhoneError.self) { try ApprovalKey.replace(damage, on: .device, in: keychain) }
        #expect(unsupported?.errorDescription == ApprovalKey.unsupported)
        #expect(keychain.writes == writes)
        #expect(keychain.record == damaged)

        // A record that changed since the person was told is not the one they chose to replace.
        for changed in [valid.prefix(10), valid, nil] {
            keychain.record = changed
            let refused = #expect(throws: PhoneError.self) { try ApprovalKey.replace(damage, on: .simulator, in: keychain) }
            #expect(refused?.errorDescription == ApprovalKey.changed)
            #expect(keychain.writes == writes)
            #expect(keychain.record == changed)
        }
        keychain.record = valid
        #expect(try ApprovalKey.load(on: .simulator, from: keychain) == kept)

        // A write that fails leaves the damaged bytes.
        keychain.record = damaged
        keychain.writing = errSecInteractionNotAllowed
        let failed = #expect(throws: PhoneError.self) { try ApprovalKey.replace(damage, on: .simulator, in: keychain) }
        #expect(failed?.errorDescription == ApprovalKey.notKept)
        #expect(keychain.writes == writes + 1)
        #expect(keychain.record == damaged)
    }
}
