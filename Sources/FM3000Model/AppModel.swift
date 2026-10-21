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
        cards = []; threads = [:]; board = nil; feed = []; cursor = nil
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
    }

    /// Stops while the app is in the background: iOS closes the socket anyway.
    public func stop() {
        loop?.cancel()
        loop = nil
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
                cards = []; threads = [:]; board = nil; feed = []; cursor = nil; client = nil
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

    private func reload() async throws {
        let list: [Card] = try await ask("fm:cards:list")
        cards = list
        for card in list { threads[card.id] = threads[card.id] ?? [] }
    }

    private func apply(_ push: Push) {
        switch push.channel {
        case "fm:cards":
            if let list = try? push.payload.decoded([Card].self) { cards = list }
        case "fm:cards:thread":
            if let thread = try? push.payload.decoded(CardThread.self) { threads[thread.cardId] = thread.messages }
        case "fm:tasks", "fm:tasks:delta":
            Task { await refreshBoard() }
        default:
            break
        }
    }

    private func ask<T: Decodable>(_ channel: String, _ args: [JSONValue] = []) async throws -> T {
        guard let client else { throw WireError.closed(code: nil, reason: nil) }
        return try await client.invoke(channel, args, as: T.self)
    }

    // MARK: What the person does

    /// Chooses one of a card's buttons: `fm:cards:act`.
    public func choose(_ action: CardAction, on card: Card) async {
        do {
            let result: ActResult = try await ask("fm:cards:act", [.string(card.id), .string(action.id), .string("chrome")])
            if let refusal = result.refusal { notice = refusal }
            else if result.effect != nil { notice = "\(action.label) needs your Mac's window: it opens something there." }
        } catch { notice = error.localizedDescription }
    }

    /// Replies under a card: `fm:cards:reply`. The words go as the captain's own.
    public func reply(_ text: String, to card: Card) async -> Bool {
        let words = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !words.isEmpty else { return false }
        do {
            let thread: CardThread = try await ask("fm:cards:reply", [.string(card.id), .string(words)])
            threads[card.id] = thread.messages
            return true
        } catch { notice = error.localizedDescription; return false }
    }

    public func loadThread(of card: Card) async {
        if let thread: CardThread = try? await ask("fm:cards:thread", [.string(card.id)]) { threads[card.id] = thread.messages }
    }

    /// Talks to Firstmate: `fm:converse`.
    public func send(_ text: String) async -> Bool {
        let words = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !words.isEmpty else { return false }
        do {
            let _: JSONValue = try await ask("fm:converse", [.string(words)])
            return true
        } catch { notice = error.localizedDescription; return false }
    }

    public func refreshBoard() async {
        do { board = try await ask("fm:tasks:board") } catch { notice = error.localizedDescription }
    }

    public func refreshFeed() async {
        do { feed = try await ask("fm:feed:recent") } catch { notice = error.localizedDescription }
    }
}
