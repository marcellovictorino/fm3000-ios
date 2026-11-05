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
/// A question's words, shared by the card's asked line and the conversation's question bubble.
/// Folded, whitespace runs together; opened, the original paragraphs remain (INF-1963, INF-2219).
public func phoneQuestionWords(_ text: String, open: Bool) -> String {
    let words = open ? text.trimmingCharacters(in: .whitespacesAndNewlines)
        : text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    return words.isEmpty ? "A picture" : words
}

/// Where a card's work came from (INF-2326), as the Mac read it: the captain's message that filed or started it,
/// a message of theirs aimed at that work alone, their click, an automation, or the nearest task it came from.
public enum PhoneAskedKind: String, Equatable, Sendable {
    case asked, said, chose, automation, from
}

public struct PhoneAsked: Equatable, Sendable {
    public let at: Date
    public let text: String
    public var kind: PhoneAskedKind = .asked
    /// A click's button words.
    public var choice: String? = nil
    /// The nearest task's key, for a line from a task.
    public var key: String? = nil
    /// How many tasks the source sits behind; nil on the card's own task.
    public var through: Int? = nil

    public init(at: Date, text: String, kind: PhoneAskedKind = .asked, choice: String? = nil, key: String? = nil, through: Int? = nil) {
        self.at = at
        self.text = text
        self.kind = kind
        self.choice = choice
        self.key = key
        self.through = through
    }

    /// The captain's own words sit in the bubble; an automation's name and a task's title sit without it.
    public var inBubble: Bool { kind != .automation && kind != .from }
    /// The words the line shows: a click's button words, then what the captain wrote with it.
    public var shown: String {
        guard kind == .chose else { return text }
        let written = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return written.isEmpty ? (choice ?? "") : "\(choice ?? "") · \(written)"
    }
    /// Folded, the lines of a long message run together; opened, its paragraphs stay as written.
    public func words(open: Bool) -> String { phoneQuestionWords(shown, open: open) }
    /// "You asked · 9:10 AM", with the date in front when it was not today, as the Mac writes it, then
    /// "· through 3 tasks" when the source is on another task; "From INF-2081" for the nearest task.
    public func label(now: Date = Date(), calendar: Calendar = .current) -> String {
        if kind == .from { return "From \(key ?? "")" }
        let name: String
        switch kind {
        case .said: name = "You said"
        case .chose: name = "You chose"
        case .automation: name = "Run by an automation"
        default: name = "You asked"
        }
        let time = at.formatted(date: .omitted, time: .shortened)
        let when = calendar.isDate(at, inSameDayAs: now)
            ? time : "\(at.formatted(.dateTime.month(.abbreviated).day())), \(time)"
        let tail = through.map { " · through \($0) \($0 == 1 ? "task" : "tasks")" } ?? ""
        return "\(name) · \(when)\(tail)"
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
    public var lifecycleID: String? { value["lifecycleId"].text }
    public var currentUpdateID: String? { value["currentUpdateId"].text }
    public var currentUpdateSeen: Bool { value["currentUpdateSeen"].flag }
    public var actions: [PhoneJSON] { value["actions"].list }
    /// INF-1610: the captain's message the card is about, which the Mac read from the saved message, never the body.
    /// INF-2326: or the click, automation or task it came from instead.
    public var asked: PhoneAsked? {
        let line = value["asked"]
        guard let at = line["at"].numeric, let text = line["text"].text else { return nil }
        return PhoneAsked(
            at: Date(timeIntervalSince1970: at / 1000), text: text,
            kind: line["kind"].text.flatMap(PhoneAskedKind.init(rawValue:)) ?? .asked,
            choice: line["choice"].text, key: line["key"].text,
            through: line["through"].numeric.map { Int($0) })
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
    /// A card the phone already read, with a field the intent layer folded in (INF-2553).
    init(trusted value: PhoneJSON) { self.value = value }
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
