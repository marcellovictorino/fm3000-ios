import Foundation
import Security
import Synchronization

/// Each attempt owns an ephemeral session. No ambient cookies, cache, credentials or redirects.
public final class PinnedTransport: NSObject, URLSessionDelegate, URLSessionTaskDelegate, @unchecked Sendable {
    private let pin: String
    private let phone: PhoneIdentity
    private var session: URLSession!
    private let rejectedPin = Mutex(false)

    public enum Purpose { case pairing, connection }

    public init(pin: String, phone: PhoneIdentity, purpose: Purpose) {
        self.pin = pin; self.phone = phone
        super.init()
        let config = URLSessionConfiguration.ephemeral
        config.tlsMinimumSupportedProtocolVersion = .TLSv13
        config.urlCredentialStorage = nil
        config.httpCookieStorage = nil
        config.urlCache = nil
        config.connectionProxyDictionary = [:]
        // A one-use pairing POST is bounded; a socket lives across many heartbeats.
        config.timeoutIntervalForRequest = purpose == .pairing ? 10 : 60
        config.timeoutIntervalForResource = purpose == .pairing ? 15 : 7 * 24 * 60 * 60
        config.waitsForConnectivity = false
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    public func close() { session.invalidateAndCancel() }

    public func pair(_ link: JoinLink, name: String) async throws -> JoinedMac {
        // Preflight is non-mutating: even a timeout here cannot spend the invitation.
        // Once a pinned route answers, the one-use POST is never retried on another route.
        for address in link.routes {
            do {
                let request = URLRequest(url: try JoinLink.url(address, path: PhoneContract.connectionPath))
                let (_, response) = try await session.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 426 else { continue }
            } catch {
                if rejectedPin.withLock({ $0 }) { throw PhoneError.wrongMac }
                if Task.isCancelled { throw CancellationError() }
                continue
            }
            do { return try await pair(link, at: address, name: name) }
            catch {
                if rejectedPin.withLock({ $0 }) { throw PhoneError.wrongMac }
                if let error = error as? PhoneError { throw error }
                throw PhoneError.unavailable
            }
        }
        throw PhoneError.unavailable
    }

    private func pair(_ link: JoinLink, at address: String, name: String, again: Bool = false) async throws -> JoinedMac {
        var request = URLRequest(url: try JoinLink.url(address, path: PhoneContract.pairPath))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = ["code": link.code, "kind": link.kind, "system": "ios", "name": name]
        if again { body["again"] = true }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard data.count <= 4096, let response = response as? HTTPURLResponse,
              let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { throw PhoneError.invalidReply }
        if response.statusCode != 201 {
            let refusal = result["refused"] as? String
            // This explicit refusal proves the first request did not spend the invitation.
            // A fresh link can recover an earlier join whose success was not kept on this phone.
            if response.statusCode == 409, refusal == "paired", !again {
                return try await pair(link, at: address, name: name, again: true)
            }
            if refusal == "malformed" {
                throw PhoneError.refused("Update Infinitary on your Mac before joining this phone.")
            }
            if refusal == "expired" || refusal == "used" || refusal == "unknown" {
                throw PhoneError.refused("This link no longer works. Make a new one in Devices on your Mac.")
            }
            throw PhoneError.refused("Your Mac could not add this phone. Make a new link in Devices and try again.")
        }
        guard result["kind"] as? String == "view", let id = result["deviceId"] as? String,
              !id.isEmpty, id.count <= 64 else { throw PhoneError.invalidReply }
        return JoinedMac(addresses: link.routes,
                         pin: link.pin, deviceID: id, name: link.computer)
    }

    public func socket(at address: String) throws -> URLSessionWebSocketTask {
        let socket = session.webSocketTask(with: try JoinLink.url(address, path: PhoneContract.connectionPath, websocket: true))
        socket.maximumMessageSize = PhoneContract.maxFrameBytes
        socket.resume()
        return socket
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodServerTrust:
            guard let trust = challenge.protectionSpace.serverTrust,
                  let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
                  let certificate = chain.first, PhoneIdentity.pin(of: certificate) == pin
            else {
                rejectedPin.withLock { $0 = true }
                completionHandler(.cancelAuthenticationChallenge, nil); return
            }
            // Deliberately trusts the paired public key, not the self-signed envelope's name/date.
            completionHandler(.useCredential, URLCredential(trust: trust))
        case NSURLAuthenticationMethodClientCertificate:
            completionHandler(.useCredential, URLCredential(identity: phone.identity,
                certificates: [phone.certificate], persistence: .forSession))
        default: completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
