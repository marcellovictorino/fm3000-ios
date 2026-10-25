import Foundation

/// One message in any chat on the phone: the main Firstmate chat, a card's thread, a crewmate's thread.
/// `who` is the Mac's word: captain, firstmate, crewmate or host.
public struct ChatItem: Equatable, Identifiable {
    public let id: String
    public let who: String
    public let text: String
    public let at: Double
    public var problem: Bool

    public init(id: String, who: String, text: String, at: Double, problem: Bool = false) {
        self.id = id; self.who = who; self.text = text; self.at = at; self.problem = problem
    }

    /// The captain's own words sit on the right; everyone else's on the left.
    public var isMine: Bool { who == "captain" }

    /// The label above a bubble, in the desktop thread's words (`crew`, `mate`), spelled out for a phone.
    public var label: String {
        switch who {
        case "captain": return "You"
        case "firstmate": return "Firstmate"
        case "crewmate": return "Crewmate"
        case "host": return "Infinitary"
        default: return who.capitalized
        }
    }

    /// Oldest first, as a chat reads: by time, ties by arrival order.
    public static func chronological(_ items: [ChatItem]) -> [ChatItem] {
        items.enumerated().sorted { a, b in a.element.at != b.element.at ? a.element.at < b.element.at : a.offset < b.offset }.map(\.element)
    }
}

public extension ThreadMessage {
    var chatItem: ChatItem { ChatItem(id: "t\(Int(id))", who: who, text: text, at: at) }
}

public extension CrewLine {
    /// A crewmate-record line as a chat message, or nil when it is machinery or a brief (shown elsewhere).
    var chatItem: ChatItem? {
        switch kind {
        case "said": return text.map { ChatItem(id: id, who: "crewmate", text: $0, at: at) }
        case "report": return ChatItem(id: id, who: "crewmate", text: [summary, text].compactMap { $0 }.joined(separator: "\n\n"), at: at)
        case "sent": return text.map { ChatItem(id: id, who: from == "captain" ? "captain" : "firstmate", text: $0, at: at) }
        default: return nil
        }
    }
}

public struct LastTurn: Codable, Equatable {
    public struct Reply: Codable, Equatable { public let text: String; public let problem: Bool? }
    public let you: String
    public let reply: Reply?
}


/// What the Message tab keeps: the last three hours, and each of the captain's posts with only the first answer to it.
/// Anything further about a request happens on its task or card, so this view stays a short list of asks and answers.
public enum ChatWindow {
    public static let span: Double = 3 * 3600 * 1000

    public static func visible(_ items: [ChatItem], now: Double) -> [ChatItem] {
        var kept: [ChatItem] = []
        var open = false  // a captain's post is waiting for its first answer
        for item in items where item.at >= now - span {
            if item.isMine { kept.append(item); open = true }
            else if open { kept.append(item); open = false }  // the first answer; later ones, and answers to nothing, are dropped
        }
        return kept
    }
}
