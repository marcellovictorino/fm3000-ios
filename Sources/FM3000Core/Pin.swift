import CryptoKit
import Foundation
import Security

/// A key's pin: SHA-256 over its SubjectPublicKeyInfo, base64url without padding
/// (docs/devices.md, "Keys").
public enum Pin {
    /// The fixed DER header of an ECDSA P-256 SubjectPublicKeyInfo; the 65-byte point follows.
    static let p256SPKIPrefix = Data([
        0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01,
        0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00,
    ])

    public static func ofSPKI(_ spki: Data) -> String {
        base64url(Data(SHA256.hash(data: spki)))
    }

    /// The SPKI of an ECDSA P-256 point as `SecKeyCopyExternalRepresentation` gives it (04 || X || Y).
    public static func spki(forP256Point point: Data) -> Data {
        p256SPKIPrefix + point
    }

    /// The pin of a certificate's key; nil when the key is not ECDSA P-256 (the Mac's always is).
    public static func ofCertificate(_ certificate: SecCertificate) -> String? {
        guard let key = SecCertificateCopyKey(certificate),
              let point = SecKeyCopyExternalRepresentation(key, nil) as Data?,
              point.count == 65, point.first == 0x04 else { return nil }
        return ofSPKI(spki(forP256Point: point))
    }

    public static func ofCertificateDER(_ der: Data) -> String? {
        guard let certificate = SecCertificateCreateWithData(nil, der as CFData) else { return nil }
        return ofCertificate(certificate)
    }
}

public func base64url(_ data: Data) -> String {
    data.base64EncodedString().replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
}
