import Foundation

/// Where a device dials: `host:port`, an address or a name.
public struct DialAddress: Equatable, Hashable, Codable, CustomStringConvertible {
    public let host: String
    public let port: UInt16

    public init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }

    /// Reads `host:port` or `[v6]:port`.
    public init?(_ text: String) {
        if text.hasPrefix("[") {
            guard let close = text.firstIndex(of: "]") else { return nil }
            let rest = text[text.index(after: close)...]
            guard rest.hasPrefix(":"), let port = UInt16(rest.dropFirst()) else { return nil }
            self.init(host: String(text[text.index(after: text.startIndex)..<close]), port: port)
            return
        }
        guard let colon = text.lastIndex(of: ":"), text.firstIndex(of: ":") == colon else { return nil }
        let host = String(text[..<colon])
        guard !host.isEmpty, let port = UInt16(text[text.index(after: colon)...]), port > 0 else { return nil }
        self.init(host: host, port: port)
    }

    public var description: String { host.contains(":") ? "[\(host)]:\(port)" : "\(host):\(port)" }
}

public enum DeviceKind: String, Codable, Equatable {
    case mac, work, view
}

public enum PairingLinkError: Error, Equatable, LocalizedError {
    case notALink
    case damaged
    case wrongKind(DeviceKind)
    case viaUnsupported

    // Never repeats the link: it carries its code (docs/devices.md, "The link").
    public var errorDescription: String? {
        switch self {
        case .notALink: return "This is not a link to join Infinitary."
        case .damaged: return "This link to join Infinitary is damaged."
        case .wrongKind: return "This link is for a computer that runs work, which a phone cannot be."
        case .viaUnsupported: return "This link reaches the Mac through SSH, which a phone cannot do."
        }
    }
}

/// `firstmate3000://join?as=mac&at=host:47623&also=a:1,b:2&key=<pin>&code=<code>`
public struct PairingLink: Equatable {
    public let kind: DeviceKind
    public let at: DialAddress
    public let also: [DialAddress]
    /// The Mac's pin: SHA-256 over its public key (SPKI), base64url, 43 characters.
    public let key: String
    /// One use, ten minutes, 43 characters.
    public let code: String

    public var addresses: [DialAddress] { [at] + also }

    static let prefixes = ["firstmate3000://join?", "infinitary://join?"]

    public static func parse(_ text: String) throws -> PairingLink {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let prefix = prefixes.first(where: { trimmed.hasPrefix($0) }) else { throw PairingLinkError.notALink }
        var parts: [String: String] = [:]
        var components = URLComponents()
        components.percentEncodedQuery = String(trimmed.dropFirst(prefix.count))
        for item in components.queryItems ?? [] {
            guard ["as", "at", "also", "key", "code", "via"].contains(item.name), parts[item.name] == nil,
                  let value = item.value else { throw PairingLinkError.damaged }
            parts[item.name] = value
        }
        if parts["via"] != nil { throw PairingLinkError.viaUnsupported }
        guard let kindText = parts["as"], let kind = DeviceKind(rawValue: kindText),
              let atText = parts["at"], let at = DialAddress(atText),
              let key = parts["key"], isKeyText(key),
              let code = parts["code"], isKeyText(code) else { throw PairingLinkError.damaged }
        var also: [DialAddress] = []
        if let alsoText = parts["also"] {
            for piece in alsoText.split(separator: ",") where !piece.isEmpty {
                guard let address = DialAddress(String(piece)) else { throw PairingLinkError.damaged }
                also.append(address)
            }
            guard also.count <= 8 else { throw PairingLinkError.damaged }
        }
        guard kind != .work else { throw PairingLinkError.wrongKind(kind) }
        return PairingLink(kind: kind, at: at, also: also, key: key, code: code)
    }

    /// 43 base64url characters, a 32-byte value.
    static func isKeyText(_ text: String) -> Bool {
        text.utf8.count == 43 && text.utf8.allSatisfy {
            ($0 >= 0x30 && $0 <= 0x39) || ($0 >= 0x41 && $0 <= 0x5a) || ($0 >= 0x61 && $0 <= 0x7a) || $0 == 0x2d || $0 == 0x5f
        }
    }
}
