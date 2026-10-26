import Foundation
import Security

/// The phone's own key and certificate, shown to the Mac in every TLS 1.3 handshake.
public struct DeviceIdentity {
    public let identity: SecIdentity
    public let certificateDER: Data
    /// The pin of the device's key. The Mac keeps only this.
    public let pin: String
}

public struct KeychainError: Error, LocalizedError {
    public let status: OSStatus
    public let doing: String
    public var errorDescription: String? {
        let words = SecCopyErrorMessageString(status, nil) as String? ?? "status \(status)"
        return "Keychain: \(doing) failed (\(words))."
    }
}

public protocol IdentityStore {
    func loadOrCreate() throws -> DeviceIdentity
    func delete()
}

/// Makes the device's ECDSA P-256 key in the app's own keychain on first use and keeps it:
/// the private key never leaves the keychain, it signs through `SecKeyCreateSignature`.
/// On macOS a scratch keychain file can be named, so tests never touch a person's keychains.
public final class KeychainIdentityStore: IdentityStore {
    /// The certificate's label, which macOS takes from its subject whatever label is asked for.
    static let certificateLabel = "firstmate-3000-ios"
    private let tag: String
    #if os(macOS)
    private let scratch: SecKeychain?
    #endif

    public init(tag: String = "dev.fm3000.device") {
        self.tag = tag
        #if os(macOS)
        self.scratch = nil
        #endif
    }

    #if os(macOS)
    /// Uses only the given keychain file, created if it does not exist.
    public init(tag: String = "dev.fm3000.device", scratchKeychainPath path: String) throws {
        self.tag = tag
        var keychain: SecKeychain?
        var status = SecKeychainOpen(path, &keychain)
        if status != errSecSuccess || FileManager.default.fileExists(atPath: path) == false {
            status = SecKeychainCreate(path, 8, "scratchpw", false, nil, &keychain)
            guard status == errSecSuccess else { throw KeychainError(status: status, doing: "creating the scratch keychain") }
        }
        status = SecKeychainUnlock(keychain, 8, "scratchpw", true)
        guard status == errSecSuccess else { throw KeychainError(status: status, doing: "unlocking the scratch keychain") }
        self.scratch = keychain
    }
    #endif

    private var tagData: Data { Data(tag.utf8) }

    /// Adds the keychain scope to a query, for the scratch keychain on macOS.
    private func scoped(_ query: [String: Any], adding: Bool) -> [String: Any] {
        var query = query
        #if os(macOS)
        if let scratch {
            if adding { query[kSecUseKeychain as String] = scratch } else { query[kSecMatchSearchList as String] = [scratch] }
        }
        #endif
        return query
    }

    private func copy(_ query: [String: Any]) -> CFTypeRef? {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(scoped(query, adding: false) as CFDictionary, &result)
        return status == errSecSuccess ? result : nil
    }

    private func existing() -> DeviceIdentity? {
        guard copy([
            kSecClass as String: kSecClassKey, kSecAttrApplicationTag as String: tagData,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom, kSecReturnRef as String: true,
        ]) != nil,
            let certificateRef = copy([
                kSecClass as String: kSecClassCertificate, kSecAttrLabel as String: Self.certificateLabel, kSecReturnRef as String: true,
            ]) else { return nil }
        let certificate = certificateRef as! SecCertificate
        return identity(for: certificate)
    }

    private func identity(for certificate: SecCertificate) -> DeviceIdentity? {
        var found: SecIdentity?
        #if os(macOS)
        if SecIdentityCreateWithCertificate(scratch, certificate, &found) != errSecSuccess { found = nil }
        #else
        if let ref = copy([kSecClass as String: kSecClassIdentity, kSecAttrLabel as String: Self.certificateLabel, kSecReturnRef as String: true]) {
            found = (ref as! SecIdentity)
        }
        #endif
        guard let identity = found, let pin = Pin.ofCertificate(certificate) else { return nil }
        return DeviceIdentity(identity: identity, certificateDER: SecCertificateCopyData(certificate) as Data, pin: pin)
    }

    public func loadOrCreate() throws -> DeviceIdentity {
        if let found = existing() { return found }
        delete()
        var privateAttributes: [String: Any] = [
            kSecAttrIsPermanent as String: true,
            kSecAttrApplicationTag as String: tagData,
        ]
        #if os(iOS)
        // Reconnecting in the background after a restart needs the key once the phone was unlocked once.
        privateAttributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        #endif
        var attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrLabel as String: tag,
            kSecPrivateKeyAttrs as String: privateAttributes,
        ]
        #if os(macOS)
        if let scratch { attributes[kSecUseKeychain as String] = scratch }
        #endif
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw KeychainError(status: Int32((error?.takeRetainedValue() as Error? as NSError?)?.code ?? -1), doing: "making the device key")
        }
        guard let publicKey = SecKeyCopyPublicKey(privateKey),
              let point = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            throw KeychainError(status: errSecParam, doing: "reading the device key")
        }
        let der = try DeviceCertificate.make(point: point, commonName: Self.certificateLabel) { message in
            var signError: Unmanaged<CFError>?
            guard let signature = SecKeyCreateSignature(privateKey, .ecdsaSignatureMessageX962SHA256, message as CFData, &signError) as Data? else {
                throw KeychainError(status: errSecParam, doing: "signing the certificate")
            }
            return signature
        }
        guard let certificate = SecCertificateCreateWithData(nil, der as CFData) else {
            throw KeychainError(status: errSecParam, doing: "reading the certificate")
        }
        let status = SecItemAdd(scoped([
            kSecClass as String: kSecClassCertificate, kSecValueRef as String: certificate, kSecAttrLabel as String: Self.certificateLabel,
        ], adding: true) as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status, doing: "keeping the certificate") }
        guard let made = identity(for: certificate) else { throw KeychainError(status: errSecItemNotFound, doing: "joining key and certificate") }
        return made
    }

    public func delete() {
        for query: [String: Any] in [
            [kSecClass as String: kSecClassKey, kSecAttrApplicationTag as String: tagData],
            [kSecClass as String: kSecClassCertificate, kSecAttrLabel as String: Self.certificateLabel],
        ] {
            SecItemDelete(scoped(query, adding: false) as CFDictionary)
        }
    }
}
