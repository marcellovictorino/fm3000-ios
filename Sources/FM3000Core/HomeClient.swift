import Foundation

public enum ClientEvent: Equatable {
    case push(Push)
    case closed(WireError)
}

/// One connection to the Mac as a view: the handshake, requests by id, and numbered pushes.
public actor HomeClient {
    public typealias TransportFactory = @Sendable (DialAddress) -> FrameTransport

    private let addresses: [DialAddress]
    private let makeTransport: TransportFactory
    private let requestTimeout: TimeInterval
    private let helloTimeout: TimeInterval
    private var transport: FrameTransport?
    private var nextId = 1
    private var pending: [Int: CheckedContinuation<JSONValue, Error>] = [:]
    private var reader: Task<Void, Never>?
    private var finished = false
    public private(set) var welcome: Welcome?
    /// Where this connection is in the Mac's journal: send it in the next `hello` to catch up.
    public private(set) var cursor: Cursor?

    public nonisolated let events: AsyncStream<ClientEvent>
    private let emit: AsyncStream<ClientEvent>.Continuation

    public init(
        addresses: [DialAddress], cursor: Cursor? = nil, requestTimeout: TimeInterval = 30, helloTimeout: TimeInterval = 10,
        transportFactory: @escaping TransportFactory
    ) {
        self.addresses = addresses
        self.cursor = cursor
        self.requestTimeout = requestTimeout
        self.helloTimeout = helloTimeout
        self.makeTransport = transportFactory
        (events, emit) = AsyncStream.makeStream(of: ClientEvent.self, bufferingPolicy: .unbounded)
    }

    /// Dials each address in turn, says hello, and waits for the welcome.
    public func connect() async throws -> Welcome {
        var lastError: Error = DialError.unreachable("no address")
        for address in addresses {
            let transport = makeTransport(address)
            do {
                try await transport.open()
                try await transport.send(HomeFrame.hello(cursor: cursor))
                let first = try await Self.within(helloTimeout) { try await transport.receive() }
                switch first {
                case .closed(let code): throw Self.closeError(code)
                case .ping: throw WireError.notAFrame
                case .text(let text):
                    guard case .welcome(let welcome) = try HomeFrame.parse(text) else { throw WireError.notAFrame }
                    self.transport = transport
                    self.welcome = welcome
                    if cursor?.epoch != welcome.epoch { cursor = Cursor(epoch: welcome.epoch, seq: welcome.seq) }
                    // A reload starts from the newest number; a replay continues from ours.
                    if welcome.catchUp == "reload" { cursor = Cursor(epoch: welcome.epoch, seq: welcome.seq) }
                    reader = Task { [weak self] in await self?.readLoop(transport) }
                    return welcome
                }
            } catch DialError.homeKeyMismatch {
                transport.close()
                throw DialError.homeKeyMismatch
            } catch WireError.unpaired {
                transport.close()
                throw WireError.unpaired
            } catch {
                transport.close()
                lastError = error
            }
        }
        throw lastError
    }

    /// Asks one channel. The Mac's own refusal comes back as `InvokeFailure`.
    public func invoke(_ channel: String, _ args: [JSONValue] = []) async throws -> JSONValue {
        guard let transport, !finished else { throw WireError.closed(code: nil, reason: nil) }
        let id = nextId
        nextId += 1
        let frame = HomeFrame.invoke(id: id, channel: channel, args: args)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<JSONValue, Error>) in
            pending[id] = continuation
            Task { [timeout = requestTimeout] in
                do { try await transport.send(frame) } catch { self.resolve(id, .failure(error)); return }
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                self.resolve(id, .failure(WireError.timedOut))
            }
        }
    }

    public func invoke<T: Decodable>(_ channel: String, _ args: [JSONValue] = [], as type: T.Type) async throws -> T {
        try await invoke(channel, args).decoded(T.self)
    }

    /// Leaves for good: the Mac takes this phone off its list, as Remove does.
    public func leave() async {
        try? await transport?.send(HomeFrame.leave())
        close()
    }

    public func close() {
        finish(.closed(code: nil, reason: nil))
    }

    private func resolve(_ id: Int, _ result: Result<JSONValue, Error>) {
        guard let continuation = pending.removeValue(forKey: id) else { return }
        continuation.resume(with: result)
    }

    private func readLoop(_ transport: FrameTransport) async {
        while !finished {
            do {
                switch try await transport.receive() {
                case .closed(let code):
                    finish(Self.closeWire(code))
                    return
                case .ping:
                    continue
                case .text(let text):
                    switch try HomeFrame.parse(text) {
                    case .result(let id, let value, let error):
                        if let error { resolve(id, .failure(InvokeFailure(reason: error))) } else { resolve(id, .success(value ?? .null)) }
                    case .push(let push):
                        if let current = cursor, push.seq <= current.seq, current.epoch == welcome?.epoch { continue }  // already seen
                        cursor = Cursor(epoch: welcome?.epoch ?? "", seq: push.seq)
                        emit.yield(.push(push))
                    case .welcome, .ignored:
                        continue
                    }
                }
            } catch {
                finish(error as? WireError ?? .closed(code: nil, reason: nil))
                return
            }
        }
    }

    private func finish(_ reason: WireError) {
        guard !finished else { return }
        finished = true
        transport?.close()
        reader?.cancel()
        for (_, continuation) in pending { continuation.resume(throwing: reason) }
        pending.removeAll()
        emit.yield(.closed(reason))
        emit.finish()
    }

    private static func closeWire(_ code: Int?) -> WireError {
        code == CloseCode.unpaired ? .unpaired : .closed(code: code, reason: nil)
    }

    private static func closeError(_ code: Int?) -> WireError { closeWire(code) }

    private static func within<T: Sendable>(_ seconds: TimeInterval, _ work: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await work() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw WireError.timedOut
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }
}
