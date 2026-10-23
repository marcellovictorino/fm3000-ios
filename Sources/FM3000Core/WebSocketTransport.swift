import Foundation
import Network

public enum TransportMessage: Equatable {
    case text(String)
    /// A WebSocket ping or pong: the connection is alive, there is nothing to read.
    case ping
    case closed(code: Int?)
}

/// One socket carrying text frames; the seam the client is written against, so its
/// logic is checked without a network (and the real one with the fake Mac).
public protocol FrameTransport: AnyObject {
    func open() async throws
    func send(_ text: String) async throws
    func receive() async throws -> TransportMessage
    func close()
}

/// The `/connection` WebSocket over TLS 1.3 with the device's certificate, pinned to the Mac's key,
/// through Network.framework. It sets no Origin: the Mac refuses any request that has one.
public final class NWWebSocketTransport: FrameTransport {
    private let connection: NWConnection
    private let check: PinCheck
    private let queue = DispatchQueue(label: "fm3000.ws")
    private let timeout: TimeInterval

    public init(address: DialAddress, homePin: String, identity: DeviceIdentity, timeout: TimeInterval = 10) {
        self.timeout = timeout
        check = PinCheck()
        let tls = PinnedTLS.options(homePin: homePin, identity: identity, check: check)
        let parameters = NWParameters(tls: tls, tcp: NWProtocolTCP.Options())
        let websocket = NWProtocolWebSocket.Options(.version13)
        websocket.autoReplyPing = true
        websocket.maximumMessageSize = 64 * 1024 * 1024
        parameters.defaultProtocolStack.applicationProtocols.insert(websocket, at: 0)
        let host = address.host.contains(":") ? "[\(address.host)]" : address.host
        let url = URL(string: "wss://\(host):\(address.port)/connection")!
        connection = NWConnection(to: .url(url), using: parameters)
    }

    public func open() async throws {
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

    public func send(_ text: String) async throws {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "text", metadata: [metadata])
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: Data(text.utf8), contentContext: context, isComplete: true, completion: .contentProcessed { error in
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            })
        }
    }

    public func receive() async throws -> TransportMessage {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TransportMessage, Error>) in
            connection.receiveMessage { data, context, _, error in
                if let error {
                    continuation.resume(returning: .closed(code: nil))
                    _ = error
                    return
                }
                let metadata = context?.protocolMetadata(definition: NWProtocolWebSocket.definition) as? NWProtocolWebSocket.Metadata
                switch metadata?.opcode {
                case .close:
                    let code: Int?
                    switch metadata?.closeCode {
                    case .protocolCode(let defined)?: code = Int(defined.rawValue)
                    case .applicationCode(let value)?, .privateCode(let value)?: code = Int(value)
                    case nil: code = nil
                    @unknown default: code = nil
                    }
                    continuation.resume(returning: .closed(code: code))
                case .ping?, .pong?:
                    // The Mac's 30-second ping: the stack answers it (autoReplyPing); it is not a frame and not a close.
                    continuation.resume(returning: .ping)
                case .text?:
                    continuation.resume(returning: .text(String(decoding: data ?? Data(), as: UTF8.self)))
                default:
                    // Binary and continuation frames are not part of the wire; the Mac sends text only.
                    continuation.resume(returning: data.map { .text(String(decoding: $0, as: UTF8.self)) } ?? .closed(code: nil))
                }
            }
        }
    }

    public func close() { connection.cancel() }
}
