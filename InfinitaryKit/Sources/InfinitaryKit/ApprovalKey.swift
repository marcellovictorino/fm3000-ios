import CryptoKit
import Foundation
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif
import Security

/// This phone's Secrets approval capability (docs/secrets.md, "Remote decisions"): a P-256 key kept for this one
/// purpose, never the pairing identity. On a device the Secure Enclave holds it and signs only after Face ID,
/// Touch ID or the passcode confirms the person, for each decision. It never leaves this device, never syncs,
/// and a device with no passcode keeps none.
public struct ApprovalKey: Sendable, Equatable {
    /// The phone's own name for this capability, kept beside the key. A new key keeps it, so the home
    /// enrolls the same device at its next generation.
    public let device: String
    /// SPKI DER, base64: what the home enrolls and checks each decision against.
    public let publicKey: String
    let signer: Signer

    enum Signer: Sendable, Equatable {
        /// The Secure Enclave's handle for the key, usable only on this device.
        case enclave(Data)
        /// A software key: the simulator, which has no Secure Enclave, and unit tests. Never a device.
        case software(Data)
    }

    /// Which keys a build keeps: a physical iPhone or iPad only Secure Enclave keys; the simulator, which has
    /// no Secure Enclave, and unit tests only software keys.
    enum Platform: Sendable, Equatable {
        case device, simulator
        static var current: Platform {
            #if os(iOS) && !targetEnvironment(simulator)
            .device
            #else
            .simulator
            #endif
        }
    }

    static let service = "com.getinfinitary.infinitary.secrets-approval"
    static let account = "approval-key"
    private struct Stored: Codable { let device: String; let key: Data; let enclave: Bool }

    /// A kept record the Keychain gave back whole but this phone cannot decode, named by the SHA-256 of its
    /// bytes so that only the record the person was told about is replaced.
    public struct Damage: Sendable, Equatable {
        let digest: Data
        init(_ record: Data) { digest = Data(SHA256.hash(data: record)) }
    }

    /// The eight digits the captain compares with the home's card before it enrolls this key: SHA-256 of the
    /// SPKI, its first four bytes as one big-endian number, modulo 10^8 (the home's `approvalCode`).
    public static func code(of publicKey: String) -> String? {
        guard let spki = Data(base64Encoded: publicKey) else { return nil }
        let digest = Array(SHA256.hash(data: spki))
        let value = (UInt32(digest[0]) << 24 | UInt32(digest[1]) << 16 | UInt32(digest[2]) << 8 | UInt32(digest[3])) % 100_000_000
        let digits = String(format: "%08u", value)
        return "\(digits.prefix(4)) \(digits.suffix(4))"
    }
    public var code: String { Self.code(of: publicKey) ?? "" }

    init(device: String, signer: Signer, platform: Platform = .current) throws {
        self.device = device
        self.signer = signer
        switch signer {
        case .software(let raw):
            // A device keeps no software key, and a caller cannot name a platform that allows more than this build.
            guard platform == .simulator, Platform.current == .simulator else { throw PhoneError.unusableApproval }
            publicKey = try P256.Signing.PrivateKey(rawRepresentation: raw).publicKey.derRepresentation.base64EncodedString()
        case .enclave(let handle):
            #if os(iOS) && !targetEnvironment(simulator)
            publicKey = try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: handle).publicKey.derRepresentation.base64EncodedString()
            #else
            _ = handle
            throw PhoneError.refused(Self.unsupported)
            #endif
        }
    }

    /// Signs one decision's exact bytes (`PhoneDecision.message`) once the person confirms it now. `reason`
    /// is what the system's prompt names. A fresh context each time: no earlier confirmation is reused.
    public func sign(_ message: String, reason: String) async throws -> String {
        let bytes = Data(message.utf8)
        switch signer {
        case .enclave(let handle):
            #if os(iOS) && !targetEnvironment(simulator)
            let context = LAContext()
            context.touchIDAuthenticationAllowableReuseDuration = 0
            guard let access = Self.accessControl() else { throw PhoneError.refused(Self.unsupported) }
            do { _ = try await context.evaluateAccessControl(access, operation: .useKeySign, localizedReason: reason) }
            catch { throw PhoneError.refused(Self.notConfirmed) }
            let key = try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: handle, authenticationContext: context)
            return try key.signature(for: bytes).derRepresentation.base64EncodedString()
            #else
            _ = handle
            throw PhoneError.refused(Self.unsupported)
            #endif
        case .software(let raw):
            #if os(iOS) && !targetEnvironment(simulator)
            // A device signs only in its Secure Enclave, never with raw key material.
            _ = raw
            throw PhoneError.unusableApproval
            #else
            #if os(iOS)
            // The simulator: the same device-owner check, answered by its enrolled Face ID.
            let context = LAContext()
            context.touchIDAuthenticationAllowableReuseDuration = 0
            do { _ = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) }
            catch {
                // INF-1109: retain the native failure in the isolated journey's existing refusal assertion.
                // Ordinary simulator use and physical devices keep the plain refusal; nothing retries or signs.
                throw Self.confirmationFailure(error,
                    isolatedPhoneTest: ProcessInfo.processInfo.environment["INFINITARY_ISOLATED_PHONE_TEST"] == "1")
            }
            #endif
            return try P256.Signing.PrivateKey(rawRepresentation: raw).signature(for: bytes).derRepresentation.base64EncodedString()
            #endif
        }
    }

    /// Only the isolated simulator journey carries native error details into its failing assertion/log.
    /// Do not dump userInfo: keys, signed bytes and the approval's reason are not diagnostic fields.
    static func confirmationFailure(_ error: Error, isolatedPhoneTest: Bool) -> PhoneError {
        guard isolatedPhoneTest else { return .refused(notConfirmed) }
        let failure = error as NSError
        return .refused("\(notConfirmed) LocalAuthentication: domain=\(failure.domain), code=\(failure.code), description=\(failure.localizedDescription)")
    }

    /// The key this phone keeps, or nil when it keeps none.
    public static func load() throws -> ApprovalKey? {
        #if os(iOS)
        try load(on: .current, from: DeviceKeychain())
        #else
        nil
        #endif
    }

    /// Nil only when the Keychain keeps no record. A device refuses a software record rather than signing with it.
    static func load(on platform: Platform, from keychain: some ApprovalKeychain) throws -> ApprovalKey? {
        guard let stored = try record(in: keychain) else { return nil }
        return try ApprovalKey(device: stored.device, signer: stored.enclave ? .enclave(stored.key) : .software(stored.key), platform: platform)
    }

    /// A new key, replacing any key this phone kept, under the same device name.
    public static func create() throws -> ApprovalKey {
        #if os(iOS)
        try create(on: .current, in: DeviceKeychain())
        #else
        throw PhoneError.refused(unsupported)
        #endif
    }

    /// A store it cannot read now is an error, never an absence: only a phone that keeps no record takes a new
    /// device name. The kept record is replaced in one write, so it stays until its replacement is saved.
    /// A damaged record is refused too; only `replace` writes over it.
    static func create(on platform: Platform, in keychain: some ApprovalKeychain) throws -> ApprovalKey {
        let kept = try record(in: keychain)
        let key = try ApprovalKey(device: kept?.device ?? UUID().uuidString, signer: try newSigner(on: platform), platform: platform)
        try save(key, on: platform, in: keychain, replacing: kept != nil)
        return key
    }

    /// Set up approvals again, the person's choice for a damaged record: a new key in place of that record.
    public static func replace(_ damage: Damage) throws -> ApprovalKey {
        #if os(iOS)
        try replace(damage, on: .current, in: DeviceKeychain())
        #else
        throw PhoneError.refused(unsupported)
        #endif
    }

    /// The record is read again and must still be the damaged bytes the person was told about. The new key is
    /// made before anything is written and one update replaces the record, so a failed read, a device that
    /// cannot keep a key, a changed record or a failed write leaves those bytes as they were. Their device name
    /// cannot be read back, so the new key takes a new one, which the home enrolls only after the person
    /// compares its code and confirms on the computer.
    static func replace(_ damage: Damage, on platform: Platform, in keychain: some ApprovalKeychain) throws -> ApprovalKey {
        let (status, data) = keychain.copy()
        guard status != errSecItemNotFound else { throw PhoneError.refused(changed) }
        guard status == errSecSuccess, let data else { throw storageError }
        guard Damage(data) == damage else { throw PhoneError.refused(changed) }
        let key = try ApprovalKey(device: UUID().uuidString, signer: try newSigner(on: platform), platform: platform)
        try save(key, on: platform, in: keychain, replacing: true)
        return key
    }

    private static func save(_ key: ApprovalKey, on platform: Platform, in keychain: some ApprovalKeychain, replacing: Bool) throws {
        let stored: Stored
        switch key.signer {
        case .enclave(let handle): stored = Stored(device: key.device, key: handle, enclave: true)
        case .software(let raw): stored = Stored(device: key.device, key: raw, enclave: false)
        }
        let record = try JSONEncoder().encode(stored)
        let accessible = platform == .device ? kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let saved = replacing ? keychain.update(record, accessible: accessible) : keychain.add(record, accessible: accessible)
        guard saved == errSecSuccess else { throw saved == errSecNotAvailable ? PhoneError.refused(unsupported) : storageError }
    }

    private static func newSigner(on platform: Platform) throws -> Signer {
        switch platform {
        case .simulator:
            return .software(P256.Signing.PrivateKey().rawRepresentation)
        case .device:
            #if os(iOS) && !targetEnvironment(simulator)
            guard SecureEnclave.isAvailable, let access = accessControl() else { throw PhoneError.refused(unsupported) }
            return .enclave(try SecureEnclave.P256.Signing.PrivateKey(accessControl: access).dataRepresentation)
            #else
            // Only a device build reaches a Secure Enclave; without one a device keeps no key, never a software one.
            throw PhoneError.refused(unsupported)
            #endif
        }
    }

    /// The kept record, or nil only when the Keychain says it keeps none. A read that fails is unreadable for
    /// now; bytes the Keychain gave back that do not decode are a damaged record, which nothing here rewrites.
    private static func record(in keychain: some ApprovalKeychain) throws -> Stored? {
        let (status, data) = keychain.copy()
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data else { throw storageError }
        guard let stored = try? JSONDecoder().decode(Stored.self, from: data) else { throw PhoneError.damagedApproval(Damage(data)) }
        return stored
    }

    /// What confirms each Allow on this device, in the words its Settings use.
    public static var confirmation: String {
        #if os(iOS)
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID or the passcode"
        case .touchID: return "Touch ID or the passcode"
        case .opticID: return "Optic ID or the passcode"
        default: return "the passcode"
        }
        #else
        return "the passcode"
        #endif
    }

    #if os(iOS) && !targetEnvironment(simulator)
    /// Each use of the key needs the person now: biometry or the passcode, on a device that has a passcode.
    private static func accessControl() -> SecAccessControl? {
        SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.privateKeyUsage, .userPresence], nil)
    }
    #endif

    static let unsupported = "This device cannot keep a Secrets approval. Set a passcode, then try again."
    static let unusable = "This phone’s saved Secrets approval cannot be used. Set up approvals again."
    static let notConfirmed = "Not confirmed. Nothing was allowed."
    static let notKept = "Could not keep this phone’s Secrets approval. Unlock your phone and try again."
    static let damaged = "This phone’s saved Secrets approval is damaged. Set up approvals again in Settings."
    static let changed = "This phone’s saved Secrets approval changed, so nothing was replaced."
    private static var storageError: PhoneError { .refused(notKept) }
}

/// Where the approval key's record is kept: one generic password, never synchronized. Tests give a stand-in
/// that answers with the Keychain's own statuses.
protocol ApprovalKeychain {
    /// The kept record, or `errSecItemNotFound` when there is none.
    func copy() -> (OSStatus, Data?)
    /// Adds the record where none is kept.
    func add(_ record: Data, accessible: CFString) -> OSStatus
    /// Replaces the kept record in one write, which leaves it as it was when it fails.
    func update(_ record: Data, accessible: CFString) -> OSStatus
}

#if os(iOS)
/// This phone's own Keychain. A Mac keeps no approval key and never reaches its Keychain.
struct DeviceKeychain: ApprovalKeychain {
    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: ApprovalKey.service,
         kSecAttrAccount as String: ApprovalKey.account, kSecAttrSynchronizable as String: false]
    }

    func copy() -> (OSStatus, Data?) {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query.merging([kSecReturnData as String: true]) { $1 } as CFDictionary, &item)
        return (status, item as? Data)
    }

    func add(_ record: Data, accessible: CFString) -> OSStatus {
        SecItemAdd(query.merging([kSecValueData as String: record, kSecAttrAccessible as String: accessible]) { $1 } as CFDictionary, nil)
    }

    func update(_ record: Data, accessible: CFString) -> OSStatus {
        SecItemUpdate(query as CFDictionary, [kSecValueData as String: record, kSecAttrAccessible as String: accessible] as CFDictionary)
    }
}
#endif

#if os(iOS) && targetEnvironment(simulator)
extension ApprovalKey {
    /// The disposable simulator's phone check alone (`INFINITARY_DAMAGED_APPROVAL`, docs/ios.md): cuts the kept
    /// record short in place, a record the phone reads but cannot decode. A device build has no such call.
    public static func damageForPhoneCheck() {
        let keychain = DeviceKeychain()
        let (status, data) = keychain.copy()
        guard status == errSecSuccess, let data else { return }
        _ = keychain.update(data.prefix(data.count / 2), accessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
    }
}
#endif
