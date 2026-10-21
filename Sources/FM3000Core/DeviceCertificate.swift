import Foundation

/// The device's own self-signed certificate. It is only the envelope TLS carries the
/// key in: the Mac reads no name or date from it, it hashes the key (docs/devices.md, "Keys").
public enum DeviceCertificate {
    /// - Parameters:
    ///   - point: the ECDSA P-256 public key, 04 || X || Y.
    ///   - sign: signs bytes with the private key, ECDSA over SHA-256, DER-encoded.
    public static func make(
        point: Data,
        commonName: String = "firstmate-3000-ios",
        now: Date = Date(),
        random: (Int) -> [UInt8] = { count in (0..<count).map { _ in UInt8.random(in: 0...255) } },
        sign: (Data) throws -> Data
    ) throws -> Data {
        let name = DER.sequence(DER.set(DER.sequence(DER.commonName, DER.utf8String(commonName))))
        let validity = DER.sequence(
            DER.time(now.addingTimeInterval(-86_400)),
            DER.time(now.addingTimeInterval(10 * 365 * 86_400))
        )
        var serial = random(16)
        serial[0] &= 0x7f
        let tbs = DER.sequence(
            DER.element(0xa0, DER.integer([2])),  // version 3
            DER.integer(serial),
            DER.ecdsaWithSHA256,
            name,
            validity,
            name,
            Pin.spki(forP256Point: point)
        )
        let signature = try sign(tbs)
        return DER.sequence(tbs, DER.ecdsaWithSHA256, DER.bitString(signature))
    }
}
