import CryptoKit
import Foundation
import NIOConcurrencyHelpers
import NIOCore
import NIOPosix
import NIOSSH
import Testing
@testable import InfinitaryKit

/// INF-1183, the captain's approved plan "join a home from the iOS app by SSH address": the phone
/// asks once about a home's key, signs in with its own key first, lets that key in with a password
/// typed once, and says each refusal in plain words. The home here is an SSH server in this test
/// that answers the fixed commands as the home's door does (src/core/devices/phoneDoor.test.ts
/// runs those commands for real); the phone journey signs in to OpenSSH itself.
@Suite(.serialized) struct SSHJoinTests {
    private static let link = "infinitary://join?as=mac&at=studio.local:47623&also=192.168.1.20:47623"
        + "&key=" + String(repeating: "k", count: 43) + "&code=" + String(repeating: "c", count: 43)

    @Test func readsTheAddressItsPersonTyped() throws {
        let address = try SSHAddress("  kun@studio ", port: "")
        #expect(address == (try SSHAddress("kun@studio", port: "22")))
        #expect((try SSHAddress("kun@[fd00::20]", port: "2222")).trustName == "[fd00::20]:2222")
        for text in ["studio", "kun@", "@studio", "kun@studio@x", "-oProxyCommand=x@studio", "kun@studio;rm"] {
            #expect(throws: SSHJoinError.address) { try SSHAddress(text) }
        }
        for port in ["0", "65536", "ssh"] {
            #expect(throws: SSHJoinError.port) { try SSHAddress("kun@studio", port: port) }
        }
    }

    @Test func asksOnceAboutTheHomesKeyAndStopsOnAnother() async throws {
        let home = try await Home.start()
        defer { home.stop() }
        let phone = PhoneSSHKey(NIOSSHPrivateKey(p256Key: .init()))
        home.letIn(phone)
        // First sight: nothing is signed in or run until the person says yes.
        let seen = try await #require(throwsUnknownHost { try await SSHJoin.link(home.address, trusted: nil, key: phone) })
        #expect(seen == home.key)
        #expect(seen.fingerprint == home.fingerprint)
        #expect(home.commands.isEmpty)
        // A different key later stops the join before anything is sent.
        let other = SSHHostKey(NIOSSHPrivateKey(p256Key: .init()).publicKey)
        await #expect(throws: SSHJoinError.hostChanged("127.0.0.1")) {
            try await SSHJoin.link(home.address, trusted: other, key: phone)
        }
        #expect(home.commands.isEmpty)
    }

    @Test func joinsWithTheLinkTheHomeAnswersTypedAddressFirst() async throws {
        let home = try await Home.start(answer: "Last login: today\ninfinitary-phone-link 1 link \(Self.link)\n")
        defer { home.stop() }
        let phone = PhoneSSHKey(NIOSSHPrivateKey(p256Key: .init()))
        home.letIn(phone)
        let link = try await SSHJoin.link(home.address, trusted: home.key, key: phone)
        #expect(home.commands == [PhoneSSHCommand.link])
        #expect(link.code == String(repeating: "c", count: 43))
        #expect(link.routes == ["127.0.0.1:47623", "studio.local:47623", "192.168.1.20:47623"])
    }

    @Test func saysEachThingTheHomeFound() async throws {
        let phone = PhoneSSHKey(NIOSSHPrivateKey(p256Key: .init()))
        for (answer, refusal) in [
            ("infinitary-phone-link 1 none not-open", SSHJoinError.notOpen("127.0.0.1")),
            ("infinitary-phone-link 1 none too-old", .tooOld("127.0.0.1")),
            ("infinitary-phone-link 1 none no-curl", .noCurl("127.0.0.1")),
            ("infinitary-phone-link 1 none refused", .noLink("127.0.0.1")),
            ("infinitary-phone-link 2 link \(Self.link)", .phoneTooOld("127.0.0.1")),
            ("zsh: command not found", .tooOld("127.0.0.1")),
        ] {
            let home = try await Home.start(answer: answer + "\n")
            defer { home.stop() }
            home.letIn(phone)
            await #expect(throws: refusal) { try await SSHJoin.link(home.address, trusted: home.key, key: phone) }
        }
    }

    @Test func letsItsKeyInWithThePasswordOnce() async throws {
        let home = try await Home.start(password: "right horse", answer: PhoneSSHCommand.placed + "\n")
        defer { home.stop() }
        let phone = PhoneSSHKey(NIOSSHPrivateKey(p256Key: .init()))
        // The home refuses the key and says it takes a password.
        await #expect(throws: SSHJoinError.keyRefused("127.0.0.1", password: true)) {
            try await SSHJoin.link(home.address, trusted: home.key, key: phone)
        }
        await #expect(throws: SSHJoinError.wrongPassword("127.0.0.1")) {
            try await SSHJoin.placeKey(home.address, trusted: home.key, key: phone, password: "wrong")
        }
        #expect(home.commands.isEmpty)
        try await SSHJoin.placeKey(home.address, trusted: home.key, key: phone, password: "right horse")
        #expect(home.commands == [PhoneSSHCommand.placeKey + " '" + phone.line + "'"])
        #expect(phone.line.hasPrefix("ecdsa-sha2-nistp256 "))
    }

    @Test func saysWhenTheHomeTakesNoPassword() async throws {
        let home = try await Home.start()
        defer { home.stop() }
        await #expect(throws: SSHJoinError.keyRefused("127.0.0.1", password: false)) {
            try await SSHJoin.link(home.address, trusted: home.key, key: PhoneSSHKey(NIOSSHPrivateKey(p256Key: .init())))
        }
    }

    @Test func saysRemoteLoginIsOffWhenNothingListens() async throws {
        let home = try await Home.start()
        let address = home.address
        home.stop()
        await #expect(throws: SSHJoinError.loginOff("127.0.0.1")) {
            try await SSHJoin.link(address, trusted: nil, key: PhoneSSHKey(NIOSSHPrivateKey(p256Key: .init())))
        }
    }

    private func throwsUnknownHost(_ body: () async throws -> some Any) async -> SSHHostKey? {
        do { _ = try await body(); return nil }
        catch SSHJoinError.unknownHost(let key) { return key }
        catch { return nil }
    }
}

/// A home's SSH server: its own key, the keys it lets in, at most one password, and what each
/// command it runs prints.
private final class Home: Sendable {
    let address: SSHAddress
    let key: SSHHostKey
    let fingerprint: String
    private let channel: Channel
    private let state: NIOLockedValueBox<(keys: [NIOSSHPublicKey], commands: [String])>

    var commands: [String] { state.withLockedValue { $0.commands } }
    func letIn(_ phone: PhoneSSHKey) { state.withLockedValue { $0.keys.append(phone.key.publicKey) } }
    func stop() { try? channel.close().wait() }

    private init(address: SSHAddress, key: SSHHostKey, channel: Channel,
                 state: NIOLockedValueBox<(keys: [NIOSSHPublicKey], commands: [String])>) {
        self.address = address; self.key = key; self.channel = channel; self.state = state
        // As `ssh-keygen -l` derives it: SHA-256 of the key's bytes.
        let blob = Data(base64Encoded: String(key.line.split(separator: " ")[1]))!
        fingerprint = "SHA256:" + Data(SHA256.hash(data: blob)).base64EncodedString().replacingOccurrences(of: "=", with: "")
    }

    static func start(password: String? = nil, answer: String = "") async throws -> Home {
        let hostKey = NIOSSHPrivateKey(p256Key: .init())
        let state = NIOLockedValueBox<(keys: [NIOSSHPublicKey], commands: [String])>(([], []))
        let users = Users(password: password, state: state)
        let channel = try await ServerBootstrap(group: MultiThreadedEventLoopGroup.singleton)
            .childChannelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandler(NIOSSHHandler(
                        role: .server(.init(hostKeys: [hostKey], userAuthDelegate: users)),
                        allocator: channel.allocator,
                        inboundChildChannelInitializer: { child, _ in
                            child.eventLoop.makeCompletedFuture {
                                try child.pipeline.syncOperations.addHandler(Run(answer: answer, state: state))
                            }
                        }))
                }
            }
            .bind(host: "127.0.0.1", port: 0).get()
        let port = channel.localAddress!.port!
        return Home(address: try SSHAddress("kun@127.0.0.1", port: String(port)),
                    key: SSHHostKey(hostKey.publicKey), channel: channel, state: state)
    }
}

private final class Users: NIOSSHServerUserAuthenticationDelegate, Sendable {
    let password: String?
    let state: NIOLockedValueBox<(keys: [NIOSSHPublicKey], commands: [String])>
    init(password: String?, state: NIOLockedValueBox<(keys: [NIOSSHPublicKey], commands: [String])>) {
        self.password = password; self.state = state
    }
    var supportedAuthenticationMethods: NIOSSHAvailableUserAuthenticationMethods {
        password == nil ? .publicKey : [.publicKey, .password]
    }
    func requestReceived(request: NIOSSHUserAuthenticationRequest, responsePromise: EventLoopPromise<NIOSSHUserAuthenticationOutcome>) {
        switch request.request {
        case .publicKey(let offer) where state.withLockedValue({ $0.keys.contains(offer.publicKey) }):
            responsePromise.succeed(.success)
        case .password(let offer) where password != nil && offer.password == password:
            responsePromise.succeed(.success)
        default: responsePromise.succeed(.failure)
        }
    }
}

private final class Run: ChannelDuplexHandler {
    typealias InboundIn = SSHChannelData
    typealias OutboundIn = SSHChannelData
    typealias OutboundOut = SSHChannelData
    let answer: String
    let state: NIOLockedValueBox<(keys: [NIOSSHPublicKey], commands: [String])>
    init(answer: String, state: NIOLockedValueBox<(keys: [NIOSSHPublicKey], commands: [String])>) {
        self.answer = answer; self.state = state
    }
    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        guard let exec = event as? SSHChannelRequestEvent.ExecRequest else { return context.fireUserInboundEventTriggered(event) }
        state.withLockedValue { $0.commands.append(exec.command) }
        let bytes = context.channel.allocator.buffer(string: answer)
        context.writeAndFlush(wrapOutboundOut(SSHChannelData(type: .channel, data: .byteBuffer(bytes))), promise: nil)
        context.triggerUserOutboundEvent(SSHChannelRequestEvent.ExitStatus(exitStatus: 0), promise: nil)
        context.close(promise: nil)
    }
}
