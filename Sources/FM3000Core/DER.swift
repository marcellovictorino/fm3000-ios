import Foundation

/// The little DER this app needs, to make its own self-signed certificate.
enum DER {
    static func length(_ count: Int) -> Data {
        if count < 0x80 { return Data([UInt8(count)]) }
        var bytes: [UInt8] = []
        var rest = count
        while rest > 0 {
            bytes.insert(UInt8(rest & 0xff), at: 0)
            rest >>= 8
        }
        return Data([0x80 | UInt8(bytes.count)]) + Data(bytes)
    }

    static func element(_ tag: UInt8, _ content: Data) -> Data {
        Data([tag]) + length(content.count) + content
    }

    static func sequence(_ parts: Data...) -> Data { element(0x30, parts.reduce(Data(), +)) }
    static func set(_ parts: Data...) -> Data { element(0x31, parts.reduce(Data(), +)) }

    /// A positive INTEGER from big-endian bytes.
    static func integer(_ bytes: [UInt8]) -> Data {
        var content = Array(bytes.drop { $0 == 0 })
        if content.isEmpty { content = [0] }
        if content[0] & 0x80 != 0 { content.insert(0, at: 0) }
        return element(0x02, Data(content))
    }

    static func utf8String(_ text: String) -> Data { element(0x0c, Data(text.utf8)) }
    static func bitString(_ bytes: Data) -> Data { element(0x03, Data([0]) + bytes) }

    /// UTCTime for years up to 2049, GeneralizedTime after.
    static func time(_ date: Date) -> Data {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        func two(_ value: Int?) -> String { String(format: "%02d", value ?? 0) }
        let year = c.year ?? 1970
        if year < 2050 {
            let text = two(year % 100) + two(c.month) + two(c.day) + two(c.hour) + two(c.minute) + two(c.second) + "Z"
            return element(0x17, Data(text.utf8))
        }
        let text = String(format: "%04d", year) + two(c.month) + two(c.day) + two(c.hour) + two(c.minute) + two(c.second) + "Z"
        return element(0x18, Data(text.utf8))
    }

    /// OID 2.5.4.3 (commonName).
    static let commonName = Data([0x06, 0x03, 0x55, 0x04, 0x03])
    /// ecdsa-with-SHA256, 1.2.840.10045.4.3.2, as an AlgorithmIdentifier.
    static let ecdsaWithSHA256 = Data([0x30, 0x0a, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x04, 0x03, 0x02])
}
