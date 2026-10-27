import Foundation

/// The protocol this app speaks (docs/contract.json `protocolVersion` is 12.0.0 in Infinitary 0.6.0).
/// The Mac gives full access only to its own major; other majors only read.
public let protocolVersion = "12.0.0"

public struct Cursor: Equatable, Codable {
    public var epoch: String
    public var seq: Int
}

public enum Access: String, Codable { case full, read }

public struct Welcome: Equatable {
    public let protocolVersion: String
    public let epoch: String
    public let seq: Int
    public let catchUp: String
    public let access: Access
    public let name: String?
    /// Where the Mac listens now, as `host:port` (its private-network addresses): the phone keeps the ones it can use for next time.
    public var addresses: [String] = []
}

public struct Push: Equatable {
    public let seq: Int
    public let channel: String
    public let payload: JSONValue
}

/// A request's answer: the value, or the Mac's reason in its own words.
public struct InvokeFailure: Error, Equatable, LocalizedError {
    public let reason: String
    public var errorDescription: String? { reason }
}

/// What the Mac sends after the handshake.
public enum HomeFrame: Equatable {
    case welcome(Welcome)
    case push(Push)
    case result(id: Int, value: JSONValue?, error: String?)
    case ignored

    /// Reads one text frame leniently: a field this version does not know is ignored (docs/connection.md).
    public static func parse(_ text: String) throws -> HomeFrame {
        guard let data = text.data(using: .utf8), case .object(let o) = try JSONDecoder().decode(JSONValue.self, from: data),
              case .string(let t)? = o["t"] else { throw WireError.notAFrame }
        func int(_ key: String) -> Int? { if case .number(let n)? = o[key] { return Int(exactly: n) } else { return nil } }
        func string(_ key: String) -> String? { if case .string(let s)? = o[key] { return s } else { return nil } }
        func strings(_ key: String) -> [String] { if case .array(let a)? = o[key] { return a.compactMap { if case .string(let s) = $0 { return s } else { return nil } } } else { return [] } }
        switch t {
        case "welcome":
            guard let version = string("protocolVersion"), let epoch = string("epoch"), let seq = int("seq"),
                  let catchUp = string("catchUp"), let accessText = string("access"), let access = Access(rawValue: accessText)
            else { throw WireError.notAFrame }
            return .welcome(Welcome(protocolVersion: version, epoch: epoch, seq: seq, catchUp: catchUp, access: access, name: string("name"), addresses: strings("addresses")))
        case "push":
            guard let seq = int("seq"), let channel = string("channel") else { throw WireError.notAFrame }
            return .push(Push(seq: seq, channel: channel, payload: o["payload"] ?? .null))
        case "result":
            guard let id = int("id"), case .bool(let ok)? = o["ok"] else { throw WireError.notAFrame }
            if ok { return .result(id: id, value: o["value"] ?? .null, error: nil) }
            return .result(id: id, value: nil, error: string("error") ?? "The request was refused.")
        default:
            return .ignored
        }
    }

    public static func hello(cursor: Cursor?) -> String {
        var frame: [String: JSONValue] = [
            "t": .string("hello"), "protocolVersion": .string(protocolVersion),
            "as": .string("view"), "system": .string("ios"), "chip": .string("arm64"),
            // Without this the Mac takes the phone for a build from before the rename and writes every push under the old `fm:` names.
            "spellings": .array([.string("inf")]),
        ]
        if let cursor { frame["cursor"] = .object(["epoch": .string(cursor.epoch), "seq": .number(Double(cursor.seq))]) }
        return encode(.object(frame))
    }

    public static func invoke(id: Int, channel: String, args: [JSONValue]) -> String {
        encode(.object(["t": .string("invoke"), "id": .number(Double(id)), "channel": .string(channel), "args": .array(args)]))
    }

    public static func leave() -> String { encode(.object(["t": .string("leave")])) }

    private static func encode(_ value: JSONValue) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(decoding: (try? encoder.encode(value)) ?? Data(), as: UTF8.self)
    }
}

public enum WireError: Error, LocalizedError, Equatable {
    case notAFrame
    case closed(code: Int?, reason: String?)
    case unpaired
    case timedOut

    public var errorDescription: String? {
        switch self {
        case .notAFrame: return "The Mac sent something this app does not understand."
        case .closed(let code, _): return "The connection closed\(code.map { " (\($0))" } ?? "")."
        case .unpaired: return "This phone was removed in Settings > Devices on the Mac. Pair it again."
        case .timedOut: return "The Mac did not answer."
        }
    }
}

/// The close codes of docs/connection.md.
public enum CloseCode {
    public static let protocolError = 4400
    public static let unpaired = 4401
    public static let behind = 4408
    public static let closing = 1001
}
