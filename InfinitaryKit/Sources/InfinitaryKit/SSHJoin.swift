import CryptoKit
import Foundation
import NIOConcurrencyHelpers
import NIOCore
import NIOPosix
import NIOSSH

/// INF-1183 (the captain's plan A, "Only the joining"): the phone signs in to its home over SSH
/// by the address its person typed, runs one fixed command there that asks the open Infinitary
/// for a one-use phone link, and joins with that link as with a scanned code. SSH carries only
/// the joining; every connection after it is the pinned connection, as today.
///
/// The home's key is asked once, by its fingerprint, and a different key later stops the join
/// before anything is sent. Sign-in tries the phone's own key; a password, typed once, only lets
/// that key in and is kept nowhere. The commands come from the home's own owner
/// (`PhoneSSHCommand`, generated from src/shared/phoneLink.ts).

/// The address its person typed, such as `kun@studio`, and the port, 22 unless said.
public struct SSHAddress: Equatable, Sendable {
    public let user: String
    public let host: String
    public let port: Int

    public init(_ text: String, port: String = "") throws {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let portText = port.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = text.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else { throw SSHJoinError.address }
        let user = String(parts[0])
        var host = String(parts[1])
        if host.hasPrefix("["), host.hasSuffix("]") { host = String(host.dropFirst().dropLast()) }
        // One account name and one host: nothing an option or a shell could read as more.
        guard user.range(of: "^[A-Za-z0-9_][A-Za-z0-9._-]{0,63}$", options: .regularExpression) != nil,
              host.range(of: "^(?:[0-9a-fA-F:.]{2,45}|[a-zA-Z0-9][a-zA-Z0-9.-]{0,252})$", options: .regularExpression) != nil
        else { throw SSHJoinError.address }
        guard let number = portText.isEmpty ? 22 : Int(portText), (1...65535).contains(number)
        else { throw SSHJoinError.port }
        self.user = user; self.host = host; self.port = number
    }

    /// Where the phone keeps its yes to this home's key.
    public var trustName: String { "\(dialHost):\(port)" }
    /// The host as a pinned address names it, with an IPv6 literal in brackets.
    public var dialHost: String { host.contains(":") ? "[\(host)]" : host }
}

/// A home's SSH key, as OpenSSH writes it (`type base64`), and the fingerprint people compare.
public struct SSHHostKey: Codable, Equatable, Sendable {
    public let line: String
    public init(line: String) { self.line = line }
    init(_ key: NIOSSHPublicKey) { line = String(openSSHPublicKey: key) }

    /// `SHA256:` and the unpadded base64 of the key's own bytes, as `ssh-keygen -l` prints it.
    public var fingerprint: String {
        let blob = line.split(separator: " ").dropFirst().first.flatMap { Data(base64Encoded: String($0)) } ?? Data()
        return "SHA256:" + Data(SHA256.hash(data: blob)).base64EncodedString().replacingOccurrences(of: "=", with: "")
    }
}

public enum SSHJoinError: LocalizedError, Equatable, Sendable {
    case address, port
    case notReached(String), loginOff(String)
    /// First sight of this home's key: the phone asks its person and sends nothing until then.
    case unknownHost(SSHHostKey)
    case hostChanged(String)
    /// The home did not let the phone's key in; `password` says whether it takes one.
    case keyRefused(String, password: Bool)
    case wrongPassword(String)
    case notOpen(String), tooOld(String), noCurl(String), noLink(String), phoneTooOld(String)
    case failed(String)

    public var errorDescription: String? {
        switch self {
        case .address: "Type the address as your account and your computer, such as kun@studio."
        case .port: "Type a port from 1 to 65535, or leave it empty for 22."
        case .notReached(let host): "Could not reach \(host). Check the address, and that both devices share a network such as Tailscale."
        case .loginOff(let host): "\(host) answered, but not for signing in. Turn on Remote Login in your Mac’s Sharing settings, or the SSH server on Linux."
        case .unknownHost: "Check this computer’s fingerprint before joining."
        case .hostChanged(let host): "\(host)’s fingerprint changed since this phone trusted it. Nothing was sent. If you did not change it, someone else may be answering at that address."
        case .keyRefused(let host, let password): password
            ? "\(host) did not let this phone’s key in."
            : "\(host) did not let this phone’s key in, and it takes no password. Copy this phone’s key to your account there, then try again."
        case .wrongPassword(let host): "\(host) did not take that password. Nothing was kept."
        case .notOpen(let host): "Infinitary is not open on \(host). Open it there, then try again."
        case .tooOld(let host): "Infinitary on \(host) needs an update before this phone can join it by its address."
        case .noCurl(let host): "\(host) needs curl for this phone to join it. Install curl there, then try again."
        case .noLink(let host): "Infinitary on \(host) could not make a link. Open Devices there to see why."
        case .phoneTooOld(let host): "Update Infinitary on this phone to join \(host) by its address."
        case .failed(let host): "Could not sign in to \(host). Try again."
        }
    }
}

/// What the phone's sign-in uses: its own key, or a password typed once to let that key in.
public enum SSHSignIn: Sendable {
    case key(NIOSSHPrivateKey)
    case password(String)
}

public enum SSHJoin {
    /// Lets the phone's key in with the password, typed once: the one command it signs in for.
    public static func placeKey(_ address: SSHAddress, trusted: SSHHostKey?, key: PhoneSSHKey, password: String) async throws {
        let said = try await run(address, trusted: trusted, signIn: .password(password),
                                 command: PhoneSSHCommand.placeKey + " '" + key.line + "'")
        guard answer(said) == PhoneSSHCommand.placed.split(separator: " ").dropFirst().map(String.init)
        else { throw SSHJoinError.failed(address.host) }
    }

    /// Asks the open Infinitary there for a one-use phone link, signed in with the phone's key.
    /// The link is never shown; the phone tries the typed address first, at the link's port.
    public static func link(_ address: SSHAddress, trusted: SSHHostKey?, key: PhoneSSHKey) async throws -> JoinLink {
        let words = answer(try await run(address, trusted: trusted, signIn: .key(key.key), command: PhoneSSHCommand.link))
        guard let version = words.first else { throw SSHJoinError.tooOld(address.host) }
        guard version == PhoneSSHCommand.version else { throw SSHJoinError.phoneTooOld(address.host) }
        switch (words.dropFirst().first, words.dropFirst(2).first) {
        case ("link", let text?):
            let link = try JoinLink(text)
            return link.trying(first: try link.typedAddress(address.dialHost))
        case ("none", PhoneSSHCommand.notOpen): throw SSHJoinError.notOpen(address.host)
        case ("none", PhoneSSHCommand.tooOld): throw SSHJoinError.tooOld(address.host)
        case ("none", PhoneSSHCommand.noCurl): throw SSHJoinError.noCurl(address.host)
        case ("none", _): throw SSHJoinError.noLink(address.host)
        default: throw SSHJoinError.failed(address.host)
        }
    }

    /// The words after the header on the last line naming it; a login shell may print more.
    static func answer(_ said: String) -> [String] {
        guard let line = said.split(whereSeparator: \.isNewline).last(where: { $0.hasPrefix(PhoneSSHCommand.header + " ") })
        else { return [] }
        return line.split(separator: " ").dropFirst().map(String.init)
    }

    /// One SSH sign-in that runs one command and answers what it printed.
    static func run(_ address: SSHAddress, trusted: SSHHostKey?, signIn: SSHSignIn, command: String) async throws -> String {
        let host = HostCheck(trusted: trusted)
        let user = UserCheck(user: address.user, signIn: signIn)
        let bootstrap = ClientBootstrap(group: MultiThreadedEventLoopGroup.singleton)
            .connectTimeout(.seconds(10))
            .channelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandlers(
                        NIOSSHHandler(role: .client(.init(userAuthDelegate: user, serverAuthDelegate: host)),
                                      allocator: channel.allocator, inboundChildChannelInitializer: nil),
                        Closer())
                }
            }
        let channel: Channel
        do {
            // A literal address is dialed as it is, never through a name lookup.
            if let literal = try? SocketAddress(ipAddress: address.host, port: address.port) {
                channel = try await bootstrap.connect(to: literal).get()
            } else {
                channel = try await bootstrap.connect(host: address.host, port: address.port).get()
            }
        } catch {
            throw refusedConnecting(error) ? SSHJoinError.loginOff(address.host) : SSHJoinError.notReached(address.host)
        }
        // The fixed commands answer in seconds; a home that holds the sign-in open is let go.
        let limit = channel.eventLoop.scheduleTask(in: .seconds(60)) { channel.close(promise: nil) }
        defer { limit.cancel(); channel.close(promise: nil) }
        let output = channel.eventLoop.makePromise(of: String.self)
        do {
            let child = channel.eventLoop.makePromise(of: Channel.self)
            channel.pipeline.handler(type: NIOSSHHandler.self).whenComplete { result in
                switch result {
                case .success(let ssh):
                    ssh.createChannel(child) { child, type in
                        guard type == .session else { return child.eventLoop.makeFailedFuture(SSHJoinError.failed(address.host)) }
                        return child.eventLoop.makeCompletedFuture {
                            try child.pipeline.syncOperations.addHandler(Exec(command: command, done: output))
                        }
                    }
                case .failure(let error): child.fail(error)
                }
            }
            channel.closeFuture.whenComplete { _ in output.fail(SSHJoinError.failed(address.host)) }
            _ = try await child.futureResult.get()
            return try await output.futureResult.get()
        } catch {
            if let seen = host.unknown { throw SSHJoinError.unknownHost(seen) }
            if host.changed { throw SSHJoinError.hostChanged(address.host) }
            if let methods = user.refusedWith {
                switch signIn {
                case .password: throw SSHJoinError.wrongPassword(address.host)
                case .key: throw SSHJoinError.keyRefused(address.host, password: methods.contains(.password))
                }
            }
            throw SSHJoinError.failed(address.host)
        }
    }

    private static func refusedConnecting(_ error: Error) -> Bool {
        if let error = error as? NIOConnectionError {
            return !error.connectionErrors.isEmpty && error.connectionErrors.allSatisfy {
                ($0.error as? IOError)?.errnoCode == ECONNREFUSED
            }
        }
        return (error as? IOError)?.errnoCode == ECONNREFUSED
    }
}

/// Answers the home's key: the one this phone trusted goes on; any other is said and refused,
/// before the phone signs in or sends anything.
private final class HostCheck: NIOSSHClientServerAuthenticationDelegate, Sendable {
    private let trusted: SSHHostKey?
    private let seen = NIOLockedValueBox<(unknown: SSHHostKey?, changed: Bool)>((nil, false))
    init(trusted: SSHHostKey?) { self.trusted = trusted }
    var unknown: SSHHostKey? { seen.withLockedValue { $0.unknown } }
    var changed: Bool { seen.withLockedValue { $0.changed } }

    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
        let key = SSHHostKey(hostKey)
        guard let trusted else {
            seen.withLockedValue { $0.unknown = key }
            return validationCompletePromise.fail(SSHJoinError.unknownHost(key))
        }
        guard trusted == key else {
            seen.withLockedValue { $0.changed = true }
            return validationCompletePromise.fail(SSHJoinError.hostChanged(""))
        }
        validationCompletePromise.succeed(())
    }
}

/// Offers one way in, once: the phone's key, or the password. A refusal keeps the ways the home
/// said it still takes, and ends the sign-in: a failed offer closes the connection.
private final class UserCheck: NIOSSHClientUserAuthenticationDelegate, Sendable {
    private let user: String
    private let signIn: SSHSignIn
    private let state = NIOLockedValueBox<(offered: Bool, refusedWith: NIOSSHAvailableUserAuthenticationMethods?)>((false, nil))
    init(user: String, signIn: SSHSignIn) { self.user = user; self.signIn = signIn }
    var refusedWith: NIOSSHAvailableUserAuthenticationMethods? { state.withLockedValue { $0.refusedWith } }

    func nextAuthenticationType(availableMethods: NIOSSHAvailableUserAuthenticationMethods,
                                nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>) {
        let first = state.withLockedValue { state in
            defer { state.offered = true }
            if state.offered { state.refusedWith = availableMethods }
            return !state.offered
        }
        guard first else { return nextChallengePromise.fail(SSHJoinError.failed("")) }
        switch signIn {
        case .key(let key):
            guard availableMethods.contains(.publicKey) else {
                state.withLockedValue { $0.refusedWith = availableMethods }
                return nextChallengePromise.fail(SSHJoinError.failed(""))
            }
            nextChallengePromise.succeed(.init(username: user, serviceName: "", offer: .privateKey(.init(privateKey: key))))
        case .password(let password):
            guard availableMethods.contains(.password) else {
                state.withLockedValue { $0.refusedWith = availableMethods }
                return nextChallengePromise.fail(SSHJoinError.failed(""))
            }
            nextChallengePromise.succeed(.init(username: user, serviceName: "", offer: .password(.init(password: password))))
        }
    }
}

/// Closes the connection on any error, which ends the sign-in.
private final class Closer: ChannelInboundHandler {
    typealias InboundIn = Any
    func errorCaught(context: ChannelHandlerContext, error: Error) { context.close(promise: nil) }
}

/// Runs the one command and reads what it prints, at most 64 KiB; what it says on its errors is not read.
private final class Exec: ChannelInboundHandler {
    typealias InboundIn = SSHChannelData
    private let command: String
    private let done: EventLoopPromise<String>
    private var said = ByteBuffer()
    init(command: String, done: EventLoopPromise<String>) { self.command = command; self.done = done }

    func handlerAdded(context: ChannelHandlerContext) {
        context.channel.setOption(ChannelOptions.allowRemoteHalfClosure, value: true).whenFailure { error in
            context.fireErrorCaught(error)
        }
    }

    func channelActive(context: ChannelHandlerContext) {
        context.triggerUserOutboundEvent(SSHChannelRequestEvent.ExecRequest(command: command, wantReply: true), promise: nil)
        context.fireChannelActive()
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let data = unwrapInboundIn(data)
        guard data.type == .channel, case .byteBuffer(var bytes) = data.data else { return }
        if said.readableBytes + bytes.readableBytes > 64 * 1024 { return context.close(promise: nil) }
        said.writeBuffer(&bytes)
    }

    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        switch event {
        case is ChannelFailureEvent: context.close(promise: nil)
        case let event as ChannelEvent where event == .inputClosed: context.close(promise: nil)
        default: context.fireUserInboundEventTriggered(event)
        }
    }

    func channelInactive(context: ChannelHandlerContext) {
        done.succeed(String(buffer: said))
        context.fireChannelInactive()
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) { context.close(promise: nil) }
}
