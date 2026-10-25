import Combine
import FM3000Core
import Foundation

public enum ConnectionPhase: Equatable {
    case unpaired
    case connecting
    case connected(mac: String, access: Access)
    case offline(String)
}

/// Everything the screens show, and every request they make. It owns the pairing, the connection
/// and its reconnecting; the views only read it and call it.
@MainActor
public final class AppModel: ObservableObject {
    @Published public private(set) var phase: ConnectionPhase
    @Published public private(set) var cards: [Card] = []
    @Published public private(set) var threads: [String: [ThreadMessage]] = [:]
    @Published public private(set) var board: Board?
    @Published public private(set) var feed: [FeedLine] = []
    /// A message for the person: the Mac's own words when it refused, or what went wrong.
    @Published public var notice: String?

    public typealias TransportMaker = @Sendable (DialAddress, Grant, DeviceIdentity) -> FrameTransport

    private let grants: GrantStore
    private let identities: IdentityStore
    private let deviceName: String
    private let makeTransport: TransportMaker
    private let pair: PairClient
    private let retryDelays: [TimeInterval]
    private var client: HomeClient?
    private var loop: Task<Void, Never>?
    private var pruner: Task<Void, Never>?
    private var cursor: Cursor?

    public init(
        grants: GrantStore, identities: IdentityStore, deviceName: String,
        pair: PairClient = PairClient(), retryDelays: [TimeInterval] = [1, 2, 4, 8, 15, 30],
        makeTransport: @escaping TransportMaker = { address, grant, identity in
            NWWebSocketTransport(address: address, homePin: grant.homeKey, identity: identity)
        }
    ) {
        self.grants = grants
        self.identities = identities
        self.deviceName = deviceName
        self.pair = pair
        self.retryDelays = retryDelays
        self.makeTransport = makeTransport
        self.phase = grants.load() == nil ? .unpaired : .connecting
    }

    /// A link opened from outside the app (a scanned code); the pairing screen shows it for review, never sends it.
    @Published public var incomingLink: String?

    public var isPaired: Bool { grants.load() != nil }
    public var canChange: Bool { if case .connected(_, .full) = phase { return true } else { return false } }

    // MARK: Pairing

    /// Uses a pasted link once. The person confirms first: this is the call that pairs.
    public func pair(withLink text: String) async -> Bool {
        do {
            let link = try PairingLink.parse(text)
            let identity = try identities.loadOrCreate()
            let grant = try await pair.join(link: link, deviceName: deviceName, identity: identity)
            try grants.save(grant)
            notice = nil
            start()
            return true
        } catch {
            notice = error.localizedDescription
            return false
        }
    }

    /// Forgets the Mac here, and asks the Mac to take this phone off its list.
    public func unpair() async {
        loop?.cancel()
        await client?.leave()
        client = nil
        grants.clear()
        identities.delete()
        cards = []; chat = []; threads = [:]; awaitingThreads = []; answered = [:]; board = nil; feed = []; cursor = nil
        phase = .unpaired
    }

    // MARK: Connection

    /// Connects, and keeps reconnecting with a growing delay until stopped or unpaired.
    public func start() {
        guard grants.load() != nil else { phase = .unpaired; return }
        if loop != nil {
            switch phase {
            case .connecting, .connected: return  // already on it
            default: break
            }
        }
        loop?.cancel()
        loop = Task { [weak self] in await self?.run() }
        pruner?.cancel()
        pruner = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                self?.pruneChat()
            }
        }
    }

    /// Stops while the app is in the background: iOS closes the socket anyway.
    public func stop() {
        loop?.cancel()
        loop = nil
        pruner?.cancel()
        pruner = nil
        let old = client
        client = nil
        Task { await old?.close() }
        if grants.load() != nil { phase = .offline("Paused in the background.") }
    }

    private func run() async {
        var attempt = 0
        while !Task.isCancelled {
            guard let grant = grants.load() else { phase = .unpaired; return }
            phase = .connecting
            do {
                let identity = try identities.loadOrCreate()
                let client = HomeClient(addresses: grant.addresses, cursor: cursor) { [makeTransport] address in
                    makeTransport(address, grant, identity)
                }
                let welcome = try await client.connect()
                self.client = client
                attempt = 0
                phase = .connected(mac: welcome.name ?? "your Mac", access: welcome.access)
                notice = nil
                try await reload()
                for await event in client.events {
                    switch event {
                    case .push(let push): apply(push)
                    case .closed(let reason): throw reason
                    }
                }
            } catch is CancellationError {
                return
            } catch WireError.unpaired {
                grants.clear()
                identities.delete()
                cards = []; chat = []; threads = [:]; awaitingThreads = []; answered = [:]; board = nil; feed = []; cursor = nil; client = nil
                phase = .unpaired
                notice = WireError.unpaired.localizedDescription
                return
            } catch DialError.homeKeyMismatch {
                phase = .offline(DialError.homeKeyMismatch.localizedDescription)
                return  // a different key is not a network blip: do not keep trying
            } catch {
                phase = .offline(error.localizedDescription)
            }
            cursor = await client?.cursor ?? cursor
            client = nil
            let delay = retryDelays[min(attempt, retryDelays.count - 1)]
            attempt += 1
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }

    /// The main Firstmate chat: what you sent, and what the first mate answered (`firstmate_reply` on `inf:event`).
    @Published public private(set) var chat: [ChatItem] = []
    /// True from a sent message until the first mate's reply arrives (or three minutes pass): the "typing" dots.
    @Published public private(set) var awaitingReply = false
    /// Cards whose thread is waiting for an answer to what the captain just wrote there: the "typing" dots under that card.
    @Published public private(set) var awaitingThreads: Set<String> = []
    private var threadAwaitingSince: [String: Date] = [:]
    private var chatCounter = 0
    private var awaitingSince = Date.distantPast

    private func expectReply(to words: String) {
        awaitingReply = true
        let since = Date(); awaitingSince = since
        let before = chat.last(where: { $0.who == "firstmate" })?.text
        Task { [weak self] in
            // The reply line the desktop shows above its input is saved as the last turn. A push may miss this phone, so ask for it too.
            while let self, self.awaitingSince == since, self.awaitingReply, Date().timeIntervalSince(since) < 180 {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard self.awaitingSince == since, self.awaitingReply else { return }
                if let turn: LastTurn = try? await self.ask("inf:conversation:last-turn"), let reply = turn.reply,
                   turn.you.trimmingCharacters(in: .whitespacesAndNewlines) == words, reply.text != before, self.awaitingSince == since {
                    self.addChat("firstmate", reply.text, problem: reply.problem ?? false)
                    return
                }
            }
            if let self, self.awaitingSince == since { self.awaitingReply = false }
        }
    }

    /// The crewmate thread has no push: the view refreshes its log while this is set, and ends it with `crewAnswered`.
    public func expectCrewReply(_ taskId: String) { expectThreadReply("crew-" + taskId) }
    public func crewAnswered(_ taskId: String) { awaitingThreads.remove("crew-" + taskId) }

    private func expectThreadReply(_ cardId: String) {
        awaitingThreads.insert(cardId)
        let since = Date(); threadAwaitingSince[cardId] = since
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 180_000_000_000)
            if let self, self.threadAwaitingSince[cardId] == since { self.awaitingThreads.remove(cardId) }
        }
    }

    /// Stores a thread as the Mac sent it; an answer from the other side ends the wait.
    private func setThread(_ cardId: String, _ messages: [ThreadMessage]) {
        threads[cardId] = messages
        if let last = messages.last, last.who != "captain" { awaitingThreads.remove(cardId) }
    }

    private func addChat(_ who: String, _ text: String, problem: Bool = false) {
        if who == "firstmate" { awaitingReply = false }
        chatCounter += 1
        let now = Date().timeIntervalSince1970 * 1000
        chat = ChatWindow.visible(chat + [ChatItem(id: "c\(chatCounter)", who: who, text: text, at: now, problem: problem)], now: now)
    }

    /// Drops what is older than three hours; run on a timer, since an idle tab adds nothing to trigger it.
    public func pruneChat() {
        let kept = ChatWindow.visible(chat, now: Date().timeIntervalSince1970 * 1000)
        if kept != chat { chat = kept }
    }

    private func reload() async throws {
        let list: [Card] = try await ask("inf:cards:list")
        cards = list
        for card in list { threads[card.id] = threads[card.id] ?? [] }
    }

    private func apply(_ push: Push) {
        switch push.channel {
        case "inf:cards":
            if let list = try? push.payload.decoded([Card].self) { cards = list }
        case "inf:cards:thread":
            if let thread = try? push.payload.decoded(CardThread.self) { setThread(thread.cardId, thread.messages) }
        case "inf:event":
            guard case .object(let o) = push.payload, case .string(let type)? = o["type"], case .string(let text)? = o["text"] else { break }
            if type == "firstmate_reply" { addChat("firstmate", text, problem: o["problem"] == .bool(true)) }
            // Another device's message shows too; one this phone just sent is already there.
            else if type == "user_turn", !(chat.last(where: { $0.isMine })?.text == text && Date().timeIntervalSince1970 * 1000 - (chat.last?.at ?? 0) < 30_000) { addChat("captain", text); expectReply(to: text) }
        case "inf:tasks", "inf:tasks:delta":
            Task { await refreshBoard() }
        default:
            break
        }
    }

    private func ask<T: Decodable>(_ channel: String, _ args: [JSONValue] = []) async throws -> T {
        guard let client else { throw WireError.closed(code: nil, reason: nil) }
        return try await client.invoke(channel, args).decoded(T.self)
    }

    // MARK: What the person does

    /// A card the person answered from this phone: what it said and which button they pressed, kept after the Mac closes it.
    public struct AnsweredCard: Equatable { public let card: Card; public let label: String }
    @Published public private(set) var answered: [String: AnsweredCard] = [:]
    /// The button being sent right now, by card: the screen shows it as working at once.
    @Published public private(set) var choosing: [String: String] = [:]
    /// A screen asks for a tab (0 Cards, 1 Message, 2 Tasks, 3 Others); the root shows it and clears this.
    @Published public var requestedTab: Int?

    /// True once a card is closed: answered here, or gone from the Mac's list.
    public func isClosed(_ card: Card) -> Bool { answered[card.id] != nil || !cards.contains { $0.id == card.id } }

    /// Chooses one of a card's buttons: `inf:cards:act`.
    public func choose(_ action: CardAction, on card: Card) async {
        guard choosing[card.id] == nil else { return }
        choosing[card.id] = action.id
        defer { choosing[card.id] = nil }
        do {
            let result: ActResult = try await ask("inf:cards:act", [.string(card.id), .string(action.id), .string("chrome")])
            if let refusal = result.refusal { notice = refusal; return }
            if result.effect != nil { notice = "\(action.label) needs your Mac's window: it opens something there." }
            if action.keepsOpen != true { answered[card.id] = AnsweredCard(card: card, label: action.label) }
        } catch { notice = error.localizedDescription }
    }

    /// Replies under a card: `inf:cards:reply`. The words go as the captain's own.
    public func reply(_ text: String, to card: Card, attachments: [Attachment] = []) async -> Bool {
        let words = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !words.isEmpty || !attachments.isEmpty else { return false }
        do {
            let thread: CardThread = try await ask("inf:cards:reply", [.string(card.id), Attachments.payload(text: words, attachments: attachments)])
            setThread(card.id, thread.messages)
            expectThreadReply(card.id)
            return true
        } catch { notice = error.localizedDescription; return false }
    }

    public func loadThread(of card: Card) async {
        if let thread: CardThread = try? await ask("inf:cards:thread", [.string(card.id)]) { setThread(card.id, thread.messages) }
    }

    /// Talks to Firstmate: `inf:converse`.
    public func send(_ text: String, attachments: [Attachment] = []) async -> Bool {
        let words = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !words.isEmpty || !attachments.isEmpty else { return false }
        do {
            let _: JSONValue = try await ask("inf:converse", [Attachments.payload(text: words, attachments: attachments)])
            addChat("captain", words.isEmpty ? "(\(attachments.count) attachment\(attachments.count == 1 ? "" : "s"))" : words)
            expectReply(to: words)
            return true
        } catch { notice = error.localizedDescription; return false }
    }

    public func refreshBoard() async {
        do { board = try await ask("inf:tasks:board") } catch { notice = error.localizedDescription }
    }

    public func taskDetail(_ id: String) async -> TaskDetail? {
        do { return try await ask("inf:tasks:detail", [.string(id)]) } catch { notice = error.localizedDescription; return nil }
    }

    public func resources() async -> ComputerResources? { try? await ask("inf:computers:resources") }

    /// The desktop's "Open pull requests" panel: its extension stores the list under `prs` (`inf:plugins:db`).
    public func openPRs() async -> OpenPRs? {
        let args: [JSONValue] = [.object(["op": .string("get"), "extensionId": .string("open-prs"), "key": .string("prs")])]
        guard let stored: StoreValue<OpenPRs> = try? await ask("inf:plugins:db", args) else { return nil }
        return stored.value
    }

    /// Asks the panel's own server action to read GitHub again now (the panel's refresh button).
    public func refreshOpenPRs() async {
        let _: JSONValue? = try? await ask("inf:plugins:invoke", [.string("open-prs"), .string("refresh"), .null])
    }

    /// The `machine-load` panel's saved reading (GPU, and memory counted as the desktop panel counts it): the panel's Mac side keeps
    /// it under `latest` in its own store, which is what the desktop panel draws. Nil when the Mac does not let this phone read the
    /// store, holds none, or holds one more than three minutes old.
    public func machineSample() async -> MachineSample? {
        let args: [JSONValue] = [.object(["op": .string("get"), "extensionId": .string("machine-load"), "key": .string("latest")])]
        guard let stored: StoreValue<MachineSample> = try? await ask("inf:plugins:db", args), let sample = stored.value, sample.isFresh() else { return nil }
        return sample
    }

    /// The quota panel's reading: remaining share of the Claude and Codex windows. Nil when the Mac holds none.
    public func quota() async -> QuotaSnapshot? {
        try? await ask("inf:quota:snapshot") as QuotaSnapshot?
    }

    /// The model a card's task runs on: the card's own model id, else the one the board holds for that task.
    public func modelName(for card: Card) -> String? {
        modelPill(label: nil, id: card.model ?? board?.tasks.first { $0.id == card.taskId }?.model)
    }

    /// The Mac's live feed over the tailnet (`MachineFeed`). Needs no pairing, so it also works while the phone is not connected.
    public func machineFeed() async -> MachineFeed.Outcome {
        let text = UserDefaults.standard.string(forKey: "machineFeedURL") ?? MachineFeed.defaultURL
        guard let url = URL(string: text) else { return .unreachable }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 4)
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        guard let (data, response) = try? await URLSession.shared.data(for: request), (response as? HTTPURLResponse)?.statusCode == 200 else { return .unreachable }
        return MachineFeed.outcome(of: data)
    }

    public func crewLog(_ id: String) async -> CrewLog? { try? await ask("inf:tasks:crewmate", [.string(id)]) }

    public func crewLive(_ id: String) async -> CrewLive? { try? await ask("inf:tasks:crewmate:live", [.string(id)]) }

    /// Tells the crewmate something: `inf:task:steer`. The Mac may refuse (nothing is running), and says why.
    /// The Mac's reason when it refused, kept for the thread to show beside its input; nil after a message goes through.
    @Published public private(set) var steerProblem: String?

    public func steer(_ taskId: String, _ text: String) async -> Bool {
        let words = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !words.isEmpty else { return false }
        do {
            let result: SteerResult = try await ask("inf:task:steer", [.string(taskId), .string(words)])
            steerProblem = result.ok ? nil : (result.text ?? "The Mac did not take that.")
            return result.ok
        } catch { steerProblem = error.localizedDescription; return false }
    }

    /// Starts a queued task (`inf:task:run`, the desktop's Start button); the Mac says why when it will not.
    public func clearSteerProblem() { steerProblem = nil }

    public func startTask(_ taskId: String) async -> Bool {
        do {
            let result: SteerResult = try await ask("inf:task:run", [.string(taskId), .string("start-task")])
            steerProblem = result.ok ? nil : (result.text ?? "The Mac did not start that task.")
            await refreshBoard()
            return result.ok
        } catch { steerProblem = error.localizedDescription; return false }
    }

    public func refreshFeed() async {
        do { feed = try await ask("inf:feed:recent") } catch { notice = error.localizedDescription }
    }
}
