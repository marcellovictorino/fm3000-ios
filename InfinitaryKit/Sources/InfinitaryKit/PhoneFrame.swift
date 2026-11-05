import Foundation

/// INF-2566 (approved B): one frame from the computer, parsed and its heavy payloads decoded off the main thread,
/// so a large board, card list or feed never holds the main thread while the crew scene is moving.
/// The session reads it on the main actor in arrival order; a payload whose decoding failed throws only where the
/// session would have decoded it, so a payload the session ignores still fails nothing.
struct PhoneFrame: Sendable {
    /// What a payload decoded into; `failed` keeps the decoding's failure for the moment the session reads it.
    enum Payload: Sendable {
        case cards([PhoneCard])
        case board(PhoneBoard)
        case delta(PhoneBoardDelta)
        case computers([PhoneComputerPresence])
        case feed([ActivityLine])
        case conversation(PhoneConversationState)
        case lastTurn(PhoneLastTurn?)
        case failed
    }

    /// The parsed envelope, which nothing mutates after parsing (`JSONSerialization` hands back immutable containers).
    private nonisolated(unsafe) let object: [String: Any]
    /// The decoded payload of a push or of a read the session was waiting for.
    let payload: Payload?
    /// A call's answer, serialized once for the caller waiting on it.
    let answer: Data?
    /// Whether the parsing ran on the main thread, kept so a test can show the session's decoding left it.
    let onMain = Thread.isMainThread

    var frame: [String: Any] { object }

    /// Parses `text` and decodes the payload its channel names; `reads` maps each read the session is waiting for to
    /// its channel, as the session's own `pending` held it when the frame arrived.
    @concurrent static func decode(_ text: String, reads: [Int: String]) async throws -> PhoneFrame {
        try read(Data(text.utf8), reads: reads)
    }

    static func read(_ data: Data, reads: [Int: String]) throws -> PhoneFrame {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw PhoneError.invalidReply }
        switch object["t"] as? String {
        case "push":
            guard let channel = object["channel"] as? String, let value = object["payload"] else { break }
            return PhoneFrame(object: object, payload: payload(channel, value: value, pushed: true), answer: nil)
        case "result":
            guard object["ok"] as? Bool == true, let id = object["id"] as? Int, let value = object["value"] else { break }
            let answer = try? JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)
            let payload = reads[id].flatMap { payload($0, value: value, pushed: false) }
            return PhoneFrame(object: object, payload: payload, answer: answer)
        default: break
        }
        return PhoneFrame(object: object, payload: nil, answer: nil)
    }

    private init(object: [String: Any], payload: Payload?, answer: Data?) {
        self.object = object; self.payload = payload; self.answer = answer
    }

    private static func payload(_ channel: String, value: Any, pushed: Bool) -> Payload? {
        func decoded<T: Decodable>(_ type: T.Type, _ wrap: (T) -> Payload) -> Payload {
            guard let bytes = try? JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed),
                  let result = try? JSONDecoder().decode(T.self, from: bytes) else { return .failed }
            return wrap(result)
        }
        switch (channel, pushed) {
        case ("inf:cards", true), (PhoneContract.cards, false): return decoded([PhoneCard].self, Payload.cards)
        case ("inf:tasks", true), (PhoneRequest.board.rawValue, false): return decoded(PhoneBoard.self, Payload.board)
        case ("inf:tasks:delta", true): return decoded(PhoneBoardDelta.self, Payload.delta)
        case ("inf:computers:presence", true), (PhoneRequest.computers.rawValue, false):
            return decoded([PhoneComputerPresence].self, Payload.computers)
        case (PhoneContract.feed, false): return decoded([ActivityLine].self, Payload.feed)
        case (PhoneRequest.conversationState.rawValue, false): return decoded(PhoneConversationState.self, Payload.conversation)
        case (PhoneRequest.lastTurn.rawValue, false): return decoded(PhoneLastTurn?.self, Payload.lastTurn)
        default: return nil
        }
    }

    func cards() throws -> [PhoneCard] { if case .cards(let value) = payload { return value }; throw PhoneError.invalidReply }
    func board() throws -> PhoneBoard { if case .board(let value) = payload { return value }; throw PhoneError.invalidReply }
    func delta() throws -> PhoneBoardDelta { if case .delta(let value) = payload { return value }; throw PhoneError.invalidReply }
    func computers() throws -> [PhoneComputerPresence] { if case .computers(let value) = payload { return value }; throw PhoneError.invalidReply }
    func feed() throws -> [ActivityLine] { if case .feed(let value) = payload { return value }; throw PhoneError.invalidReply }
    func conversation() throws -> PhoneConversationState { if case .conversation(let value) = payload { return value }; throw PhoneError.invalidReply }
    func lastTurn() throws -> PhoneLastTurn? { if case .lastTurn(let value) = payload { return value }; throw PhoneError.invalidReply }
}
