import CryptoKit
import Foundation
import NIOSSH
import Security

/// INF-1183: the key this phone signs in to its home with over SSH. It is made on this phone and
/// never leaves it: in the Secure Enclave where the phone has one, otherwise (a simulator) a P-256
/// key in this phone's own Keychain, this device only, never synchronized. Only its public line
/// is ever shown or sent.
public struct PhoneSSHKey: Sendable {
    static let service = "com.marcellovictorino.infinitary.phone-ssh-key"
    let key: NIOSSHPrivateKey
    init(_ key: NIOSSHPrivateKey) { self.key = key }

    /// The key's public line, as the home's `authorized_keys` holds it.
    public var line: String { String(openSSHPublicKey: key.publicKey) + " infinitary-phone" }

    public static func loadOrCreate() throws -> PhoneSSHKey {
        #if os(iOS)
        var item: CFTypeRef?
        let status = SecItemCopyMatching([kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service, kSecReturnData as String: true] as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data, let kind = data.first {
            let bytes = data.dropFirst()
            switch kind {
            case 1: return PhoneSSHKey(NIOSSHPrivateKey(secureEnclaveP256Key: try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: bytes)))
            case 0: return PhoneSSHKey(NIOSSHPrivateKey(p256Key: try P256.Signing.PrivateKey(rawRepresentation: bytes)))
            default: throw storageError()
            }
        }
        guard status == errSecItemNotFound else { throw storageError() }
        let key: NIOSSHPrivateKey
        let data: Data
        if SecureEnclave.isAvailable {
            let made = try SecureEnclave.P256.Signing.PrivateKey()
            key = NIOSSHPrivateKey(secureEnclaveP256Key: made); data = Data([1]) + made.dataRepresentation
        } else {
            let made = P256.Signing.PrivateKey()
            key = NIOSSHPrivateKey(p256Key: made); data = Data([0]) + made.rawRepresentation
        }
        let stored = SecItemAdd([kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service, kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrSynchronizable as String: false] as CFDictionary, nil)
        guard stored == errSecSuccess else { throw storageError() }
        return PhoneSSHKey(key)
        #else
        // Package tests on macOS make their own keys and never touch a Mac's keychain.
        throw PhoneError.refused("Phone keys can only be made on iOS.")
        #endif
    }

    private static func storageError() -> PhoneError {
        .refused("Could not read or keep this phone’s key. Unlock your phone and try again.")
    }
}

/// The homes' keys this phone said yes to, by address and port: a saved yes, never a secret.
public struct TrustedHomes: Codable, Equatable, Sendable {
    public var keys: [String: SSHHostKey] = [:]
    public init() {}
    public func key(for address: SSHAddress) -> SSHHostKey? { keys[address.trustName] }
    public mutating func trust(_ key: SSHHostKey, for address: SSHAddress) { keys[address.trustName] = key }
}
