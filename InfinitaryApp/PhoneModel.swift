import Foundation
import InfinitaryKit
import Network
import Observation
import UIKit

/// INF-1183: joining a home by its address, one step at a time on its sheet.
struct AddressJoin: Equatable {
    enum Step: Equatable {
        /// Signing in and asking the home for a link.
        case working
        /// First sight of the home's key: the person says yes, or Not this one.
        case trust(SSHHostKey)
        /// The home did not let the phone's key in; `password` says whether it takes one.
        case keyRefused(password: Bool)
        /// The join stopped; `problem` says why, and the person may try again.
        case stopped
    }
    let address: SSHAddress
    var step: Step
    var problem: String?
}

@MainActor @Observable final class PhoneModel {
    var connection: ReadOnlySession?
    var proposal: JoinLink?
    var problem: String?
    var busy = false
    var removed = false
    let nearby = NearbyMacs()
    var addressJoin: AddressJoin?
    private var identity: PhoneIdentity?
    private var sshKey: PhoneSSHKey?
    private var signingIn: Task<Void, Never>?
    private var joining: Task<Void, Never>?
    private var foreground = false
    private var backgroundTime = UIBackgroundTaskIdentifier.invalid
    /// INF-2157: a change of network looks again at once, as a reopen does, rather than waiting on a quiet connection.
    @ObservationIgnored private let network = NWPathMonitor()
    @ObservationIgnored private var networkSeen: String?
    private let savedURL: URL
    private let trustedURL: URL
    private let loadIdentity: () throws -> PhoneIdentity
    private let readMac: () throws -> JoinedMac?
    private let protectedDataAvailable: @MainActor () -> Bool

    init(loadIdentity: @escaping () throws -> PhoneIdentity = PhoneIdentity.loadOrCreate,
         readMac: (() throws -> JoinedMac?)? = nil,
         protectedDataAvailable: @escaping @MainActor () -> Bool = { UIApplication.shared.isProtectedDataAvailable }) {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("JoinedMac.json")
        savedURL = url
        trustedURL = url.deletingLastPathComponent().appendingPathComponent("TrustedHomes.json")
        self.loadIdentity = loadIdentity
        self.protectedDataAvailable = protectedDataAvailable
        self.readMac = readMac ?? {
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return try JSONDecoder().decode(JoinedMac.self, from: Data(contentsOf: url))
        }
        // Prewarm can construct the model before first unlock. Read protected data on activation.
        nearby.changed = { [weak self] addresses in self?.connection?.found(addresses: addresses) }
        network.pathUpdateHandler = { [weak self] path in
            let seen = "\(path.status)|" + path.availableInterfaces.map(\.name).joined(separator: ",")
            let usable = path.status == .satisfied
            Task { @MainActor in self?.networkChanged(seen, usable: usable) }
        }
        network.start(queue: .main)
    }

    private func networkChanged(_ seen: String, usable: Bool) {
        // The monitor's first answer is the network the app started on, not a change.
        defer { networkSeen = seen }
        guard let before = networkSeen, before != seen, usable, foreground else { return }
        connection?.start()
    }

    @discardableResult func restore() -> Bool {
        guard connection == nil, !busy else { return true }
        do {
            identity = try identity ?? loadIdentity()
            if let mac = try readMac() {
                guard JoinLink.validKey(mac.pin), !mac.addresses.isEmpty, mac.addresses.count <= 25,
                      !mac.deviceID.isEmpty, !mac.name.isEmpty,
                      mac.addresses.allSatisfy({ (try? JoinLink.url($0, path: "/")) != nil })
                else { return discardDamagedMac() }
                connect(mac)
            }
            problem = nil
            return true
        } catch {
            if identity == nil { problem = error.localizedDescription }
            else if needsUnlock(error) { problem = "Could not read this phone’s saved computer. Unlock your phone and try again." }
            else if error is DecodingError || (error as? CocoaError)?.code == .fileReadCorruptFile {
                return discardDamagedMac()
            } else { problem = "Could not read this phone’s saved computer. Try again." }
            return false
        }
    }

    private func needsUnlock(_ error: Error) -> Bool {
        !protectedDataAvailable() || (error as? CocoaError)?.code == .fileReadNoPermission
    }

    private func discardDamagedMac() -> Bool {
        guard protectedDataAvailable() else {
            problem = "Could not read this phone’s saved computer. Unlock your phone and try again."
            return false
        }
        do {
            try forget()
            problem = "Infinitary forgot a damaged connection. Use a new link to join your computer again."
            return true
        } catch {
            problem = needsUnlock(error) ? "Could not forget this computer. Unlock your phone and try again."
                : "Could not forget this computer. Try again."
            return false
        }
    }

    func propose(_ text: String) {
        guard connection == nil, !busy else { return }
        do { proposal = try JoinLink(text); problem = nil }
        catch { problem = error.localizedDescription }
    }

    func join() {
        guard let link = proposal else { return }
        join(link)
    }

    private func join(_ link: JoinLink) {
        guard !busy else { return }
        guard restore(), let identity else { proposal = nil; return }
        guard connection == nil else {
            proposal = nil; problem = "Leave or forget your saved computer before joining another."
            return
        }
        busy = true; proposal = nil; problem = nil
        joining = Task {
            defer { busy = false; joining = nil }
            // A pinned non-mutating preflight selects a reachable route before joining.
            // A lost reply never retries; a fresh confirmed link can recover the same phone key.
            let transport = PinnedTransport(pin: link.pin, phone: identity, purpose: .pairing)
            defer { transport.close() }
            do {
                let name = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
                let mac = try await transport.pair(link, name: name)
                try save(mac)
                proposal = nil; removed = false; CharacterCues.greetOnNextSight(); connect(mac)
            } catch { problem = error.localizedDescription }
        }
    }

    /// The phone's own key line, as the home's `authorized_keys` holds it.
    var sshKeyLine: String? { (try? phoneSSHKey())?.line }

    private func phoneSSHKey() throws -> PhoneSSHKey {
        if let sshKey { return sshKey }
        let key = try PhoneSSHKey.loadOrCreate()
        sshKey = key
        return key
    }

    /// Signs in to the typed address with the phone's key and joins with the link its home answers.
    func joinByAddress(_ text: String, port: String) {
        guard connection == nil, !busy, signingIn == nil else { return }
        do {
            addressJoin = AddressJoin(address: try SSHAddress(text, port: port), step: .working)
            askForLink()
        } catch { addressJoin = nil; problem = error.localizedDescription }
    }

    /// The person said this is their computer: keep the yes, then sign in.
    func trustHome() {
        guard let join = addressJoin, case .trust(let key) = join.step else { return }
        var homes = trustedHomes()
        homes.trust(key, for: join.address)
        do { try keep(homes) } catch {
            addressJoin?.problem = "Could not keep this computer’s fingerprint. Try again."
            return
        }
        askForLink()
    }

    /// Lets the phone's key in with the password, typed once, then signs in with the key.
    func sendPassword(_ password: String) {
        guard let join = addressJoin, case .keyRefused(true) = join.step, signingIn == nil, !password.isEmpty else { return }
        addressJoin?.step = .working; addressJoin?.problem = nil
        signingIn = Task {
            defer { signingIn = nil }
            do {
                try await SSHJoin.placeKey(join.address, trusted: trustedHomes().key(for: join.address),
                                           key: try phoneSSHKey(), password: password)
            } catch {
                addressJoin?.step = .keyRefused(password: true)
                addressJoin?.problem = error.localizedDescription
                return
            }
            signingIn = nil
            askForLink()
        }
    }

    func tryAddressAgain() { if addressJoin != nil { askForLink() } }

    func cancelAddressJoin() { signingIn?.cancel(); signingIn = nil; addressJoin = nil }

    private func askForLink() {
        guard let join = addressJoin, signingIn == nil else { return }
        addressJoin?.step = .working; addressJoin?.problem = nil
        signingIn = Task {
            defer { signingIn = nil }
            do {
                let link = try await SSHJoin.link(join.address, trusted: trustedHomes().key(for: join.address),
                                                  key: try phoneSSHKey())
                guard addressJoin?.address == join.address else { return }
                // The link is never shown: the phone joins with it at once, typed address first.
                addressJoin = nil; problem = nil
                self.join(link)
            } catch SSHJoinError.unknownHost(let key) {
                addressJoin?.step = .trust(key)
            } catch SSHJoinError.keyRefused(_, let password) {
                addressJoin?.step = .keyRefused(password: password)
            } catch {
                addressJoin?.step = .stopped
                addressJoin?.problem = error.localizedDescription
            }
        }
    }

    private func trustedHomes() -> TrustedHomes {
        (try? JSONDecoder().decode(TrustedHomes.self, from: Data(contentsOf: trustedURL))) ?? TrustedHomes()
    }

    private func keep(_ homes: TrustedHomes) throws {
        try FileManager.default.createDirectory(at: trustedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(homes).write(to: trustedURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    func leave() async {
        do {
            try await connection?.leave()
            forgetMac()
        } catch { problem = error.localizedDescription }
    }

    /// A local choice: no request to a Mac that may no longer exist, and no key rotation.
    func forgetMac() {
        do {
            try forget()
            connection?.stop(); connection = nil
            removed = false; proposal = nil; problem = nil
        } catch {
            problem = needsUnlock(error) ? "Could not forget this computer. Unlock your phone and try again."
                : "Could not forget this computer. Try again."
        }
    }

    func active(_ active: Bool) {
        foreground = active
        if active { endBackgroundTime(); _ = restore(); nearby.start(); connection?.start() }
        else { nearby.stop(); keepThroughBackgroundTime() }
    }

    /// INF-1528: a short trip away keeps the connection, so the app comes back in reach. It stays open for the
    /// background time iOS gives the app and closes when iOS ends that time, before the app is suspended.
    private func keepThroughBackgroundTime() {
        guard connection != nil, backgroundTime == .invalid else { return }
        backgroundTime = UIApplication.shared.beginBackgroundTask(withName: "Stay in reach") { [weak self] in
            MainActor.assumeIsolated { self?.backgroundTimeEnded() }
        }
        if backgroundTime == .invalid { connection?.stop(); return }
        // The simulator never ends a background task, so the journey stands in for iOS with its own end.
        if let seconds = ProcessInfo.processInfo.environment["INFINITARY_TEST_BACKGROUND_TIME"].flatMap(Double.init) {
            let task = backgroundTime
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(seconds))
                if self?.backgroundTime == task { self?.backgroundTimeEnded() }
            }
        }
    }

    private func backgroundTimeEnded() {
        if !foreground { connection?.stop() }
        endBackgroundTime()
    }

    private func endBackgroundTime() {
        guard backgroundTime != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTime)
        backgroundTime = .invalid
    }

    private func connect(_ mac: JoinedMac) {
        guard let identity else { return }
        let session = ReadOnlySession(mac: mac, phone: identity)
        session.onMacChanged = { [weak self] mac in
            do { try self?.save(mac) } catch { self?.problem = "Could not keep this computer’s new address." }
        }
        session.onRemoved = { [weak self] in
            guard let self else { return }
            do { try forget() } catch { problem = "Could not forget this computer. Try Leave again." }
            removed = true
        }
        session.onEmote = { emote in CharacterCues.reacted(emote) }
        session.onSceneSignal = { signal in CharacterCues.signal(signal) }
        connection = session
        session.found(addresses: nearby.macs.map(\.address))
        if foreground { session.start() }
    }

    func dismissRemoved() { forgetMac() }

    private func save(_ mac: JoinedMac) throws {
        try FileManager.default.createDirectory(at: savedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(mac).write(to: savedURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        var url = savedURL
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try url.setResourceValues(values)
    }

    private func forget() throws {
        if FileManager.default.fileExists(atPath: savedURL.path) { try FileManager.default.removeItem(at: savedURL) }
    }
}
