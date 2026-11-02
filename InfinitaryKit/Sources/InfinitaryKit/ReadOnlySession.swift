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
    public private(set) var cards: [PhoneCard] = []
    public private(set) var activity: [ActivityLine] = []
    public private(set) var threads: [String: PhoneJSON] = [:]
    public private(set) var pastCards: [PhoneCard] = []
    public var showCardID: String?
    @ObservationIgnored private var threadRevisions: [String: Int] = [:]
    public private(set) var board: PhoneBoard?
    public private(set) var lastTurn: PhoneLastTurn?
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
    public private(set) var seenCards = Set<String>()
    /// The Mac's stage rule: a new card waits for its author's close-out, but a replied-under card stays.
    /// A minimized card leaves the phone's stack and count too (INF-944 item 3).
    public var stack: [PhoneCard] { cards.filter { ($0.awaiting == nil || $0.sentBackAt != nil) && !$0.minimized } }
    public var unreadCards: Int { stack.filter { !seenCards.contains($0.offerID ?? $0.id) }.count }
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
            if channel.changes { throw PhoneError.refused("Could not confirm the change. Check your computer before sending it again.") }
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
            if channel.changes { throw PhoneError.refused("Could not confirm the change. Check your computer before sending it again.") }
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
        if revision == threadRevisions[id, default: 0] { threads[id] = thread }
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
        continuation.resume(throwing: changes
            ? PhoneError.refused("Could not confirm the change. Check your computer before sending it again.")
            : PhoneError.unavailable)
    }
    private func failCalls() { for id in Array(calls.keys) { failCall(id) } }

    private func clearContent() {
        computers = []
        cards = []; activity = []; board = nil; lastTurn = nil; notice = nil; firstmateBusy = false; firstmateObserved = false
        threads = [:]; pastCards = []; showCardID = nil; threadRevisions = [:]; seenCards = []
        notified = [:]; awaited = []; primed = false; workRevision += 1
        wakeReachWaiters()
    }

    /// Reading a card ends the notice about it.
    public func markSeen(_ card: PhoneCard) {
        seenCards.insert(card.offerID ?? card.id)
        if notice?.cardID == card.id { notice = nil }
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
            if !reply && seenCards.contains(newest.offerID ?? newest.id) { return }
            notice = PhoneNotice(cardID: newest.id, title: newest.title, reply: reply)
        }
    }

    public init(mac: JoinedMac, phone: PhoneIdentity) { self.mac = mac; self.phone = phone }

    public func start() {
        guard loop == nil, !removed else { return }
        generation += 1
        let current = generation
        loop = Task { [weak self] in await self?.run(generation: current) }
    }

    public func stop() {
        generation += 1
        loop?.cancel(); loop = nil
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

    private func abort(_ socket: URLSessionWebSocketTask) {
        guard self.socket === socket else { return }
        socket.cancel(with: .goingAway, reason: nil)
        // Also cancel a handshake that has not become a WebSocket yet.
        transport?.close()
    }

    private func finishLeave(_ error: Error? = nil) {
        let continuation = leaveContinuation; leaveContinuation = nil
        if let error { continuation?.resume(throwing: error) } else { continuation?.resume() }
    }

    private func run(generation current: Int) async {
        var attempt = 0
        while !Task.isCancelled && !removed && current == generation {
            let addresses = PhoneAddresses.preferred(mac.addresses + discoveries)
            for address in addresses {
                if Task.isCancelled || removed || current != generation { return }
                let transport = PinnedTransport(pin: mac.pin, phone: phone, purpose: .connection)
                self.transport = transport
                var connection: URLSessionWebSocketTask?
                do {
                    let socket = try transport.socket(at: address)
                    connection = socket; self.socket = socket
                    failCalls()
                    pending.removeAll(); waitingSince.removeAll(); dirty.removeAll(); ready.removeAll()
                    access = "read"; firstmateBusy = false; firstmateObserved = false
                    contact = heardAt == nil ? "reaching" : "lost"
                    var hello: [String: Any] = ["t": "hello", "protocolVersion": PhoneContract.version,
                        "as": "view", "viewFloor": PhoneContract.viewFloor, "system": "ios", "spellings": ["inf"], "appVersion": "0.1.0"]
                    if let epoch { hello["cursor"] = ["epoch": epoch, "seq": sequence] }
                    let watchdog = Task { [weak self, weak socket] in
                        // Bound the handshake too: send(hello) can wait for a connection to open.
                        // Each successful pong proves liveness; welcome/reads have a separate bounded wait.
                        var welcomed = false
                        while !Task.isCancelled {
                            try? await Task.sleep(for: .seconds(10))
                            guard !Task.isCancelled, let self, let socket, self.socket === socket else { return }
                            let waiting = self.waitingSince.values.contains { Date().timeIntervalSince($0) > 15 }
                            let leaveWait = self.leaveStarted.map { Date().timeIntervalSince($0) > 15 } ?? false
                            if waiting || leaveWait { self.abort(socket); return }
                            if !welcomed && self.contact != "in-reach" {
                                self.abort(socket); return
                            }
                            welcomed = true
                            if let heard = self.heardAt, Date().timeIntervalSince(heard) > 25 {
                                self.abort(socket); return
                            }
                            socket.sendPing { [weak self, weak socket] error in
                                Task { @MainActor in
                                    guard let self, let socket, self.socket === socket else { return }
                                    if error != nil { self.abort(socket) }
                                    else { self.heardAt = Date() }
                                }
                            }
                        }
                    }
                    defer { watchdog.cancel() }
                    try await send(hello, on: socket)
                    while !Task.isCancelled {
                        let message = try await socket.receive()
                        guard current == generation, !Task.isCancelled else { break }
                        let data: Data
                        switch message {
                        case .string(let text): data = Data(text.utf8)
                        default: throw PhoneError.invalidReply
                        }
                        try await receive(data, on: socket)
                        guard current == generation, !Task.isCancelled else { break }
                        if contact == "in-reach" {
                            attempt = 0; refused = 0
                            reachedAddress = address
                            let preferred = Array(PhoneAddresses.preferred(mac.addresses + [address]).prefix(25))
                            if mac.addresses != preferred {
                                mac.addresses = preferred
                                onMacChanged?(mac)
                            }
                        }
                    }
                } catch {
                    guard current == generation, !Task.isCancelled else { transport.close(); return }
                    let code = connection?.closeCode.rawValue
                    let status = (connection?.response as? HTTPURLResponse)?.statusCode
                    if code == 4401 {
                        removed = true; clearContent()
                        contact = "removed"; finishLeave(); onRemoved?()
                    } else {
                        if status == 401 { refused += 1 }
                        else if status != nil { refused = 0 }
                        if refused >= 2 {
                            removed = true; clearContent(); contact = "removed"
                            finishLeave(); onRemoved?()
                        } else {
                            contact = code == 1001 ? "closed" : "lost"
                            missed = true
                            finishLeave(PhoneError.unavailable)
                        }
                    }
                }
                failCalls(); firstmateBusy = false; firstmateObserved = false
                transport.close()
                guard current == generation else { return }
                self.socket = nil; self.transport = nil
                if Task.isCancelled || removed || current != generation { return }
            }
            attempt = min(attempt + 1, 5)
            try? await Task.sleep(for: .seconds(attempt))
        }
    }

    private func receive(_ data: Data, on socket: URLSessionWebSocketTask) async throws {
        guard let frame = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let kind = frame["t"] as? String else { throw PhoneError.invalidReply }
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
            if frame["channel"] as? String == "inf:cards" {
                guard let snapshot = frame["payload"] else { throw PhoneError.invalidReply }
                let updated = try JSONDecoder().decode([PhoneCard].self, from: JSONSerialization.data(withJSONObject: snapshot))
                let departed = cards.filter { old in !updated.contains { $0.id == old.id } }.map(\.id)
                cards = updated
                for id in departed { Task { try? await self.readPast(id) } }
                observeCards(cards)
                supersede(PhoneContract.cards)
            }
            if frame["channel"] as? String == "inf:computers:presence", let payload = frame["payload"], sceneObservations {
                computers = try JSONDecoder().decode([PhoneComputerPresence].self, from: JSONSerialization.data(withJSONObject: payload))
                supersede(PhoneRequest.computers.rawValue)
            }
            if frame["channel"] as? String == "inf:tasks", let payload = frame["payload"] {
                board = try JSONDecoder().decode(PhoneBoard.self, from: JSONSerialization.data(withJSONObject: payload))
                supersede(PhoneRequest.board.rawValue); workRevision += 1
            }
            // A delta folds onto the board held, as on the Mac (INF-1854); a full read is the contract's resync path
            // for a delta with no base to apply to.
            if frame["channel"] as? String == "inf:tasks:delta", let payload = frame["payload"] {
                let delta = try JSONDecoder().decode(PhoneBoardDelta.self, from: JSONSerialization.data(withJSONObject: payload))
                if let held = board, let next = held.applying(delta) {
                    if next.seq != held.seq { board = next; supersede(PhoneRequest.board.rawValue); workRevision += 1 }
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
                    threads[id] = thread
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
                if frame["ok"] as? Bool == true, let value = frame["value"] {
                    do { continuation.resume(returning: try JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)) }
                    catch { continuation.resume(throwing: PhoneError.invalidReply) }
                } else {
                    continuation.resume(throwing: PhoneError.refused((frame["error"] as? [String: Any])?["message"] as? String ?? frame["error"] as? String ?? "Your computer refused this request."))
                }
                return
            }
            guard let channel = pending.removeValue(forKey: id) else { return }
            waitingSince.removeValue(forKey: id)
            guard frame["ok"] as? Bool == true, let value = frame["value"] else {
                throw PhoneError.invalidReply
            }
            let bytes = try JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)
            switch channel {
            case PhoneContract.cards: cards = try JSONDecoder().decode([PhoneCard].self, from: bytes); observeCards(cards)
            case PhoneContract.feed: activity = try JSONDecoder().decode([ActivityLine].self, from: bytes)
            case PhoneRequest.board.rawValue: board = try JSONDecoder().decode(PhoneBoard.self, from: bytes); workRevision += 1
            case PhoneRequest.conversationState.rawValue:
                firstmateBusy = try JSONDecoder().decode(PhoneConversationState.self, from: bytes).busy
                firstmateObserved = true
            case PhoneRequest.computers.rawValue: computers = try JSONDecoder().decode([PhoneComputerPresence].self, from: bytes)
            case PhoneRequest.lastTurn.rawValue: lastTurn = try JSONDecoder().decode(PhoneLastTurn?.self, from: bytes)
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
