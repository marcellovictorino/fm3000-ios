import Foundation
import Network

/// A TLS 1.3 socket to the Mac, pinned, carrying plain bytes: what `/pair` uses.
final class RawTLSChannel {
    private let connection: NWConnection
    private let check: PinCheck
    private let queue = DispatchQueue(label: "fm3000.raw")

    init(address: DialAddress, homePin: String, identity: DeviceIdentity) {
        check = PinCheck()
        let tls = PinnedTLS.options(homePin: homePin, identity: identity, check: check)
        let parameters = NWParameters(tls: tls, tcp: NWProtocolTCP.Options())
        connection = NWConnection(host: NWEndpoint.Host(address.host), port: NWEndpoint.Port(rawValue: address.port)!, using: parameters)
    }

    /// Resolves once the handshake finished and the pin matched, so no byte goes out before.
    func open(timeout: TimeInterval) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let once = Once()
            connection.stateUpdateHandler = { [check] state in
                switch state {
                case .ready:
                    if once.take() { continuation.resume() }
                case .failed(let error), .waiting(let error):
                    if once.take() { continuation.resume(throwing: check.mismatch ? DialError.homeKeyMismatch : DialError.unreachable(error.localizedDescription)) }
                case .cancelled:
                    if once.take() { continuation.resume(throwing: DialError.unreachable("cancelled")) }
                default: break
                }
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + timeout) { [connection] in
                if once.take() { connection.cancel(); continuation.resume(throwing: DialError.timedOut) }
            }
        }
    }

    func send(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            })
        }
    }

    /// The next bytes, or nil at the end of the stream.
    func receive() async throws -> Data? {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data?, Error>) in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, isComplete, error in
                if let error { continuation.resume(throwing: error) }
                else if let data, !data.isEmpty { continuation.resume(returning: data) }
                else if isComplete { continuation.resume(returning: nil) }
                else { continuation.resume(returning: Data()) }
            }
        }
    }

    func close() { connection.cancel() }
}

/// Resolves a continuation exactly once across racing callbacks.
final class Once: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false
    func take() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if done { return false }
        done = true
        return true
    }
}
