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
    public private(set) var computers: [PhoneComputerPresence] = []
    /// Every welcome settles its initial roster rather than replaying arrivals or packets.
    public private(set) var sceneGeneration = 0
    @ObservationIgnored private var sceneObservations = false
    public private(set) var workRevision = 0
    public private(set) var access = "read"
    /// The contract the computer's welcome said it speaks, which names the side a reads-only phone updates.
    public private(set) var homeVersion: String?
    public var notice: PhoneNotice?
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
    public private(set) var contact = "reaching"
    public private(set) var heardAt: Date?
    public private(set) var removed = false
    /// How many times the computer came back in reach after an attempt to reach it failed (INF-589 item 12).
    /// The ordinary reconnection when the app opens is not a return.
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
    @ObservationIgnored private var reachWaiters: [UUID: CheckedContinuation<Void, Error>] = [:]
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
        syncedCards = []; activity = []; syncedBoard = nil; syncedTurn = nil; notice = nil; firstmateBusy = false; firstmateObserved = false
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

    /// How long an accepted change may wait for the snapshot that shows it, the serve watchdog's own wait.
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
    private func saw(_ snapshot: PhoneSnapshot, replayed: Bool = false) {
        let before = ledger.intents.map(\.id)
        // A push the welcome replays can predate a change whose result was lost, so it settles only what it holds.
        let contradicted = ledger.saw(snapshot, welcome: replayed ? Int.min : welcomes)
        for intent in contradicted {
            restorers.removeValue(forKey: intent.id)?()
            say(PhoneError.unconfirmed.localizedDescription, at: intent)
        }
        let after = Set(ledger.intents.map(\.id))
        for id in before where !after.contains(id) { restorers.removeValue(forKey: id) }
        if after.count != before.count { refold(); return }
        switch snapshot {
        case .cards: cards = PhoneIntentFold.cards(syncedCards, ledger.intents)
        case .thread: threads = PhoneIntentFold.threads(syncedThreads, ledger.intents)
        case .board: board = PhoneIntentFold.board(syncedBoard, ledger.intents)
        case .turn: lastTurn = PhoneIntentFold.lastTurn(syncedTurn, ledger.intents)
        case .task, .crew: break
        }
    }

    private func refold() {
        cards = PhoneIntentFold.cards(syncedCards, ledger.intents)
        threads = PhoneIntentFold.threads(syncedThreads, ledger.intents)
        board = PhoneIntentFold.board(syncedBoard, ledger.intents)
        lastTurn = PhoneIntentFold.lastTurn(syncedTurn, ledger.intents)
    }

    public init(mac: JoinedMac, phone: PhoneIdentity) { self.mac = mac; self.phone = phone }

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

    /// INF-2157: how long a kept connection has to answer the reopen's ping before it is cut and redialed.
    static let reopenAnswer: Duration = .seconds(2)
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
    @ObservationIgnored private var cutting: Cut?
    /// A reopen or a change of network ended the wait, so the next round says it is reaching again.
    @ObservationIgnored private var woken = false

    private func lookAgain() {
        if pause != nil { woken = true; contact = "reaching" }
        endPause()
        guard contact == "in-reach", let socket, checking !== socket else { return }
        checking = socket
        socket.sendPing { [weak self, weak socket] error in
            Task { @MainActor in
                guard let self, let socket, self.socket === socket, self.checking === socket else { return }
                self.checking = nil
                if error != nil { self.cut(socket, .failed) } else { self.heardAt = Date() }
            }
        }
        Task { [weak self, weak socket] in
            try? await Task.sleep(for: Self.reopenAnswer)
            guard let self, let socket, self.socket === socket, self.checking === socket else { return }
            self.checking = nil
            self.cut(socket, .unanswered)
        }
    }

    private func waitBetweenRounds(_ seconds: Int) async {
        let until = ContinuousClock.now + .seconds(seconds)
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
        generation += 1
        loop?.cancel(); loop = nil
        endPause()
        finishLeave(PhoneError.unavailable)
        failCalls(); notice = nil; access = "read"; firstmateBusy = false; firstmateObserved = false
        socket?.cancel(with: .goingAway, reason: nil); socket = nil
        transport?.close(); transport = nil
        contact = "lost"
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
            access = "read"; firstmateBusy = false; firstmateObserved = false
            // Out of reach stays while later rounds try again on their own; a reopen says it is reaching.
            if attempt == 0 || woken { contact = "reaching" }
            woken = false
            let dialed = await dial(PhoneAddresses.preferred(mac.addresses + discoveries), generation: current)
            guard alive(current) else { dialed?.transport.close(); return }
            if let dialed, await serve(dialed, generation: current) {
                attempt = 0
                continue
            }
            guard alive(current) else { return }
            contact = "lost"; missed = true
            finishLeave(PhoneError.unavailable)
            attempt = min(attempt + 1, 5)
            await waitBetweenRounds(attempt)
        }
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
                    transport = dialed.transport
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
        self.socket = socket; cutting = nil
        var reached = false
        var hello: [String: Any] = ["t": "hello", "protocolVersion": PhoneContract.version,
            "as": "view", "viewFloor": PhoneContract.viewFloor, "system": "ios", "spellings": ["inf"], "appVersion": "0.1.0"]
        if let epoch { hello["cursor"] = ["epoch": epoch, "seq": sequence] }
        let watchdog = Task { [weak self, weak socket] in
            // Each successful pong proves liveness; welcome/reads have a separate bounded wait.
            var welcomed = false
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled, let self, let socket, self.socket === socket else { return }
                let waiting = self.waitingSince.values.contains { Date().timeIntervalSince($0) > 15 }
                let leaveWait = self.leaveStarted.map { Date().timeIntervalSince($0) > 15 } ?? false
                if waiting || leaveWait { self.cut(socket, .quiet); return }
                if !welcomed && self.contact != "in-reach" {
                    self.cut(socket, .quiet); return
                }
                welcomed = true
                if let heard = self.heardAt, Date().timeIntervalSince(heard) > 25 {
                    self.cut(socket, .quiet); return
                }
                socket.sendPing { [weak self, weak socket] error in
                    Task { @MainActor in
                        guard let self, let socket, self.socket === socket else { return }
                        if error != nil { self.cut(socket, .failed) }
                        else { self.heardAt = Date() }
                    }
                }
            }
        }
        defer { watchdog.cancel() }
        do {
            try await send(hello, on: socket)
            while !Task.isCancelled {
                let message = try await socket.receive()
                guard current == generation, !Task.isCancelled else { break }
                guard case .string(let text) = message else { throw PhoneError.invalidReply }
                // INF-2566: the frame is parsed and its payload decoded off the main thread, then read here in order.
                let frame = try await PhoneFrame.decode(text, reads: pending)
                guard current == generation, !Task.isCancelled else { break }
                try await receive(frame, on: socket)
                guard current == generation, !Task.isCancelled else { break }
                if contact == "in-reach" {
                    reached = true; refused = 0
                    reachedAddress = address
                    let preferred = Array(PhoneAddresses.preferred(mac.addresses + [address]).prefix(25))
                    if mac.addresses != preferred {
                        mac.addresses = preferred
                        onMacChanged?(mac)
                    }
                }
            }
        } catch {
            guard current == generation, !Task.isCancelled else { transport.close(); return reached }
            lastCut = cutting ?? .failed; cutting = nil
            if socket.closeCode.rawValue == 4401 {
                removed = true; clearContent()
                contact = "removed"; finishLeave(); onRemoved?()
            } else {
                missed = true
                finishLeave(PhoneError.unavailable)
            }
        }
        failCalls(); firstmateBusy = false; firstmateObserved = false
        transport.close()
        guard current == generation else { return reached }
        self.socket = nil; self.transport = nil; checking = nil
        return reached
    }

    private func receive(_ decoded: PhoneFrame, on socket: URLSessionWebSocketTask) async throws {
        let frame = decoded.frame
        guard let kind = frame["t"] as? String else { throw PhoneError.invalidReply }
        heardAt = Date()
        switch kind {
        case "welcome":
            guard let epoch = frame["epoch"] as? String, !epoch.isEmpty,
                  let seq = frame["seq"] as? Int, seq >= 0,
                  let catchUp = frame["catchUp"] as? String, ["replay", "reload"].contains(catchUp)
            else { throw PhoneError.invalidReply }
            if catchUp == "reload" { self.sequence = seq; primed = false; notified = [:]; awaited = [] }
            access = frame["access"] as? String == "full" ? "full" : "read"
            homeVersion = frame["protocolVersion"] as? String
            self.epoch = epoch
            welcomeSeq = seq
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
            if !sceneObservations { computers = [] }
            sceneGeneration += 1
            contact = "reaching"
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
            if frame["channel"] as? String == "inf:cards" {
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
                computers = try decoded.computers()
                supersede(PhoneRequest.computers.rawValue)
            }
            if frame["channel"] as? String == "inf:tasks", frame["payload"] != nil {
                syncedBoard = try decoded.board()
                saw(.board(syncedBoard!), replayed: replayed)
                if !replayed { supersede(PhoneRequest.board.rawValue) }
                workRevision += 1
            }
            // A delta folds onto the board held, as on the Mac (INF-1854); a full read is the contract's resync path
            // for a delta with no base to apply to.
            if frame["channel"] as? String == "inf:tasks:delta", frame["payload"] != nil {
                let delta = try decoded.delta()
                if let held = syncedBoard, let next = held.applying(delta) {
                    if next.seq != held.seq { syncedBoard = next; saw(.board(next), replayed: replayed); if !replayed { supersede(PhoneRequest.board.rawValue) }; workRevision += 1 }
                } else {
                    try await refresh(PhoneRequest.board.rawValue, on: socket)
                }
            }
            if frame["channel"] as? String == "inf:event", let event = frame["payload"] as? [String: Any], let type = event["type"] as? String {
                if type == "firstmate_state", let busy = event["busy"] as? Bool {
                    firstmateBusy = busy; firstmateObserved = true
                    if sceneObservations { supersede(PhoneRequest.conversationState.rawValue) }
                }
                if contact == "in-reach", let signal = PhoneSceneSignal.read(event) { onSceneSignal?(signal) }
                if type == "firstmate_emote", contact == "in-reach", let emote = event["emote"] as? String { onEmote?(emote) }
                if type == "user_turn" || type == "firstmate_reply" {
                    try await refresh(PhoneRequest.lastTurn.rawValue, on: socket)
                }
                if ["task_changed", "task_event", "turn_end", "tool_execution_end"].contains(type) { workRevision += 1 }
            }
            if frame["channel"] as? String == "inf:cards:thread", let payload = frame["payload"] {
                let thread = try PhoneJSON.read(payload)
                if let id = thread["cardId"].text {
                    threadRevisions[id, default: 0] += 1
                    syncedThreads[id] = thread
                    saw(.thread(card: id, thread), replayed: replayed)
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
        ready.insert(channel)
        guard initialReads.allSatisfy({ ready.contains($0) }) else { return }
        let reached = contact != "in-reach"
        contact = "in-reach"
        if missed { missed = false; returns += 1 }
        if reached { reaches += 1; wakeReachWaiters() }
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
