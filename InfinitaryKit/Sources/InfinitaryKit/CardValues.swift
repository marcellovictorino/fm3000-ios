import Foundation

/// JSON at the published connection boundary, never a dynamically selected native capability.
public enum PhoneJSON: Codable, Sendable, Equatable {
    case object([String: PhoneJSON]), array([PhoneJSON]), string(String), number(Double), bool(Bool), null

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        if value.decodeNil() { self = .null }
        else if let v = try? value.decode(Bool.self) { self = .bool(v) }
        else if let v = try? value.decode(String.self) { self = .string(v) }
        else if let v = try? value.decode(Double.self) { self = .number(v) }
        else if let v = try? value.decode([PhoneJSON].self) { self = .array(v) }
        else { self = .object(try value.decode([String: PhoneJSON].self)) }
    }
    public func encode(to encoder: Encoder) throws {
        var value = encoder.singleValueContainer()
        switch self {
        case .object(let v): try value.encode(v)
        case .array(let v): try value.encode(v)
        case .string(let v): try value.encode(v)
        case .number(let v): try value.encode(v)
        case .bool(let v): try value.encode(v)
        case .null: try value.encodeNil()
        }
    }
    public subscript(_ key: String) -> PhoneJSON {
        if case .object(let value) = self { return value[key] ?? .null }
        return .null
    }
    public var text: String? { if case .string(let v) = self { return v }; return nil }
    public var list: [PhoneJSON] { if case .array(let v) = self { return v }; return [] }
    public var flag: Bool { self == .bool(true) }
    public var numeric: Double? { if case .number(let v) = self { return v }; return nil }
    public var foundation: Any { get throws { try JSONSerialization.jsonObject(with: JSONEncoder().encode(self), options: .fragmentsAllowed) } }
    public static func read(_ value: Any) throws -> PhoneJSON {
        try JSONDecoder().decode(Self.self, from: JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed))
    }
}

/// The "You asked" line's message: when the captain sent it and their words, whole (INF-1610).
public struct PhoneAsked: Equatable, Sendable {
    public let at: Date
    public let text: String
    /// Folded, the lines of a long message run together; opened, its paragraphs stay as written.
    public func words(open: Bool) -> String {
        let words = open ? text.trimmingCharacters(in: .whitespacesAndNewlines)
            : text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return words.isEmpty ? "A picture" : "\u{201C}\(words)\u{201D}"
    }
    /// "You asked · 9:10 AM", with the date in front when it was not today, as the Mac writes it.
    public func label(now: Date = Date(), calendar: Calendar = .current) -> String {
        let time = at.formatted(date: .omitted, time: .shortened)
        if calendar.isDate(at, inSameDayAs: now) { return "You asked · \(time)" }
        return "You asked · \(at.formatted(.dateTime.month(.abbreviated).day())), \(time)"
    }
}

public struct PhoneCard: Decodable, Identifiable, Sendable {
    public let value: PhoneJSON
    public var id: String { value["id"].text! }
    public var title: String { value["title"].text! }
    public var author: String { value["author"].text! }
    public var meta: String? { value["meta"].text }
    public var reviewTaskId: String? { value["reviewTaskId"].text }
    public var taskID: String? { value["taskId"].text }
    public var awaiting: String? { value["awaiting"].text }
    public var sentBackAt: Double? { value["sentBackAt"].numeric }
    public var body: String { value["body"].text! }
    public var offerID: String? { value["offerId"].text }
    public var actions: [PhoneJSON] { value["actions"].list }
    /// INF-1610: the captain's message the card is about, which the Mac read from the saved message, never the body.
    public var asked: PhoneAsked? {
        guard let at = value["asked"]["at"].numeric, let text = value["asked"]["text"].text else { return nil }
        return PhoneAsked(at: Date(timeIntervalSince1970: at / 1000), text: text)
    }
    /// INF-1670: the Mac's stuck alert is the host's, and names the first mate as the one who answers it.
    public var takesReplies: Bool {
        value["replies"] != .bool(false)
            && (author == "firstmate" || value["answeredBy"] == .string("firstmate")
                || (author == "crewmate" && value["taskId"].text != nil))
    }
    public var isPast: Bool { value["ending"] != .null }
    /// Minimized on the Mac: still open, but off its stack.
    public var minimized: Bool { value["minimized"] == .bool(true) }
    /// The evidence actor may be "frame"; name that frame's author, never the captain.
    /// Keep the stored ending untouched and reuse the shared owner's words after this typed projection.
    public var endingForWords: PhoneJSON {
        guard value["ending"]["by"] == .string("frame"), case .object(var ending) = value["ending"] else { return value["ending"] }
        ending["by"] = .string(author == "crewmate" ? "crewmate" : "firstmate")
        return .object(ending)
    }
    public init(from decoder: Decoder) throws {
        value = try PhoneJSON(from: decoder)
        guard value["id"].text != nil, value["title"].text != nil,
              value["author"].text != nil, value["body"].text != nil,
              case .array = value["actions"] else { throw PhoneError.invalidReply }
    }
    public init(_ value: PhoneJSON) throws {
        self = try JSONDecoder().decode(Self.self, from: JSONEncoder().encode(value))
    }
    public static func canSendReply(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.utf16.count <= PhoneLimits.reply
    }
    public func submission(reading: PhoneJSON? = nil, fresh: Bool = true) -> PhoneJSON {
        var fields: [String: PhoneJSON] = ["id": .string(UUID().uuidString), "reading": .string(reading == nil ? "none" : fresh ? "fresh" : "fallback")]
        for key in ["offerId", "lifecycleId"] where value[key] != .null { fields[key] = value[key] }
        if let reading {
            if fresh {
                for key in ["questions", "questionsGap"] where reading[key] != .null { fields[key] = reading[key] }
            } else { fields["questionsGap"] = .string("no-fresh-reading") }
        }
        return .object(fields)
    }
}

public struct PhoneRequestError: LocalizedError, Sendable {
    public let words: String
    public init(_ words: String) { self.words = words }
    public var errorDescription: String? { words }
}
