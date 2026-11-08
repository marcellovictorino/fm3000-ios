import Foundation

/// INF-2553, the captain's direction B: every change the captain makes on this phone is an intent, drawn at once over
/// the home's last snapshot and kept until the home's own evidence settles it. The snapshot is never edited, so taking
/// a prediction back is dropping its intent. The table of kinds, what each predicts and what settles it is
/// `src/shared/intents.ts`; `Fixtures/PhoneIntents.json` is the fixture both sides replay.
public struct PhoneIntent: Sendable, Equatable, Identifiable {
    public enum Kind: Sendable, Equatable {
        /// Close a card: it leaves the stage.
        case close(card: String, lifecycle: String?, offer: String?)
        /// A footer or body choice: the card leaves the stage.
        case choose(card: String, lifecycle: String?, offer: String?)
        /// Put a card aside: it leaves the stage for its task row.
        case putAside(card: String, lifecycle: String?, offer: String?)
        /// Bring a card put aside back to the stage.
        case bringBack(card: String)
        /// A reply under a card: its words join the thread, marked sending. `before` counts the captain's messages the
        /// thread showed at the tap, sending ones included: the home writes a reply's words its own way (trimmed, with a
        /// line for each picture), so the evidence counts messages and never compares words.
        case reply(card: String, text: String, before: Int)
        /// A message to the first mate: it shows as the last turn, marked sending. `before` is the last turn shown at the
        /// tap, which the home's turn for this message follows; the words are never compared.
        case send(text: String, before: PhoneTurnMark?)
        /// Start or Continue a task: the record and its row read Starting.
        case start(task: String, move: String)
        /// Explicit Done or Dismiss: the record and row show the selected ending.
        case finish(task: String, ending: PhoneTaskEnding)
        /// Interrupt a crewmate's turn: the record reads Stopping.
        case interrupt(task: String)
        /// Steer a crewmate: the words show as sent in its transcript. `before` counts the captain's steers the
        /// transcript showed at the tap, sending ones included, as a reply's does.
        case steer(task: String, text: String, before: Int)
    }

    /// `sent` waits on the home's result; `accepted` on the snapshot that holds the change; `unknown` lost its result
    /// and waits for the first snapshot read after the phone reaches its computer again.
    public enum State: Sendable, Equatable { case sent, accepted, unknown(welcome: Int) }

    public let id: Int
    public internal(set) var kind: Kind
    public internal(set) var state: State
    public let at: Date
}

/// The two explicit task endings offered by the home; never inferred from a card leaving.
public enum PhoneTaskEnding: String, Sendable, CaseIterable {
    case answerDone = "answer-done"
    case dismissQuestion = "dismiss-question"
    public var status: String { self == .answerDone ? "done" : "dropped" }
    public var reason: String { self == .answerDone ? "answered" : "cancelled" }
}

/// Which last turn a message was sent after: the newest round's words and the round's before it.
public struct PhoneTurnMark: Sendable, Equatable {
    public let you: String
    public let previous: String?
    public init(you: String, previous: String?) { self.you = you; self.previous = previous }
    public init?(_ turn: PhoneLastTurn?) {
        guard let turn else { return nil }
        self.init(you: turn.you, previous: turn.previous?.you)
    }
}

/// What one snapshot says of one intent.
public enum PhoneIntentEvidence: Sendable, Equatable {
    /// The snapshot already holds the change: the intent retires and nothing on screen moves.
    case holds
    /// The thing the intent named changed under it (a revised card, a closed task): the intent goes, with no notice.
    case void
    /// The snapshot is about the intent's target and does not hold the change.
    case lacks
}

/// A snapshot the home sent, as the ledger reads it.
public enum PhoneSnapshot: Sendable {
    case cards([PhoneCard])
    case thread(card: String, PhoneJSON)
    case board(PhoneBoard)
    case task(PhoneTask)
    case turn(PhoneLastTurn?)
    case crew(PhoneCrew)
}

/// The captain's pending intents and the rules that settle them; pure, so the session only wires it.
public struct PhoneIntentLedger: Sendable {
    public private(set) var intents: [PhoneIntent] = []
    private var lastID = 0

    public init() {}

    public var isEmpty: Bool { intents.isEmpty }

    @discardableResult
    public mutating func add(_ kind: PhoneIntent.Kind, at: Date = Date()) -> Int {
        lastID += 1
        intents.append(PhoneIntent(id: lastID, kind: kind, state: .sent, at: at))
        return lastID
    }

    public func intent(_ id: Int) -> PhoneIntent? { intents.first { $0.id == id } }

    /// The home accepted it; the snapshot that holds the change retires it.
    public mutating func accept(_ id: Int) {
        guard let index = intents.firstIndex(where: { $0.id == id }), intents[index].state == .sent else { return }
        intents[index].state = .accepted
    }

    /// The result was lost (a cut connection, the serve watchdog, a reload): the prediction stays, by the captain's
    /// choice, until the first snapshot read after the phone reaches its computer again.
    public mutating func lose(_ id: Int, welcome: Int) {
        guard let index = intents.firstIndex(where: { $0.id == id }), intents[index].state == .sent else { return }
        intents[index].state = .unknown(welcome: welcome)
    }

    /// Takes the intent back: the home refused it, or an accepted one never showed.
    @discardableResult
    public mutating func drop(_ id: Int) -> PhoneIntent? {
        guard let index = intents.firstIndex(where: { $0.id == id }) else { return nil }
        return gone(at: index)
    }

    /// Removes a change the home does not hold. A reply, message or steer counted the ones still sending in its
    /// place at its tap, so each later one in that place stops counting this one.
    private mutating func gone(at index: Int) -> PhoneIntent {
        let gone = intents.remove(at: index)
        var next = true
        for later in intents.indices where intents[later].id > gone.id {
            switch (gone.kind, intents[later].kind) {
            case let (.reply(card, _, _), .reply(other, text, before)) where other == card:
                intents[later].kind = .reply(card: other, text: text, before: before - 1)
            case let (.steer(task, _, _), .steer(other, text, before)) where other == task:
                intents[later].kind = .steer(task: other, text: text, before: before - 1)
            case let (.send(_, mark), .send(text, _)) where next:
                intents[later].kind = .send(text: text, before: mark); next = false
            default: break
            }
        }
        return gone
    }

    public mutating func clear() { intents = [] }

    /// Settles every intent the snapshot speaks about. `welcome` counts the connections that were welcomed, so an
    /// unknown intent is settled only by a snapshot read after the phone reached its computer again. Returns the
    /// intents taken back because that snapshot contradicts them, for the session to say so and restore drafts.
    public mutating func saw(_ snapshot: PhoneSnapshot, welcome: Int) -> [PhoneIntent] {
        var contradicted: [PhoneIntent] = []
        var index = 0
        while index < intents.count {
            switch (Self.evidence(intents[index].kind, snapshot), intents[index].state) {
            case (.holds?, _): intents.remove(at: index)
            case (.void?, _): _ = gone(at: index)
            case (.lacks?, .unknown(let lost)) where welcome > lost: contradicted.append(gone(at: index))
            default: index += 1
            }
        }
        return contradicted
    }

    /// What `snapshot` says of an intent of this kind, or nil when it says nothing about it.
    public static func evidence(_ kind: PhoneIntent.Kind, _ snapshot: PhoneSnapshot) -> PhoneIntentEvidence? {
        switch (kind, snapshot) {
        case let (.close(id, lifecycle, offer), .cards(cards)):
            guard let card = cards.first(where: { $0.id == id }), same(card.lifecycleID, lifecycle) else { return .holds }
            return same(card.offerID, offer) ? .lacks : .void
        case let (.choose(id, lifecycle, offer), .cards(cards)):
            guard let card = cards.first(where: { $0.id == id }), same(card.lifecycleID, lifecycle) else { return .holds }
            if card.awaiting != nil && card.sentBackAt == nil { return .holds }
            return same(card.offerID, offer) ? .lacks : .void
        case let (.putAside(id, lifecycle, offer), .cards(cards)):
            guard let card = cards.first(where: { $0.id == id }), same(card.lifecycleID, lifecycle) else { return .holds }
            if card.minimized { return .holds }
            return same(card.offerID, offer) ? .lacks : .void
        case let (.bringBack(id), .cards(cards)):
            guard let card = cards.first(where: { $0.id == id }) else { return .void }
            return card.minimized ? .lacks : .holds
        case let (.reply(id, _, _), .cards(cards)):
            return cards.contains { $0.id == id } ? nil : .void
        case let (.reply(id, _, before), .thread(card, thread)):
            guard card == id else { return nil }
            return captainMessages(thread) > before ? .holds : .lacks
        case let (.send(_, before), .turn(turn)):
            guard let turn else { return .lacks }
            return PhoneTurnMark(turn) != before && turn.previous?.you == before?.you ? .holds : .lacks
        case let (.start(id, move), .board(board)):
            return board.tasks.first { $0.id == id }.map { started($0, move) } ?? .void
        case let (.start(id, move), .task(task)):
            return task.id == id ? started(task, move) : nil
        case let (.finish(id, ending), .board(board)):
            return board.tasks.first { $0.id == id }.map { finished($0, ending) } ?? .void
        case let (.finish(id, ending), .task(task)):
            return task.id == id ? finished(task, ending) : nil
        case let (.interrupt(id), .board(board)):
            return board.tasks.first { $0.id == id }.map(stopped) ?? .void
        case let (.interrupt(id), .task(task)):
            return task.id == id ? stopped(task) : nil
        case let (.steer(id, _, before), .crew(crew)):
            guard crew.taskId == id else { return nil }
            return captainSteers(crew) > before ? .holds : .lacks
        default: return nil
        }
    }

    /// An identity the phone did not hold matches any; one it held must match.
    private static func same(_ now: String?, _ then: String?) -> Bool { then == nil || now == then }

    /// The captain's messages in a thread, those still sending included.
    public static func captainMessages(_ thread: PhoneJSON?) -> Int {
        (thread?["messages"].list ?? []).filter { $0["who"].text == "captain" }.count
    }

    /// The captain's steers in a transcript, those still sending included.
    public static func captainSteers(_ crew: PhoneCrew?) -> Int {
        (crew?.lines ?? []).filter { $0.kind == "sent" && $0.from == "captain" }.count
    }

    private static func started(_ task: PhoneTask, _ move: String) -> PhoneIntentEvidence {
        if task.status == "done" || task.status == "dropped" { return .void }
        let attempting = task.startAttempt?.phase == "preparing" || task.startAttempt?.phase == "checking"
        let running = task.status == "active" && ["starting", "running"].contains(task.activity ?? "")
        let offered = task.moves.map { $0[move]?.ok == true }
        return attempting || running || offered == false ? .holds : .lacks
    }

    private static func finished(_ task: PhoneTask, _ ending: PhoneTaskEnding) -> PhoneIntentEvidence {
        if task.status == ending.status && task.closedReason == ending.reason { return .holds }
        return task.status == "done" || task.status == "dropped" ? .void : .lacks
    }

    private static func stopped(_ task: PhoneTask) -> PhoneIntentEvidence {
        if task.status != "active" { return .void }
        return task.activity == "running" ? .lacks : .holds
    }
}

/// The folds: what the screens show, the home's snapshot with the pending intents drawn over it in the order sent.
public enum PhoneIntentFold {
    public static func cards(_ synced: [PhoneCard], _ intents: [PhoneIntent]) -> [PhoneCard] {
        guard !intents.isEmpty else { return synced }
        var cards = synced
        for intent in intents {
            switch intent.kind {
            case let .close(id, _, _), let .choose(id, _, _):
                cards.removeAll { $0.id == id }
            case let .putAside(id, _, _):
                cards = cards.map { $0.id == id ? $0.minimizing(true) : $0 }
            case let .bringBack(id):
                cards = cards.map { $0.id == id ? $0.minimizing(false) : $0 }
            default: break
            }
        }
        return cards
    }

    /// A reply's words join its thread as the captain's, marked `sending`, as the thread push will carry them.
    public static func threads(_ synced: [String: PhoneJSON], _ intents: [PhoneIntent]) -> [String: PhoneJSON] {
        var threads = synced
        for intent in intents {
            guard case let .reply(id, text, _) = intent.kind else { continue }
            var thread: [String: PhoneJSON] = ["cardId": .string(id), "messages": .array([])]
            if case .object(let held) = threads[id] ?? .null { thread = held }
            let message: PhoneJSON = .object(["who": .string("captain"), "text": .string(text),
                                              "at": .number(intent.at.timeIntervalSince1970 * 1000), "sending": .bool(true)])
            thread["messages"] = .array((thread["messages"] ?? .null).list + [message])
            threads[id] = .object(thread)
        }
        return threads
    }

    /// The message sent is the newest round, with no reply yet; the round it follows becomes the older one.
    public static func lastTurn(_ synced: PhoneLastTurn?, _ intents: [PhoneIntent]) -> PhoneLastTurn? {
        var turn = synced
        for intent in intents {
            guard case let .send(text, _) = intent.kind else { continue }
            turn = PhoneLastTurn(you: text, reply: nil, previous: turn.map { PhoneLastRound(you: $0.you, reply: $0.reply) })
        }
        return turn
    }

    public static func board(_ synced: PhoneBoard?, _ intents: [PhoneIntent]) -> PhoneBoard? {
        guard var board = synced, intents.contains(where: { $0.taskID != nil }) else { return synced }
        board.tasks = board.tasks.map { task($0, intents) }
        return board
    }

    public static func task(_ synced: PhoneTask, _ intents: [PhoneIntent]) -> PhoneTask {
        var task = synced
        for intent in intents where intent.taskID == task.id {
            switch intent.kind {
            case let .start(_, move):
                task.startAttempt = PhoneTask.StartAttempt(phase: "preparing", since: intent.at.timeIntervalSince1970 * 1000)
                // The host leaves the start wait out while an attempt stands (INF-2935: no wait line while Starting).
                task.queueWait = nil
                task.moves = (task.moves ?? [:]).merging([move: PhoneMove(ok: false, text: nil)]) { $1 }
            case let .finish(_, ending):
                task.status = ending.status
                task.closedReason = ending.reason
            case .interrupt:
                task.activity = "stopping"
            default: break
            }
        }
        return task
    }

    /// A steer's words show as sent in its transcript, under an id the home never writes.
    public static func crew(_ synced: PhoneCrew, _ intents: [PhoneIntent]) -> PhoneCrew {
        let lines = intents.compactMap { intent -> PhoneCrew.Line? in
            guard case let .steer(id, text, _) = intent.kind, id == synced.taskId else { return nil }
            return PhoneCrew.Line(id: "\(PhoneCrew.Line.sendingPrefix)\(intent.id)", kind: "sent", text: text, title: nil,
                                  summary: nil, from: "captain", name: nil, target: nil, reading: nil, result: nil)
        }
        guard !lines.isEmpty else { return synced }
        return PhoneCrew(taskId: synced.taskId, earlier: synced.earlier, lines: synced.lines + lines)
    }
}

extension PhoneIntent {
    /// The task an intent changes, for the board's fold.
    public var taskID: String? {
        switch kind {
        case let .start(id, _), let .finish(id, _), let .interrupt(id), let .steer(id, _, _): return id
        default: return nil
        }
    }

    /// Where an iPhone on its side says why the intent was taken back: its card's own line, or the composer's for a
    /// message.
    public var place: String? {
        if case .send = kind { return Self.messagePlace }
        return cardID
    }
    public static let messagePlace = "message"

    /// The card an intent changes.
    public var cardID: String? {
        switch kind {
        case let .close(id, _, _), let .choose(id, _, _), let .putAside(id, _, _), let .bringBack(id), let .reply(id, _, _): return id
        default: return nil
        }
    }
}

extension PhoneCard {
    /// The same card, put aside or brought back, as the home writes `minimized`.
    func minimizing(_ minimized: Bool) -> PhoneCard {
        guard case .object(var value) = value else { return self }
        if minimized { value["minimized"] = .bool(true) } else { value.removeValue(forKey: "minimized") }
        return PhoneCard(trusted: .object(value))
    }
}

extension PhoneCrew.Line {
    /// The id prefix of a steer the home has not shown yet.
    public static let sendingPrefix = "sending-"
    public var sending: Bool { id.hasPrefix(Self.sendingPrefix) }
}

/// Why a change shown at the tap was taken back, said once where the captain is.
public struct PhoneChangeNotice: Equatable, Sendable, Identifiable {
    public let id = UUID()
    public let words: String
    /// The place whose own line keeps the words on an iPhone on its side (`PhoneIntent.place`).
    public let place: String?
    public init(words: String, place: String? = nil) { self.words = words; self.place = place }
}
