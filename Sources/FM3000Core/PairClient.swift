import Foundation

/// What the Mac keeps of this phone, and the phone of the Mac. `key` and the device's own
/// key are never in it: the first is the pin to hold the Mac to, the second stays in the keychain.
public struct Grant: Codable, Equatable {
    public var at: DialAddress
    public var also: [DialAddress]
    public var homeKey: String
    public var deviceId: String
    public var kind: DeviceKind
    public var name: String
    public var addresses: [DialAddress] { [at] + also }

    /// The grant after the Mac says where it listens now: addresses a phone can reach (not loopback, link-local or a wildcard) join
    /// the others, newest first, so a Mac that moved on its private network is found at its new address. The address that paired
    /// stays first; the list keeps at most six others.
    public func learning(_ offered: [String]) -> Grant {
        let usable = offered.compactMap(DialAddress.init).filter { address in
            let host = address.host.lowercased()
            return !(host.hasPrefix("127.") || host == "::1" || host == "localhost" || host == "0.0.0.0" || host == "::" || host.hasPrefix("169.254.") || host.hasPrefix("fe80:"))
        }
        var kept: [DialAddress] = []
        for address in usable + also where address != at && !kept.contains(address) { kept.append(address) }
        var grant = self
        grant.also = Array(kept.prefix(6))
        return grant
    }
}

public enum PairError: Error, LocalizedError, Equatable {
    /// The Mac refused the link: its `refused` word and its reason.
    case refused(String, String)
    case badAnswer

    public var errorDescription: String? {
        switch self {
        case .refused(_, let reason): return reason
        case .badAnswer: return "Your Mac answered in a way this app does not understand."
        }
    }
}

public struct PairClient {
    public var timeout: TimeInterval = 10
    public init(timeout: TimeInterval = 10) { self.timeout = timeout }

    /// Uses the link once: dials each address in turn over TLS 1.3, holds the Mac to the link's pin,
    /// and only then sends `POST /pair` (docs/devices.md, "Joining").
    public func join(link: PairingLink, deviceName: String, identity: DeviceIdentity) async throws -> Grant {
        var lastError: Error = DialError.unreachable("no address")
        for address in link.addresses {
            let channel = RawTLSChannel(address: address, homePin: link.key, identity: identity)
            defer { channel.close() }
            do {
                try await channel.open(timeout: timeout)
            } catch DialError.homeKeyMismatch {
                throw DialError.homeKeyMismatch  // a wrong key is never retried at another address
            } catch {
                lastError = error
                continue
            }
            let body = try JSONSerialization.data(withJSONObject: [
                "code": link.code, "kind": link.kind.rawValue, "name": deviceName, "window": true, "system": "ios",
            ] as [String: Any])
            let head = "POST /pair HTTP/1.1\r\nHost: \(address)\r\nContent-Type: application/json\r\n"
                + "Content-Length: \(body.count)\r\nConnection: close\r\n\r\n"
            try await channel.send(Data(head.utf8) + body)
            let response = try await Self.readResponse(from: channel)
            return try Self.grant(from: response, link: link, address: address, name: deviceName)
        }
        throw lastError
    }

    struct Response { var status: Int; var body: Data }

    static func readResponse(from channel: RawTLSChannel) async throws -> Response {
        var buffer = Data()
        while true {
            guard let chunk = try await channel.receive() else { break }
            buffer += chunk
            if let response = parse(buffer, complete: false) { return response }
        }
        guard let response = parse(buffer, complete: true) else { throw PairError.badAnswer }
        return response
    }

    /// An HTTP/1.1 response: the status line, then the body by Content-Length or to the end.
    static func parse(_ data: Data, complete: Bool) -> Response? {
        guard let split = data.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        let head = String(decoding: data[..<split.lowerBound], as: UTF8.self)
        let lines = head.components(separatedBy: "\r\n")
        let status = lines[0].split(separator: " ")
        guard status.count >= 2, let code = Int(status[1]) else { return nil }
        let body = data[split.upperBound...]
        // Node answers `end(json)` after `writeHead` chunked, so the real Mac does too.
        if lines.dropFirst().contains(where: { $0.lowercased().hasPrefix("transfer-encoding:") && $0.lowercased().contains("chunked") }) {
            return decodeChunked(Data(body)).map { Response(status: code, body: $0) }
        }
        let lengthLine = lines.dropFirst().first { $0.lowercased().hasPrefix("content-length:") }
        if let lengthLine, let length = Int(lengthLine.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)) {
            return body.count >= length ? Response(status: code, body: Data(body.prefix(length))) : nil
        }
        return complete ? Response(status: code, body: Data(body)) : nil
    }

    /// The body of a chunked message, or nil until its last chunk has arrived.
    static func decodeChunked(_ data: Data) -> Data? {
        var result = Data()
        var rest = data[...]
        let crlf = Data("\r\n".utf8)
        while true {
            guard let lineEnd = rest.range(of: crlf) else { return nil }
            let sizeText = String(decoding: rest[..<lineEnd.lowerBound], as: UTF8.self).split(separator: ";").first.map(String.init) ?? ""
            guard let size = Int(sizeText.trimmingCharacters(in: .whitespaces), radix: 16) else { return nil }
            let start = lineEnd.upperBound
            if size == 0 { return result }
            guard rest.distance(from: start, to: rest.endIndex) >= size + 2 else { return nil }
            result += rest[start..<rest.index(start, offsetBy: size)]
            rest = rest[rest.index(start, offsetBy: size + 2)...]
        }
    }

    static func grant(from response: Response, link: PairingLink, address: DialAddress, name: String) throws -> Grant {
        let object = (try? JSONSerialization.jsonObject(with: response.body)) as? [String: Any]
        if response.status == 201, let deviceId = object?["deviceId"] as? String,
           let kindText = object?["kind"] as? String, let kind = DeviceKind(rawValue: kindText) {
            // It keeps the address that answered first.
            let others = link.addresses.filter { $0 != address }
            return Grant(at: address, also: others, homeKey: link.key, deviceId: deviceId, kind: kind, name: name)
        }
        if let refused = object?["refused"] as? String {
            throw PairError.refused(refused, object?["reason"] as? String ?? "The Mac refused this link.")
        }
        if response.status == 403 { throw PairError.refused("origin", "The Mac refused the request.") }
        throw PairError.badAnswer
    }
}
