import CryptoKit
import Foundation
import Security
import X509

/// Device-only identity. Never uses a Mac's keychain, a shared access group or iCloud.
public struct PhoneIdentity: @unchecked Sendable {
    public let identity: SecIdentity
    public let certificate: SecCertificate
    static let label = "com.marcellovictorino.infinitary.phone-identity"

    public static func loadOrCreate() throws -> PhoneIdentity {
        #if os(iOS)
        let query: [String: Any] = [kSecClass as String: kSecClassIdentity,
                                   kSecAttrLabel as String: label, kSecReturnRef as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let item {
            let identity = item as! SecIdentity
            var certificate: SecCertificate?
            guard SecIdentityCopyCertificate(identity, &certificate) == errSecSuccess, let certificate
            else { throw PhoneError.refused("Could not read this phone’s identity.") }
            return PhoneIdentity(identity: identity, certificate: certificate)
        }
        guard status == errSecItemNotFound else { throw storageError(status) }
        // A crash between the two writes must not replace a key the Mac may already trust.
        var old: CFTypeRef?
        let keyStatus = SecItemCopyMatching([kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: Data(label.utf8), kSecReturnRef as String: true] as CFDictionary, &old)
        let key: P256.Signing.PrivateKey
        if keyStatus == errSecSuccess, let old {
            guard let bytes = SecKeyCopyExternalRepresentation(old as! SecKey, nil) as Data?
            else { throw storageError() }
            key = try P256.Signing.PrivateKey(x963Representation: bytes)
        } else if keyStatus == errSecItemNotFound {
            key = P256.Signing.PrivateKey()
            var error: Unmanaged<CFError>?
            guard let secKey = SecKeyCreateWithData(key.x963Representation as CFData,
                [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                 kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
                 kSecAttrKeySizeInBits as String: 256] as CFDictionary, &error) else { throw storageError() }
            let stored = SecItemAdd([kSecClass as String: kSecClassKey,
                kSecValueRef as String: secKey, kSecAttrLabel as String: label,
                kSecAttrApplicationTag as String: Data(label.utf8),
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                kSecAttrSynchronizable as String: false] as CFDictionary, nil)
            guard stored == errSecSuccess else { throw storageError(stored) }
        } else { throw storageError(keyStatus) }
        let cert = try certificate(key: key)
        let certStatus = SecItemAdd([kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: cert, kSecAttrLabel as String: label,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrSynchronizable as String: false] as CFDictionary, nil)
        // Keep the key on a failed certificate write so the next unlocked attempt can recover it.
        guard certStatus == errSecSuccess else { throw storageError(certStatus) }
        var restored: CFTypeRef?
        let restoredStatus = SecItemCopyMatching(query as CFDictionary, &restored)
        guard restoredStatus == errSecSuccess, let restored else { throw storageError(restoredStatus) }
        let identity = restored as! SecIdentity
        var storedCertificate: SecCertificate?
        guard SecIdentityCopyCertificate(identity, &storedCertificate) == errSecSuccess, let storedCertificate
        else { throw storageError() }
        return PhoneIdentity(identity: identity, certificate: storedCertificate)
        #else
        // Unit tests on macOS exercise certificate and pin logic without touching its keychain.
        throw PhoneError.refused("Phone identities can only be created on iOS.")
        #endif
    }

    static func certificate(key: P256.Signing.PrivateKey) throws -> SecCertificate {
        let name = try DistinguishedName { CommonName("Infinitary phone") }
        let certificate = try Certificate(version: .v3, serialNumber: .init(),
            publicKey: .init(key.publicKey),
            notValidBefore: Date(timeIntervalSince1970: 1577836800),
            notValidAfter: Date(timeIntervalSince1970: 4733510400),
            issuer: name, subject: name, signatureAlgorithm: .ecdsaWithSHA256,
            extensions: Certificate.Extensions {}, issuerPrivateKey: .init(key))
        return try SecCertificate.makeWithCertificate(certificate)
    }

    /// The Mac pins SHA-256 of DER SubjectPublicKeyInfo, not the certificate or raw EC point.
    public static func pin(of certificate: SecCertificate) -> String? {
        guard let key = SecCertificateCopyKey(certificate),
              let attrs = SecKeyCopyAttributes(key) as? [String: Any],
              attrs[kSecAttrKeyType as String] as? String == kSecAttrKeyTypeECSECPrimeRandom as String,
              attrs[kSecAttrKeySizeInBits as String] as? Int == 256,
              let point = SecKeyCopyExternalRepresentation(key, nil) as Data?, point.count == 65
        else { return nil }
        // RFC 5480 id-ecPublicKey + prime256v1, followed by the uncompressed EC point.
        let prefix: [UInt8] = [0x30,0x59,0x30,0x13,0x06,0x07,0x2a,0x86,0x48,0xce,0x3d,0x02,0x01,
                              0x06,0x08,0x2a,0x86,0x48,0xce,0x3d,0x03,0x01,0x07,0x03,0x42,0x00]
        return Data(SHA256.hash(data: Data(prefix) + point)).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func storageError(_ status: OSStatus? = nil) -> PhoneError {
        #if DEBUG
        FileHandle.standardError.write(Data("Infinitary identity storage status: \(status.map(String.init) ?? "no status")\n".utf8))
        #endif
        return .refused("Could not read or keep this phone’s identity. Unlock your phone and try again.")
    }
}
