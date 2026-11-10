import Foundation
import Observation

public struct ActivityLine: Decodable, Sendable {
    public let kind: String
    public let taskKey: String?
    public let text: String
    public let at: Double
}

/// Which side a reads-only phone updates (INF-1649): the older one, named in the line under the message box.
public enum PhoneUpdate: Equatable, Sendable {
    case phone, computer

    /// The computer is older when its contract's major is below the phone's; otherwise the phone updates.
    public static func side(phone: String, computer: String?) -> PhoneUpdate {
        func major(_ version: String?) -> Int? { version?.split(separator: ".").first.flatMap { Int($0) } }
        guard let mine = major(phone), let theirs = major(computer) else { return .phone }
        return theirs < mine ? .computer : .phone
    }

    public var words: String {
        switch self {
        case .phone: return "Update Infinitary on this phone to make changes."
        case .computer: return "Update Infinitary on your computer to make changes."
        }
    }
}

/// One card's arrival: a new card, or its author's answer to the captain's reply.
public struct PhoneNotice: Equatable, Sendable {
    public let cardID: String
    public let title: String
    public let reply: Bool
}

/// All product content is in memory. Only the joined computer's public routing facts persist.
@MainActor @Observable public final class ReadOnlySession {
    /// The last authenticated route, separate from saved preference. Never a route merely attempted.
    public private(set) var reachedAddress: String?
    public private(set) var mac: JoinedMac
    /// What the screens show: the home's last snapshot with the captain's pending intents folded over it (INF-2553).
    public private(set) var cards: [PhoneCard] = []
    public private(set) var activity: [ActivityLine] = []
    public private(set) var threads: [String: PhoneJSON] = [:]
    public private(set) var pastCards: [PhoneCard] = []
    public var showCardID: String?
    @ObservationIgnored private var threadRevisions: [String: Int] = [:]
    public private(set) var board: PhoneBoard?
    public private(set) var lastTurn: PhoneLastTurn?
    /// INF-2553: the home's own snapshots, never edited; the shown values above are these with `intents` folded over.
    @ObservationIgnored private var syncedCards: [PhoneCard] = []
    @ObservationIgnored private var syncedThreads: [String: PhoneJSON] = [:]
    @ObservationIgnored private var syncedBoard: PhoneBoard?
    @ObservationIgnored private var syncedTurn: PhoneLastTurn?
    /// The captain's changes this phone already shows and its computer has not yet confirmed, in the order sent.
    public private(set) var ledger = PhoneIntentLedger()
    /// Why a change shown at the tap was taken back: the home refused it, or could not confirm it after reconnecting.
    public var changeNotice: PhoneChangeNotice?
    /// INF-2553, the captain's pick: an iPhone on its side shows no notice pill, so the same words stay on the place's
    /// own line (`PhoneIntent.place`) until that place's next change or the upright pill shows them, never cleared unseen.
    public private(set) var takenBack: [String: String] = [:]
    @ObservationIgnored private var restorers: [Int: @MainActor () -> Void] = [:]
    /// Each welcome counts, so a change whose result was lost is settled by a snapshot read after the next one.
    @ObservationIgnored private var welcomes = 0
    /// The journal's newest push when the last welcome came: the pushes up to it are replayed catch-up.
    @ObservationIgnored private var welcomeSeq = 0
    /// Only the home's busy snapshot or numbered firstmate_state event establishes a conversational turn.
    /// An older home keeps event-only activity; there is still no phone dictation/listening signal.
    public private(set) var firstmateBusy = false
    public private(set) var firstmateObserved = false
    /// INF-3011: the first mate is shortening its conversation (`firstmate_state` folding), heard live only;
    /// `firstmateFoldStarts` counts each start, so one heard starting and ending at once still plays the cinch.
    public private(set) var firstmateFolding = false
    public private(set) var firstmateFoldStarts = 0
    public private(set) var computers: [PhoneComputerPresence] = []
    /// Every welcome settles its initial roster rather than replaying arrivals or packets.
    public private(set) var sceneGeneration = 0
    @ObservationIgnored private var sceneObservations = false
    public private(set) var workRevision = 0
    /// Rises when the home's Secrets change or contact comes back, so this phone reads its approvals again.
    public private(set) var secretsRevision = 0
    public private(set) var access = "read"
    /// The contract the computer's welcome said it speaks, which names the side a reads-only phone updates.
    public private(set) var homeVersion: String?
    public var notice: PhoneNotice?
    /// INF-2631: what this phone's usage events say of it; nil sends none.
    public var usage: PhoneUsage?
    @ObservationIgnored private var usageWaiting = PhoneDiagnosticsQueue()
    /// The computer's welcome named the change that takes a phone's usage events.
    @ObservationIgnored private var homeTakesUsage = false
    /// Offers the stage has drawn while the person could see it, kept for this computer's session only.
    private var seenCards = Set<String>()
    public private(set) var sharedCardSeen = false
    /// The Mac's stage rule: a new card waits for its author's close-out, but a replied-under card stays.
    /// A minimized card leaves the phone's stack and count too (INF-944 item 3).
    public var stack: [PhoneCard] { cards.filter { ($0.awaiting == nil || $0.sentBackAt != nil) && !$0.minimized } }
    public var unreadCards: Int { stack.filter { !hasSeen($0) }.count }
    public var canChange: Bool { contact == "in-reach" && access == "full" }
    public var changeRefusal: String? {
        if contact != "in-reach" { return "Your computer is out of reach. Nothing will be sent later." }
        if access != "full" { return PhoneUpdate.side(phone: PhoneContract.version, computer: homeVersion).words }
        return nil
    }
    /// Where the connection is: what gates reads and changes. The words a person reads are `reach`.
    public private(set) var contact = "reaching" { didSet { if contact != oldValue { settleReach() } } }
    /// INF-2668, the captain's answer "about 20 s": what the reach line and the computer button say. A connection
    /// that was in reach keeps saying In reach while it redials, until the computer has been quiet for `patience`;
    /// only then do the words follow `contact`, so a cell pause passes unnoticed and a dead path is named within
    /// half a minute.
    public private(set) var reach = "reaching"
    public private(set) var heardAt: Date?
    public private(set) var removed = false
    /// How many times the computer came back in reach after the words said Out of reach (INF-589 item 12; INF-2668,
    /// the captain's answer "only after the line said Out of reach"). A redial the words never showed is not a
    /// return, and neither is the ordinary reconnection when the app opens.
    public private(set) var returns = 0
    public var onMacChanged: ((JoinedMac) -> Void)?
    public var onRemoved: (() -> Void)?
    /// The Mac's first mate reacted (a firstmate_emote), heard live; a replay on reconnect is not a reaction now.
    public var onEmote: ((String) -> Void)?
    public var onSceneSignal: ((PhoneSceneSignal) -> Void)?
    @ObservationIgnored private let phone: PhoneIdentity
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var socket: URLSessionWebSocketTask?
    @ObservationIgnored private var transport: PinnedTransport?
    /// The address the current connection was dialed at: the route it reached once it turns In reach.
    @ObservationIgnored private var serving: String?
    @ObservationIgnored private var epoch: String?
    @ObservationIgnored private var sequence = 0
    @ObservationIgnored private var nextID = 0
    @ObservationIgnored private var pending: [Int: String] = [:]
    @ObservationIgnored private var dirty = Set<String>()
    @ObservationIgnored private var ready = Set<String>()
    @ObservationIgnored private var discoveries: [String] = []
    @ObservationIgnored private var refused = 0
    @ObservationIgnored private var leaving = false
    @ObservationIgnored private var leaveContinuation: CheckedContinuation<Void, Error>?
    @ObservationIgnored private var waitingSince: [Int: Date] = [:]
    @ObservationIgnored private var leaveStarted: Date?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var calls: [Int: (Bool, CheckedContinuation<Data, Error>)] = [:]
    @ObservationIgnored private var notified: [String: Bool] = [:]
    @ObservationIgnored private var awaited = Set<String>()
    @ObservationIgnored private var primed = false
    @ObservationIgnored private var missed = false
    /// How many times contact became in-reach, and the card reads waiting for the next time.
    @ObservationIgnored private var reaches = 0
    /// When the computer was last heard, on the clock the deadlines use.
    @ObservationIgnored private var heard: ContinuousClock.Instant?
    /// When the computer last sent a frame or a part of one, which a pong is not.
    @ObservationIgnored private var framed: ContinuousClock.Instant?
    @ObservationIgnored private var reachTimer: Task<Void, Never>?
    /// INF-2668: every first read has answered since the last reload, so a replaying welcome needs none of them.
    @ObservationIgnored private var caughtUp = false
    /// Reads that were still out when a connection ended; a replaying welcome sends them again without waiting on them.
    @ObservationIgnored private var owed = Set<String>()
    @ObservationIgnored private var reachWaiters: [UUID: CheckedContinuation<Void, Error>] = [:]
    /// INF-2773, the captain's pick "keep what they showed, then change once when the catch-up is read": while a
    /// welcome's replay is read, its pushes update the synced copies and this record, and the screens change once.
    @ObservationIgnored private var held: HeldCatchUp?
    private struct HeldCatchUp {
        /// The cards before the replay, so the cards that left while away are read into Past once.
        let cards: [PhoneCard]
        var cardsChanged = false
        /// Board deltas not yet applied: a run on one base folds with one sort (`PhoneBoard.applying(run:)`).
        var deltas: [PhoneBoardDelta] = []
        /// The board's seq once those deltas apply, or -1 with no board held.
        var boardSeq: Int
        var work = false
        var busy: Bool?
        var computers: [PhoneComputerPresence]?
    }
    private var initialReads: [String] {
        [PhoneContract.cards, PhoneContract.feed, PhoneRequest.board.rawValue, PhoneRequest.lastTurn.rawValue]
            + (sceneObservations ? [PhoneRequest.conversationState.rawValue, PhoneRequest.computers.rawValue] : [])
    }

    /// No write is queued or retried. A lost reply is explicitly an unknown outcome.
    public func request<T: Decodable & Sendable>(_ channel: PhoneRequest, args: [Any] = [], as: T.Type = T.self) async throws -> T {
        let answer = try await invoke(channel.rawValue, changes: channel.changes, args: args)
        try Task.checkCancellation()
        do { return try JSONDecoder().decode(T.self, from: answer) }
        catch {
            if channel.changes { throw PhoneError.unconfirmed }
            throw PhoneError.invalidReply
        }
    }

    private func invoke(_ channel: String, changes: Bool, args: [Any]) async throws -> Data {
        guard !Task.isCancelled, contact == "in-reach", let socket, !removed else { throw PhoneError.unavailable }
        if changes, let reason = changeRefusal { throw PhoneError.refused(reason) }
        nextID += 1
        let id = nextID
        let data = try JSONSerialization.data(withJSONObject: ["t": "invoke", "id": id, "channel": channel, "args": args])
        guard data.count <= PhoneContract.maxFrameBytes, let text = String(data: data, encoding: .utf8) else { throw PhoneError.invalidReply }
        let answer: Data = try await withCheckedThrowingContinuation { continuation in
            calls[id] = (changes, continuation); waitingSince[id] = Date()
            Task {
                do { try await socket.send(.string(text)) }
                catch { self.failCall(id) }
            }
        }
        return answer
    }

    public func ask(_ channel: PhoneCardRequest, _ args: [PhoneJSON]) async throws -> PhoneJSON {
        let answer = try await invoke(channel.rawValue, changes: channel.changes, args: args.map { try $0.foundation })
        try Task.checkCancellation()
        do { return try JSONDecoder().decode(PhoneJSON.self, from: answer) }
        catch {
            if channel.changes { throw PhoneError.unconfirmed }
            throw PhoneError.invalidReply
        }
    }

    /// INF-1059: a card's own file (a picture, typeface or part of a recording) waits for contact rather than failing
    /// for good. The stage draws a card from the first cards read while the other first reads are still out, and a
    /// reconnect or a trip to the background fails every ask in flight; such an ask is sent again once in reach.
    public func read(_ channel: PhoneCardRequest, _ args: [PhoneJSON]) async throws -> PhoneJSON {
        guard !channel.changes else { return try await ask(channel, args) }
        var asked = -1
        while true {
            try await inReach(after: asked)
            asked = reaches
            do { return try await ask(channel, args) }
            catch PhoneError.unavailable { continue }
        }
    }

    /// Returns once contact is in-reach on a reach other than `asked`; throws if cancelled or this phone was removed.
    private func inReach(after asked: Int) async throws {
        while contact != "in-reach" || reaches == asked {
            if removed { throw PhoneError.unavailable }
            let id = UUID()
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    if Task.isCancelled { continuation.resume(throwing: CancellationError()) } else { reachWaiters[id] = continuation }
                }
            } onCancel: {
                Task { @MainActor in self.reachWaiters.removeValue(forKey: id)?.resume(throwing: CancellationError()) }
            }
        }
    }

    private func wakeReachWaiters() {
        let waiters = reachWaiters; reachWaiters = [:]
        for continuation in waiters.values { continuation.resume() }
    }

    public func readThread(_ id: String) async throws {
        let revision = threadRevisions[id, default: 0]
        let thread = try await ask(.thread, [.string(id)])
        if revision == threadRevisions[id, default: 0] { syncedThreads[id] = thread; saw(.thread(card: id, thread)) }
    }

    public func readPast(_ id: String) async throws {
        let result = try await ask(.past, [.string(id)])
        guard result != .null else { return }
        let card = try PhoneCard(result)
        pastCards.removeAll { $0.id == id }; pastCards.insert(card, at: 0)
    }

    private func failCall(_ id: Int) {
        waitingSince.removeValue(forKey: id)
        guard let (changes, continuation) = calls.removeValue(forKey: id) else { return }
        continuation.resume(throwing: changes ? PhoneError.unconfirmed : PhoneError.unavailable)
    }
    private func failCalls() { for id in Array(calls.keys) { failCall(id) } }

    private func clearContent() {
        computers = []
        held = nil
        syncedCards = []; activity = []; syncedBoard = nil; syncedTurn = nil; notice = nil; firstmateBusy = false; firstmateObserved = false; firstmateFolding = false
        syncedThreads = [:]; pastCards = []; showCardID = nil; threadRevisions = [:]; seenCards = []
        ledger.clear(); restorers = [:]; changeNotice = nil; takenBack = [:]; refold()
        notified = [:]; awaited = []; primed = false; workRevision += 1
        wakeReachWaiters()
    }

    /// Updated homes own every current-update mark; the set is only the older-home fallback.
    public func hasSeen(_ card: PhoneCard) -> Bool {
        sharedCardSeen ? card.currentUpdateSeen : seenCards.contains(card.offerID ?? card.id)
    }

    /// Called only after the current pane drew in an active, visible, connected scene.
    public func markSeen(_ card: PhoneCard) {
        guard contact == "in-reach", let current = cards.first(where: { $0.id == card.id }),
              current.lifecycleID == card.lifecycleID, current.offerID == card.offerID,
              current.currentUpdateID == card.currentUpdateID else { return }
        if !sharedCardSeen { seenCards.insert(card.offerID ?? card.id) }
        if notice?.cardID == card.id { notice = nil }
        let currentGeneration = generation
        Task {
            guard currentGeneration == generation, contact == "in-reach",
                  let newest = cards.first(where: { $0.id == card.id }),
                  newest.lifecycleID == card.lifecycleID, newest.currentUpdateID == card.currentUpdateID else { return }
            if sharedCardSeen {
                guard let lifecycle = card.lifecycleID, let update = card.currentUpdateID else { return }
                _ = try? await ask(.seenUpdate, [.string(card.id), .string(lifecycle), .string(update)])
            } else if let offer = card.offerID {
                _ = try? await ask(.seen, [.string(card.id), .string(offer)])
            }
        }
    }

    private func observeCards(_ snapshot: [PhoneCard]) {
        let live = snapshot.filter { $0.awaiting == nil || $0.sentBackAt != nil }
        let news = live.filter { !$0.minimized && primed && (notified[$0.id] == nil || (notified[$0.id] == true && $0.awaiting == nil)) }
        // A card that waited on its author after the captain's reply returns as a reply: one the stage
        // kept while it waited, or one that left the stage and was awaiting the answer.
        let reply = news.last.map { notified[$0.id] == true || awaited.contains($0.id) } ?? false
        notified = Dictionary(uniqueKeysWithValues: live.map { ($0.id, $0.awaiting != nil) })
        awaited = Set(snapshot.filter { $0.awaiting == "answer" || ($0.awaiting != nil && awaited.contains($0.id)) }.map(\.id))
        primed = true
        guard let newest = news.last, contact == "in-reach" else { return }
        let current = generation
        Task {
            let enabled = try? await request(.notifications, as: Bool.self)
            guard enabled == true, current == generation, contact == "in-reach" else { return }
            // A new card the stage drew while this question was out is already read.
            if let current = cards.first(where: { $0.id == newest.id }), (sharedCardSeen || !reply) && hasSeen(current) { return }
            notice = PhoneNotice(cardID: newest.id, title: newest.title, reply: reply)
        }
    }

    // MARK: INF-2553, the captain's direction B: every tap shows at once and settles on the home's evidence.

    /// Sends a card change and shows it at once. A refusal takes it back with the home's words in `changeNotice` and
    /// runs `restore`; a lost result keeps it shown until a snapshot read after reconnecting settles it. Nothing is
    /// queued or sent again.
    @discardableResult
    public func change(_ kind: PhoneIntent.Kind, _ channel: PhoneCardRequest, _ args: [PhoneJSON],
                       restore: (@MainActor () -> Void)? = nil) async throws -> PhoneJSON {
        let id = begin(kind, restore)
        do {
            let result = try await ask(channel, args)
            if let refusal = result["refusal"].text { refuse(id, refusal); throw PhoneRequestError(refusal) }
            accept(id)
            if channel == .act { noteUsage(.cardAnswered) }
            return result
        } catch { settle(id, after: error); throw error }
    }

    /// The same for a message, a start, an interrupt or a steer, each answered as accepted or not.
    public func change(_ kind: PhoneIntent.Kind, _ channel: PhoneRequest, args: [Any],
                       restore: (@MainActor () -> Void)? = nil) async throws {
        let id = begin(kind, restore)
        do {
            let answer: PhoneAnswer = try await request(channel, args: args)
            if !answer.ok {
                let words = answer.text ?? "Your computer could not make this change."
                refuse(id, words); throw PhoneError.refused(words)
            }
            accept(id)
            if channel == .converse { noteUsage(.messageSent) }
        } catch { settle(id, after: error); throw error }
    }

    /// A task record's own read, which also settles the intents it speaks about; the record draws `shown(_:)` of it.
    public func readDetail(_ id: String) async throws -> PhoneTask {
        let task: PhoneTask = try await request(.detail, args: [id])
        saw(.task(task))
        return task
    }

    public func readCrew(_ id: String) async throws -> PhoneCrew {
        let crew: PhoneCrew = try await request(.crew, args: [id])
        saw(.crew(crew))
        return crew
    }

    /// A record's task or transcript as the screens show it, with the pending intents drawn over it.
    public func shown(_ task: PhoneTask) -> PhoneTask { PhoneIntentFold.task(task, ledger.intents) }
    public func shown(_ crew: PhoneCrew) -> PhoneCrew { PhoneIntentFold.crew(crew, ledger.intents) }

    /// A message to the first mate is on its way: the last turn shows it, marked sending.
    public var messageSending: Bool { ledger.intents.contains { if case .send = $0.kind { true } else { false } } }

    /// How long an accepted change may wait for the snapshot that shows it.
    static let acceptedWait: Duration = .seconds(15)

    private func begin(_ kind: PhoneIntent.Kind, _ restore: (@MainActor () -> Void)?) -> Int {
        let id = ledger.add(kind)
        if let restore { restorers[id] = restore }
        changeNotice = nil
        if let place = ledger.intent(id)?.place { takenBack[place] = nil }
        refold()
        return id
    }

    /// The home accepted it. The snapshot that holds the change retires it; one that never comes lets it go quietly.
    private func accept(_ id: Int) {
        ledger.accept(id)
        guard ledger.intent(id)?.state == .accepted else { restorers.removeValue(forKey: id); return }
        // Ids are never reused, so a reconnect in between leaves the wait to end as it would have.
        Task { [weak self] in
            try? await Task.sleep(for: Self.acceptedWait)
            guard let self, self.ledger.intent(id)?.state == .accepted else { return }
            self.ledger.drop(id); self.restorers.removeValue(forKey: id); self.refold()
        }
    }

    private func settle(_ id: Int, after error: Error) {
        guard ledger.intent(id)?.state == .sent else { return }
        switch error {
        case PhoneError.unconfirmed, is CancellationError: ledger.lose(id, welcome: welcomes)
        case PhoneError.unavailable: refuse(id, changeRefusal ?? error.localizedDescription)
        default: refuse(id, error.localizedDescription)
        }
    }

    private func refuse(_ id: Int, _ words: String) {
        guard let intent = ledger.drop(id) else { return }
        restorers.removeValue(forKey: id)?()
        say(words, at: intent)
        refold()
    }

    private func say(_ words: String, at intent: PhoneIntent) {
        changeNotice = PhoneChangeNotice(words: words, place: intent.place)
        if let place = intent.place { takenBack[place] = words }
    }

    /// The upright pill showed the notice, so its place's line has nothing left unseen to say.
    public func noticeShown(_ change: PhoneChangeNotice) {
        guard changeNotice == change, let place = change.place else { return }
        takenBack[place] = nil
    }

    /// A snapshot from the home: retire what it holds, void what changed under it, and take back with today's
    /// unconfirmed words what it contradicts after reconnecting.
    /// A held snapshot (`show` false) is still checked against every pending change, and shows with the catch-up.
    private func saw(_ snapshot: PhoneSnapshot, replayed: Bool = false, show: Bool = true) {
        if !show && ledger.intents.isEmpty { return }
        let before = ledger.intents.map(\.id)
        // A push the welcome replays can predate a change whose result was lost, so it settles only what it holds.
        let contradicted = ledger.saw(snapshot, welcome: replayed ? Int.min : welcomes)
        for intent in contradicted {
            restorers.removeValue(forKey: intent.id)?()
            say(PhoneError.unconfirmed.localizedDescription, at: intent)
        }
        let after = Set(ledger.intents.map(\.id))
        for id in before where !after.contains(id) { restorers.removeValue(forKey: id) }
        if !show { return }
        if after.count != before.count { refold(); return }
        switch snapshot {
        case .cards: cards = PhoneIntentFold.cards(syncedCards, ledger.intents)
        case .thread: threads = PhoneIntentFold.threads(syncedThreads, ledger.intents)
        case .board: board = PhoneIntentFold.board(syncedBoard, ledger.intents)
        case .turn: lastTurn = PhoneIntentFold.lastTurn(syncedTurn, ledger.intents)
        case .task, .crew: break
        }
    }

    /// Applies the held board deltas with one sort. A change waiting on the computer has already seen each one.
    private func foldHeldBoard() {
        guard let deltas = held?.deltas, !deltas.isEmpty else { return }
        held?.deltas = []
        guard let board = syncedBoard, let next = board.applying(run: deltas) else { return }
        syncedBoard = next
        saw(.board(next), replayed: true, show: false)
    }

    /// INF-2773: the one change a catch-up makes on the screens, at its last push or when the connection ends first.
    private func showHeld() {
        guard held != nil else { return }
        foldHeldBoard()
        guard let fold = held else { return }
        held = nil
        if fold.cardsChanged {
            let departed = fold.cards.filter { old in !syncedCards.contains { $0.id == old.id } }.map(\.id)
            for id in departed { Task { try? await self.readPast(id) } }
            observeCards(syncedCards)
        }
        refold()
        if fold.work { workRevision += 1 }
        if let busy = fold.busy { firstmateBusy = busy; firstmateObserved = true }
        if let computers = fold.computers { self.computers = computers }
    }

    private func refold() {
        cards = PhoneIntentFold.cards(syncedCards, ledger.intents)
        threads = PhoneIntentFold.threads(syncedThreads, ledger.intents)
        board = PhoneIntentFold.board(syncedBoard, ledger.intents)
        lastTurn = PhoneIntentFold.lastTurn(syncedTurn, ledger.intents)
    }

    public init(mac: JoinedMac, phone: PhoneIdentity) { self.mac = mac; self.phone = phone }

    /// INF-2668: the captain's patience, two missed heartbeats. In reach may stay this long on a quiet connection.
    static let patience: Duration = .seconds(20)

    /// The words follow `contact`, except that In reach stays until the computer was last heard `patience` ago.
    private func settleReach() {
        reachTimer?.cancel(); reachTimer = nil
        if reach == "in-reach", contact != "in-reach", contact != "removed", let heard {
            let due = heard + Self.patience
            if ContinuousClock.now < due {
                reachTimer = Task { [weak self] in
                    try? await Task.sleep(until: due)
                    guard !Task.isCancelled else { return }
                    self?.settleReach()
                }
                return
            }
        }
        guard reach != contact else { return }
        reach = contact
        // Only Out of reach said while the phone keeps trying makes the next In reach a return.
        if reach == "lost", loop != nil { missed = true }
    }

    /// Anything from the computer: a frame or a pong.
    private func hear() {
        heardAt = Date(); heard = .now
        if doubted != nil { doubted = nil; replacing?.cancel(); replacing = nil }
    }

    /// INF-2157: the app's reopen, and a change of network, start the loop or, while it runs, look again at once:
    /// a kept connection must answer a ping within `reopenAnswer`, and a wait between rounds ends now.
    public func start() {
        guard !removed else { return }
        guard loop == nil else { lookAgain(); return }
        generation += 1
        let current = generation
        contact = "reaching"
        loop = Task { [weak self] in await self?.run(generation: current) }
    }

    /// INF-2157, INF-2668: the least time a kept connection has to answer the reopen's ping; a slower measured round
    /// trip gives it `roundTrips` of those instead. Unanswered, it is doubted, never cut: a replacement is dialed and
    /// the kept connection is cut only once the replacement opened, unless the kept one is heard first.
    static let reopenAnswer: Duration = .seconds(5)
    static let roundTrips = 4
    /// INF-2668: how long the phone waits on an answer before the silence counts. A ping's pong waits behind an answer
    /// on its way, so while a greeting or read is out the phone gives it twice `patience`.
    static let answerWait: Duration = .seconds(40)
    /// How often a quiet connection is pinged: twice in `patience`.
    static let pingEvery: Duration = .seconds(10)
    /// INF-2668: the longest wait between failed rounds, so a computer that comes back is found within 15 s.
    static let longestWait: Double = 14
    /// INF-2157 (RFC 8305's attempt delay): the private network's lead over the other addresses, so it wins when both answer.
    static let privateLead: Duration = .milliseconds(250)
    /// How long a round's addresses have to open before the round fails, as the watchdog allowed one address before.
    static let dialLimit: Duration = .seconds(10)

    /// Why the last connection that opened ended, for the app-hosted tests.
    enum Cut: Equatable { case unanswered, quiet, failed }
    @ObservationIgnored private(set) var lastCut: Cut?
    /// When the wait between rounds is due to end, while the loop waits.
    @ObservationIgnored private(set) var pausedUntil: ContinuousClock.Instant?
    @ObservationIgnored private var pause: CheckedContinuation<Void, Never>?
    @ObservationIgnored private var pauseTimer: Task<Void, Never>?
    @ObservationIgnored private var checking: URLSessionWebSocketTask?
    /// The last ping's round trip, which scales the reopen's wait.
    @ObservationIgnored private var roundTrip: Duration = .zero
    /// The kept connection a reopen's ping found unanswered, and the dial of its replacement.
    @ObservationIgnored private var doubted: URLSessionWebSocketTask?
    @ObservationIgnored private var replacing: Task<Void, Never>?
    @ObservationIgnored private var replacement: Dialed?
    @ObservationIgnored private var cutting: Cut?
    /// A reopen or a change of network ended the wait, so the next round says it is reaching again.
    @ObservationIgnored private var woken = false

    private func lookAgain() {
        if pause != nil { woken = true; contact = "reaching" }
        endPause()
        guard contact == "in-reach", let socket, checking !== socket, doubted == nil else { return }
        checking = socket
        let sent = ContinuousClock.now
        ping(socket)
        let wait = max(Self.reopenAnswer, roundTrip * Self.roundTrips)
        Task { [weak self, weak socket] in
            var since = sent
            while true {
                try? await Task.sleep(until: since + wait)
                guard let self, let socket, self.socket === socket, self.checking === socket else { return }
                // A connection still receiving is answering, however slowly, so the check goes on from what it last
                // sent; a frame already on its way when the ping left proves nothing about the path after it.
                if let heard = self.heard, heard > since { since = heard; continue }
                self.checking = nil
                self.doubt(socket)
                return
            }
        }
    }

    /// Pings and measures the round trip; a failed ping cuts the connection.
    private func ping(_ socket: URLSessionWebSocketTask) {
        let sent = ContinuousClock.now
        socket.sendPing { [weak self, weak socket] error in
            Task { @MainActor in
                guard let self, let socket, self.socket === socket else { return }
                if self.checking === socket { self.checking = nil }
                if error != nil { self.cut(socket, .failed) } else { self.roundTrip = .now - sent; self.hear() }
            }
        }
    }

    /// INF-2668: keeps a doubted connection while its replacement dials, and cuts it only once the replacement
    /// opened. Hearing the kept connection first ends the doubt and the dial.
    private func doubt(_ socket: URLSessionWebSocketTask) {
        doubted = socket
        let current = generation
        replacing = Task { [weak self] in
            guard let self else { return }
            let dialed = await self.dial(PhoneAddresses.preferred(self.mac.addresses + self.discoveries), generation: current)
            guard let dialed else {
                // No replacement opened: the kept connection stays, under the watchdog, and a later reopen checks it again.
                if !Task.isCancelled, self.doubted === socket { self.doubted = nil; self.replacing = nil }
                return
            }
            guard !Task.isCancelled, self.alive(current), self.doubted === socket, self.socket === socket else {
                dialed.transport.close(); return
            }
            self.replacing = nil; self.doubted = nil
            self.replacement = dialed
            self.cut(socket, .unanswered)
        }
    }

    private func waitBetweenRounds(_ wait: Duration) async {
        let until = ContinuousClock.now + wait
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            pause = continuation; pausedUntil = until
            pauseTimer = Task { [weak self] in
                try? await Task.sleep(until: until)
                self?.endPause()
            }
        }
    }

    private func endPause() {
        pauseTimer?.cancel(); pauseTimer = nil; pausedUntil = nil
        let continuation = pause; pause = nil
        continuation?.resume()
    }

    public func stop() {
        showHeld()
        generation += 1
        loop?.cancel(); loop = nil
        endPause()
        replacing?.cancel(); replacing = nil; doubted = nil
        replacement?.transport.close(); replacement = nil
        finishLeave(PhoneError.unavailable)
        failCalls(); notice = nil; access = "read"; firstmateBusy = false; firstmateObserved = false; firstmateFolding = false
        socket?.cancel(with: .goingAway, reason: nil); socket = nil; serving = nil
        transport?.close(); transport = nil
        // A deliberate close has nothing to be patient about: the words follow at once, so a reopen reads Reaching
        // until its dial is in reach rather than an In reach no connection backs.
        heard = nil
        contact = "lost"
        settleReach()
    }

    public func found(addresses: [String]) {
        discoveries = Array(Set(addresses)).sorted()
    }

    public func leave() async throws {
        guard contact == "in-reach", let socket, !leaving else { throw PhoneError.unavailable }
        leaving = true; leaveStarted = Date()
        defer { leaving = false; leaveStarted = nil }
        try await withCheckedThrowingContinuation { continuation in
            leaveContinuation = continuation
            Task {
                do { try await send(["t": "leave"], on: socket) }
                catch {
                    if self.socket === socket { finishLeave(error) }
                }
            }
        }
    }

    private func cut(_ socket: URLSessionWebSocketTask, _ why: Cut) {
        guard self.socket === socket else { return }
        // The first reason holds: cancelling fails every ping still out, which is not why it was cut.
        if cutting == nil { cutting = why }
        socket.cancel(with: .goingAway, reason: nil)
        transport?.close()
    }

    private func finishLeave(_ error: Error? = nil) {
        let continuation = leaveContinuation; leaveContinuation = nil
        if let error { continuation?.resume(throwing: error) } else { continuation?.resume() }
    }

    private func alive(_ current: Int) -> Bool { !Task.isCancelled && !removed && current == generation }

    /// Each round dials every saved and nearby address together, keeps the first whose WebSocket opens and greets
    /// only that one. "Out of reach" is said once a whole round failed; until then the words say it is reaching.
    private func run(generation current: Int) async {
        var attempt = 0
        while alive(current) {
            failCalls()
            pending.removeAll(); waitingSince.removeAll(); dirty.removeAll(); ready.removeAll()
            access = "read"; firstmateBusy = false; firstmateObserved = false; firstmateFolding = false
            // Out of reach stays while later rounds try again on their own; a reopen says it is reaching.
            if attempt == 0 || woken { contact = "reaching" }
            woken = false
            // A replacement that opened while its doubted connection was cut is served without dialing again.
            var dialed = replacement; replacement = nil
            if dialed == nil { dialed = await dial(PhoneAddresses.preferred(mac.addresses + discoveries), generation: current) }
            guard alive(current) else { dialed?.transport.close(); return }
            if let dialed, await serve(dialed, generation: current) {
                attempt = 0
                continue
            }
            guard alive(current) else { return }
            contact = "lost"
            finishLeave(PhoneError.unavailable)
            attempt += 1
            await waitBetweenRounds(Self.wait(after: attempt))
        }
    }

    /// INF-2668: 2, 4, 8 s and so on between failed rounds, each up to a quarter longer at random, never past
    /// `longestWait`. A reopen or a change of network still ends the wait at once.
    static func wait(after attempt: Int, random: Double = Double.random(in: 1...1.25)) -> Duration {
        let doubling = pow(2, Double(min(max(attempt, 1), 5)))
        return .milliseconds(Int(min(longestWait, doubling * random) * 1000))
    }

    private struct Dialed: @unchecked Sendable { let address: String; let transport: PinnedTransport; let socket: URLSessionWebSocketTask }
    private enum Dial: Sendable { case opened(Dialed), failed(status: Int?), timedOut }
    private struct Attempt: Sendable { let address: String; let transport: PinnedTransport; let delay: Duration }

    private nonisolated static func open(_ attempt: Attempt) async -> Dial {
        if attempt.delay > .zero { try? await Task.sleep(for: attempt.delay) }
        if Task.isCancelled { attempt.transport.close(); return .failed(status: nil) }
        guard let socket = try? attempt.transport.socket(at: attempt.address) else {
            attempt.transport.close(); return .failed(status: nil)
        }
        do {
            try await attempt.transport.opened()
            return .opened(Dialed(address: attempt.address, transport: attempt.transport, socket: socket))
        } catch {
            return .failed(status: (socket.response as? HTTPURLResponse)?.statusCode)
        }
    }

    /// The private network dials first and the rest `privateLead` later; nothing else orders the addresses.
    private func dial(_ addresses: [String], generation current: Int) async -> Dialed? {
        let lead = addresses.contains(where: PhoneAddresses.isPrivate) ? Self.privateLead : .zero
        let attempts = addresses.map { address in
            Attempt(address: address, transport: PinnedTransport(pin: mac.pin, phone: phone, purpose: .connection),
                    delay: PhoneAddresses.isPrivate(address) ? .zero : lead)
        }
        guard !attempts.isEmpty else { return nil }
        var kept: PinnedTransport?
        defer { for attempt in attempts where attempt.transport !== kept { attempt.transport.close() } }
        return await withTaskGroup(of: Dial.self) { group in
            for attempt in attempts { group.addTask { await Self.open(attempt) } }
            group.addTask { try? await Task.sleep(for: Self.dialLimit); return .timedOut }
            var left = attempts.count
            for await outcome in group {
                guard alive(current) else { break }
                switch outcome {
                case .opened(let dialed):
                    group.cancelAll()
                    kept = dialed.transport
                    return dialed
                case .failed(let status):
                    if status == 401 { refused += 1 } else if status != nil { refused = 0 }
                    if refused >= 2 {
                        group.cancelAll()
                        removed = true; clearContent(); contact = "removed"
                        finishLeave(); onRemoved?()
                        return nil
                    }
                    left -= 1
                    if left == 0 { group.cancelAll(); return nil }
                case .timedOut:
                    group.cancelAll()
                    return nil
                }
            }
            group.cancelAll()
            return nil
        }
    }

    /// Greets the opened socket and reads it until it ends; true when the computer was in reach on it.
    private func serve(_ dialed: Dialed, generation current: Int) async -> Bool {
        let (address, transport, socket) = (dialed.address, dialed.transport, dialed.socket)
        self.socket = socket; self.transport = transport; serving = address; cutting = nil
        var reached = false
        var hello: [String: Any] = ["t": "hello", "protocolVersion": PhoneContract.version,
            "as": "view", "viewFloor": PhoneContract.viewFloor, "system": "ios", "spellings": ["inf"], "appVersion": "0.1.0",
            "changes": [PhoneContract.frameParts]]
        if let epoch { hello["cursor"] = ["epoch": epoch, "seq": sequence] }
        let opened = ContinuousClock.now
        // INF-2668: the connection is cut for silence alone, never because an answer is slow. Quiet for `patience`
        // while nothing is awaited, or for `answerWait` while a greeting or read is out, it is cut and redialed.
        let watchdog = Task { [weak self, weak socket] in
            var pinged = ContinuousClock.now
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self, let socket, self.socket === socket else { return }
                let leaveWait = self.leaveStarted.map { Date().timeIntervalSince($0) > 15 } ?? false
                if leaveWait { self.cut(socket, .quiet); return }
                let awaiting = self.contact != "in-reach" || !self.waitingSince.isEmpty
                let since = max(opened, self.heard ?? opened)
                if ContinuousClock.now - since > (awaiting ? Self.answerWait : Self.patience) {
                    self.cut(socket, .quiet); return
                }
                // A computer that answers pings but not a read for `answerWait`, while it sends nothing else, is stuck.
                let oldest = self.waitingSince.values.min().map { Date().timeIntervalSince($0) } ?? 0
                if oldest > Double(Self.answerWait.components.seconds),
                   ContinuousClock.now - max(opened, self.framed ?? opened) > Self.answerWait {
                    self.cut(socket, .quiet); return
                }
                if ContinuousClock.now - pinged >= Self.pingEvery {
                    pinged = .now
                    self.ping(socket)
                }
            }
        }
        defer { watchdog.cancel() }
        var parts = PhoneParts()
        do {
            try await send(hello, on: socket)
            while !Task.isCancelled {
                let message = try await socket.receive()
                guard current == generation, !Task.isCancelled else { break }
                guard case .string(let text) = message else { throw PhoneError.invalidReply }
                // INF-2832: each part of a long frame is the computer sending, heard as it arrives; the frame is read
                // once whole, so an answer still arriving is never cut as a stuck one.
                guard let whole = try parts.read(text) else { hear(); framed = .now; continue }
                // INF-2566: the frame is parsed and its payload decoded off the main thread, then read here in order.
                let frame = try await PhoneFrame.decode(whole, reads: pending)
                guard current == generation, !Task.isCancelled else { break }
                try await receive(frame, on: socket)
                guard current == generation, !Task.isCancelled else { break }
                if contact == "in-reach" { refused = 0; reached = true }
            }
        } catch {
            guard current == generation, !Task.isCancelled else {
                if current == generation { showHeld() }
                transport.close(); return reached
            }
            lastCut = cutting ?? .failed; cutting = nil
            if socket.closeCode.rawValue == 4401 {
                removed = true; clearContent()
                contact = "removed"; finishLeave(); onRemoved?()
            } else {
                finishLeave(PhoneError.unavailable)
            }
        }
        if current == generation { showHeld() }
        owed.formUnion(pending.values)
        failCalls(); firstmateBusy = false; firstmateObserved = false; firstmateFolding = false
        transport.close()
        guard current == generation else { return reached }
        self.socket = nil; self.transport = nil; serving = nil; checking = nil
        if doubted === socket { doubted = nil; replacing?.cancel(); replacing = nil }
        return reached
    }

    private func receive(_ decoded: PhoneFrame, on socket: URLSessionWebSocketTask) async throws {
        let frame = decoded.frame
        guard let kind = frame["t"] as? String else { throw PhoneError.invalidReply }
        hear(); framed = .now
        // A held catch-up covers only the run of replayed pushes; anything else shows it first.
        if kind != "push" { showHeld() }
        switch kind {
        case "welcome":
            guard let epoch = frame["epoch"] as? String, !epoch.isEmpty,
                  let seq = frame["seq"] as? Int, seq >= 0,
                  let catchUp = frame["catchUp"] as? String, ["replay", "reload"].contains(catchUp)
            else { throw PhoneError.invalidReply }
            if catchUp == "reload" { self.sequence = seq; primed = false; notified = [:]; awaited = []; caughtUp = false; owed = [] }
            access = frame["access"] as? String == "full" ? "full" : "read"
            homeVersion = frame["protocolVersion"] as? String
            self.epoch = epoch
            welcomeSeq = seq
            if catchUp == "replay", seq > sequence {
                held = HeldCatchUp(cards: syncedCards, boardSeq: syncedBoard?.seq ?? -1)
            }
            welcomes += 1
            refused = 0
            if let name = frame["name"] as? String, !name.isEmpty {
                mac.name = name; onMacChanged?(mac)
            }
            if let alternatives = frame["addresses"] as? [String] {
                // Metadata belongs to this pinned, authenticated socket, never to discovery.
                // Keep old fallbacks (and the working route); refresh never restarts the socket.
                let refreshed = Array(PhoneAddresses.preferred(alternatives + mac.addresses).prefix(25))
                if !refreshed.isEmpty && refreshed != mac.addresses {
                    mac.addresses = refreshed; onMacChanged?(mac)
                }
            }
            // A major folds every earlier change name in, so a home from sceneObservationsSince on has them without naming them.
            let homeMajor = ((frame["protocolVersion"] as? String)?.split(separator: ".").first).flatMap { Int($0) } ?? 0
            sharedCardSeen = homeMajor >= PhoneContract.cardCurrentUpdateSeenSince
                || (frame["changes"] as? [String] ?? []).contains(PhoneContract.cardCurrentUpdateSeen)
            sceneObservations = homeMajor >= PhoneContract.sceneObservationsSince
                || (frame["changes"] as? [String] ?? []).contains(PhoneContract.sceneObservations)
            homeTakesUsage = homeMajor >= PhoneContract.phoneDiagnosticsSince
                || (frame["changes"] as? [String] ?? []).contains(PhoneDiagnosticEvent.change)
            if !sceneObservations { computers = [] }
            sceneGeneration += 1
            contact = "reaching"
            // INF-2668: a replay brings every push the phone missed, so what it holds is current once the replay is
            // read; only the scene's two small reads, and reads a cut left unanswered, go again, unawaited. A change
            // whose result was lost still waits on the full reads that settle it.
            let lost = ledger.intents.contains { if case .unknown = $0.state { true } else { false } }
            if catchUp == "replay", caughtUp, !lost {
                let again = owed.union(sceneObservations ? [PhoneRequest.conversationState.rawValue, PhoneRequest.computers.rawValue] : [])
                ready.formUnion(initialReads); markReady(PhoneContract.cards)
                for channel in again.sorted() {
                    guard self.socket === socket, !Task.isCancelled else { return }
                    try await refresh(channel, on: socket)
                }
                return
            }
            for channel in initialReads {
                guard self.socket === socket, !Task.isCancelled else { return }
                try await refresh(channel, on: socket)
            }
        case "push":
            guard epoch != nil, let seq = frame["seq"] as? Int else { throw PhoneError.invalidReply }
            if seq <= sequence { return }
            guard seq == sequence + 1 else { epoch = nil; throw PhoneError.invalidReply }
            sequence = seq
            let replayed = seq <= welcomeSeq
            if !replayed { showHeld() }
            let holding = held != nil
            defer { if seq >= welcomeSeq { showHeld() } }
            if holding, frame["channel"] as? String == "inf:cards" {
                guard frame["payload"] != nil else { throw PhoneError.invalidReply }
                syncedCards = try decoded.cards(); held?.cardsChanged = true
                saw(.cards(syncedCards), replayed: true, show: false)
            } else if frame["channel"] as? String == "inf:cards" {
                guard frame["payload"] != nil else { throw PhoneError.invalidReply }
                let updated = try decoded.cards()
                let departed = syncedCards.filter { old in !updated.contains { $0.id == old.id } }.map(\.id)
                syncedCards = updated
                for id in departed { Task { try? await self.readPast(id) } }
                observeCards(syncedCards)
                saw(.cards(updated), replayed: replayed)
                // A replayed push can predate a lost change, so the cards read sent at the welcome still settles it.
                if !replayed { supersede(PhoneContract.cards) }
            }
            if frame["channel"] as? String == "inf:computers:presence", frame["payload"] != nil, sceneObservations {
                if holding { held?.computers = try decoded.computers() } else { computers = try decoded.computers() }
                supersede(PhoneRequest.computers.rawValue)
            }
            if holding, frame["channel"] as? String == "inf:tasks", frame["payload"] != nil {
                syncedBoard = try decoded.board()
                held?.deltas = []; held?.boardSeq = syncedBoard!.seq; held?.work = true
                saw(.board(syncedBoard!), replayed: true, show: false)
            } else if frame["channel"] as? String == "inf:tasks", frame["payload"] != nil {
                syncedBoard = try decoded.board()
                saw(.board(syncedBoard!), replayed: replayed)
                if !replayed { supersede(PhoneRequest.board.rawValue) }
                workRevision += 1
            }
            // A delta folds onto the board held, as on the Mac (INF-1854); a full read is the contract's resync path
            // for a delta with no base to apply to.
            if holding, let base = held?.boardSeq, frame["channel"] as? String == "inf:tasks:delta", frame["payload"] != nil {
                let delta = try decoded.delta()
                if delta.seq <= base {
                    // Older than the board held, as `applying` passes it over.
                } else if syncedBoard != nil, delta.baseSeq == base {
                    held?.deltas.append(delta); held?.boardSeq = delta.seq; held?.work = true
                    // A change waiting on the computer sees every board, as it does one push at a time.
                    if !ledger.intents.isEmpty { foldHeldBoard() }
                } else {
                    foldHeldBoard()
                    try await refresh(PhoneRequest.board.rawValue, on: socket)
                }
            } else if frame["channel"] as? String == "inf:tasks:delta", frame["payload"] != nil {
                let delta = try decoded.delta()
                if let held = syncedBoard, let next = held.applying(delta) {
                    if next.seq != held.seq { syncedBoard = next; saw(.board(next), replayed: replayed); if !replayed { supersede(PhoneRequest.board.rawValue) }; workRevision += 1 }
                } else {
                    try await refresh(PhoneRequest.board.rawValue, on: socket)
                }
            }
            if frame["channel"] as? String == "inf:event", let event = frame["payload"] as? [String: Any], let type = event["type"] as? String {
                if type == "firstmate_state", let busy = event["busy"] as? Bool {
                    if holding { held?.busy = busy } else { firstmateBusy = busy; firstmateObserved = true }
                    // A shortening replayed while reconnecting is over by now, so only a live one plays.
                    let folding = !replayed && event["folding"] as? Bool == true
                    if folding && !firstmateFolding { firstmateFoldStarts += 1 }
                    firstmateFolding = folding
                    if sceneObservations { supersede(PhoneRequest.conversationState.rawValue) }
                }
                // A reaction replayed while reconnecting is not played (INF-2773: a caught-up replay is in reach).
                if contact == "in-reach", !replayed, let signal = PhoneSceneSignal.read(event) { onSceneSignal?(signal) }
                if type == "firstmate_emote", contact == "in-reach", !replayed, let emote = event["emote"] as? String { onEmote?(emote) }
                if type == "user_turn" || type == "firstmate_reply" {
                    try await refresh(PhoneRequest.lastTurn.rawValue, on: socket)
                }
                if ["task_changed", "task_event", "turn_end", "tool_execution_end"].contains(type) {
                    if holding { held?.work = true } else { workRevision += 1 }
                }
            }
            if frame["channel"] as? String == "inf:secrets:changed" { secretsRevision += 1 }
            if frame["channel"] as? String == "inf:cards:thread", let payload = frame["payload"] {
                let thread = try PhoneJSON.read(payload)
                if let id = thread["cardId"].text {
                    threadRevisions[id, default: 0] += 1
                    syncedThreads[id] = thread
                    saw(.thread(card: id, thread), replayed: replayed, show: !holding)
                }
            }
            if frame["channel"] as? String == "inf:event", let event = frame["payload"] as? [String: Any],
               let id = event["cardId"] as? String {
                if event["type"] as? String == "past_card_shown" {
                    Task { try? await self.readPast(id); self.showCardID = id }
                } else if event["type"] as? String == "open_card_shown" { showCardID = id }
            }
            // The Mac still owns feed wording. Only types that can change it cause a read.
            if frame["channel"] as? String == "inf:event",
               let event = frame["payload"] as? [String: Any], let type = event["type"] as? String,
               FeedChange(rawValue: type) != nil,
               type != "task_event" || event["feed"] as? Bool == true {
                try await refresh(PhoneContract.feed, on: socket)
            }
        case "result":
            guard let id = frame["id"] as? Int else { throw PhoneError.invalidReply }
            if let (_, continuation) = calls.removeValue(forKey: id) {
                waitingSince.removeValue(forKey: id)
                if frame["ok"] as? Bool == true, frame["value"] != nil {
                    if let answer = decoded.answer { continuation.resume(returning: answer) }
                    else { continuation.resume(throwing: PhoneError.invalidReply) }
                } else {
                    continuation.resume(throwing: PhoneError.refused((frame["error"] as? [String: Any])?["message"] as? String ?? frame["error"] as? String ?? "Your computer refused this request."))
                }
                return
            }
            guard let channel = pending.removeValue(forKey: id) else { return }
            waitingSince.removeValue(forKey: id)
            guard frame["ok"] as? Bool == true, frame["value"] != nil else {
                throw PhoneError.invalidReply
            }
            switch channel {
            case PhoneContract.cards:
                syncedCards = try decoded.cards(); observeCards(syncedCards); saw(.cards(syncedCards))
            case PhoneContract.feed: activity = try decoded.feed()
            case PhoneRequest.board.rawValue:
                syncedBoard = try decoded.board(); saw(.board(syncedBoard!)); workRevision += 1
            case PhoneRequest.conversationState.rawValue:
                firstmateBusy = try decoded.conversation().busy
                firstmateObserved = true
            case PhoneRequest.computers.rawValue: computers = try decoded.computers()
            case PhoneRequest.lastTurn.rawValue:
                syncedTurn = try decoded.lastTurn(); saw(.turn(syncedTurn))
            default: break
            }
            markReady(channel)
            if dirty.remove(channel) != nil { try await refresh(channel, on: socket) }
        default: break // Later envelope fields and frame kinds do not widen what this client sends.
        }
    }

    private func supersede(_ channel: String) {
        if let id = pending.first(where: { $0.value == channel })?.key {
            pending.removeValue(forKey: id); waitingSince.removeValue(forKey: id)
        }
        markReady(channel)
    }

    private func markReady(_ channel: String) {
        ready.insert(channel); owed.remove(channel)
        guard initialReads.allSatisfy({ ready.contains($0) }) else { return }
        caughtUp = true
        let reached = contact != "in-reach"
        if reached { reachRoute() }
        contact = "in-reach"
        if missed { missed = false; returns += 1 }
        if reached { reaches += 1; secretsRevision += 1; wakeReachWaiters(); handUsage() }
    }

    /// INF-2773: the route and its preference are worked out once per connection, in the step that turns it In reach,
    /// so nothing reads In reach beside the last connection's route while the catch-up's reads are still being sent.
    private func reachRoute() {
        guard let address = serving else { return }
        if reachedAddress != address { reachedAddress = address }
        let preferred = Array(PhoneAddresses.preferred(mac.addresses + [address]).prefix(25))
        if mac.addresses != preferred {
            mac.addresses = preferred
            onMacChanged?(mac)
        }
    }

    // MARK: INF-2631: the phone's usage events go to its computer, which alone decides whether any leaves.

    /// Notes one usage event: it waits in memory until the computer is in reach, then is handed over once.
    public func noteUsage(_ event: PhoneDiagnosticEvent) {
        guard usage != nil, !removed else { return }
        usageWaiting.note(event, at: Date())
        handUsage()
    }

    /// Hands every waiting event to a computer in reach. One that does not take them, or that this phone may only read
    /// from, is sent nothing and keeps nothing. A lost answer is never sent again.
    private func handUsage() {
        guard let usage, contact == "in-reach", socket != nil else { return }
        guard homeTakesUsage, access == "full" else { usageWaiting.drop(); return }
        for argument in usageWaiting.handOver(as: usage) {
            Task { _ = try? await self.invoke(PhoneDiagnosticEvent.request, changes: true, args: [argument]) }
        }
    }

    private func refresh(_ channel: String, on socket: URLSessionWebSocketTask) async throws {
        if pending.values.contains(channel) { dirty.insert(channel); return }
        nextID += 1; pending[nextID] = channel; waitingSince[nextID] = Date()
        try await send(["t": "invoke", "id": nextID, "channel": channel, "args": []], on: socket)
    }

    private func send(_ object: [String: Any], on socket: URLSessionWebSocketTask) async throws {
        let data = try JSONSerialization.data(withJSONObject: object)
        guard let text = String(data: data, encoding: .utf8) else { throw PhoneError.invalidReply }
        try await socket.send(.string(text))
    }
}
