import Foundation

/// What the Apple Watch and the phone say to each other. The watch cannot reach the Mac itself, so it asks the phone,
/// which holds the pairing and the connection. Plain text only: the watch draws no web view, and has no text field.

/// One of a card's buttons, as the watch shows it.
public struct WatchChoice: Codable, Equatable, Identifiable {
    public let id: String
    public let label: String
    public let isDefault: Bool
    public init(id: String, label: String, isDefault: Bool) { self.id = id; self.label = label; self.isDefault = isDefault }
}

/// A card waiting on the captain, reduced to what a wrist can read and answer.
public struct WatchCard: Codable, Equatable, Identifiable {
    public let id: String
    public let title: String
    /// The card's own byline (its task and author), one line.
    public let meta: String
    /// The body as plain text, cut to `WatchCard.textLimit`.
    public let text: String
    public let choices: [WatchChoice]
    /// The card asks a question to fill in (a form), which the watch cannot show: it says "Answer on your phone" and offers no choice.
    public let needsPhone: Bool

    public static let textLimit = 2_500

    public init(id: String, title: String, meta: String, text: String, choices: [WatchChoice], needsPhone: Bool) {
        self.id = id; self.title = title; self.meta = meta; self.text = text; self.choices = choices; self.needsPhone = needsPhone
    }
}

public enum WatchRequest: Codable, Equatable {
    /// The cards waiting on the captain, read fresh from the Mac.
    case cards
    /// Press one of a card's buttons: the Mac's `inf:cards:act`.
    case choose(cardId: String, choiceId: String)
    /// Put a card aside for later: the Mac's `inf:cards:minimize`.
    case putAside(cardId: String)
}

public struct WatchReply: Codable, Equatable {
    /// Every card now waiting on the captain, after the request ran. Nil when the phone could not read them.
    public let cards: [WatchCard]?
    /// The Mac's or the phone's reason when the request did not go through, in words for the wrist; nil on success.
    public let problem: String?
    public init(cards: [WatchCard]?, problem: String? = nil) { self.cards = cards; self.problem = problem }
}

/// WatchConnectivity carries property-list dictionaries: each message is one JSON blob under a fixed key.
public enum WatchWire {
    static let key = "fm3000.watch"
    public static func message(_ request: WatchRequest) -> [String: Any] { [key: (try? JSONEncoder().encode(request)) ?? Data()] }
    public static func request(from message: [String: Any]) -> WatchRequest? {
        (message[key] as? Data).flatMap { try? JSONDecoder().decode(WatchRequest.self, from: $0) }
    }
    public static func message(_ reply: WatchReply) -> [String: Any] { [key: (try? JSONEncoder().encode(reply)) ?? Data()] }
    public static func reply(from message: [String: Any]) -> WatchReply? {
        (message[key] as? Data).flatMap { try? JSONDecoder().decode(WatchReply.self, from: $0) }
    }
}
