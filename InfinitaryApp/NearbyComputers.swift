import Foundation
import Network
import Observation

/// INF-1312: a computer on this network that takes a sign-in, announced with Remote Login on or answering the sweep.
struct NearbyComputer: Identifiable, Equatable {
    var id: String { "\(host):\(port)" }
    let name: String
    let host: String
    let port: Int
    /// Found by the sweep the person asked for, rather than announced.
    var swept = false
}

/// INF-1312: Join by its address lists the computers on this network with Remote Login on (`_ssh._tcp`), as the Mac's
/// own By its address list does (`src/shared/nearbyMacs.ts`), while its sheet is open and the app is in front.
/// Only on the person's yes does it also try each address on this network for a sign-in banner.
/// Like Nearby on the welcome screen, it says where to try, never who to trust: the sign-in still asks for the fingerprint.
@MainActor @Observable final class NearbyComputers: NSObject, @preconcurrency NetServiceDelegate {
    enum Looking: Equatable { case looking, notAllowed, failed }
    enum Sweep: Equatable { case idle, sweeping(addresses: Int), done, noNetwork }

    private(set) var looking: Looking = .looking
    private(set) var sweep: Sweep = .idle
    private(set) var announced: [NearbyComputer] = []
    private(set) var answered: [NearbyComputer] = []
    /// Announced computers first, then each swept address no announcement already resolved to.
    var computers: [NearbyComputer] {
        let addresses = announcedAddresses, ids = Set(announced.map(\.id))
        return announced + answered.filter { !addresses.contains($0.host) && !ids.contains($0.id) }
    }

    private var browser: NWBrowser?
    private var services: [NetService] = []
    private var resolvedAddresses: [String: [String]] = [:]
    private var announcedAddresses: Set<String> { Set(resolvedAddresses.values.joined()) }
    private var sweeping: Task<Void, Never>?

    /// The isolated phone gate never looks on a real network: it names one stand-in computer and the addresses to sweep.
    private static var isolated: Bool {
        #if targetEnvironment(simulator)
        ProcessInfo.processInfo.environment["INFINITARY_ISOLATED_PHONE_TEST"] == "1"
        #else
        false
        #endif
    }

    func start() {
        guard browser == nil, announced.isEmpty else { return }
        if Self.isolated {
            // `name|host|port`, the test home's own sshd.
            let parts = (ProcessInfo.processInfo.environment["INFINITARY_TEST_NEARBY_SSH"] ?? "").split(separator: "|").map(String.init)
            if parts.count == 3, let port = Int(parts[2]) { announced = [NearbyComputer(name: parts[0], host: parts[1], port: port)] }
            return
        }
        let browser = NWBrowser(for: .bonjour(type: "_ssh._tcp", domain: "local."), using: .tcp)
        self.browser = browser
        browser.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in self?.browserState(state, of: browser) }
        }
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            let names = results.compactMap { result -> String? in
                if case .service(let name, _, _, _) = result.endpoint { return name }
                return nil
            }
            Task { @MainActor in self?.found(names, by: browser) }
        }
        browser.start(queue: .main)
    }

    func stop() {
        browser?.cancel(); browser = nil
        services.forEach { $0.stop() }; services = []
        sweeping?.cancel(); sweeping = nil
        announced = []; answered = []; resolvedAddresses = [:]
        looking = .looking; sweep = .idle
    }

    private func browserState(_ state: NWBrowser.State, of browser: NWBrowser) {
        guard browser === self.browser else { return }
        switch state {
        case .ready: looking = .looking
        // kDNSServiceErr_PolicyDenied: iOS has not let the app use the local network.
        case .waiting(.dns(-65570)), .failed(.dns(-65570)): looking = .notAllowed
        case .failed: looking = .failed
        default: break
        }
    }

    private func found(_ names: [String], by browser: NWBrowser) {
        guard browser === self.browser else { return }
        looking = .looking
        let kept = Set(names)
        for service in services where !kept.contains(service.name) { service.stop() }
        services.removeAll { !kept.contains($0.name) }
        announced.removeAll { !kept.contains($0.name) }
        resolvedAddresses = resolvedAddresses.filter { kept.contains($0.key) }
        for name in names where !services.contains(where: { $0.name == name }) && services.count < 32 {
            let service = NetService(domain: "local.", type: "_ssh._tcp.", name: name)
            services.append(service); service.delegate = self; service.resolve(withTimeout: 5)
        }
    }

    func netServiceDidResolveAddress(_ service: NetService) {
        guard services.contains(service), let host = service.hostName, service.port > 0,
              !service.name.isEmpty, service.name.count <= 64 else { return }
        let computer = NearbyComputer(name: service.name, host: host.trimmingCharacters(in: CharacterSet(charactersIn: ".")), port: service.port)
        announced.removeAll { $0.name == service.name }
        announced.append(computer); announced.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        resolvedAddresses[service.name] = (service.addresses ?? []).compactMap(Self.ipv4)
    }

    /// The person said yes: try each address on this phone's own private network for a sign-in banner.
    func sweepNetwork() {
        guard sweeping == nil, sweep != .done else { return }
        let targets: [(String, UInt16)]
        if Self.isolated {
            targets = (ProcessInfo.processInfo.environment["INFINITARY_TEST_SWEEP"] ?? "").split(separator: ",").compactMap { entry in
                let parts = entry.split(separator: ":")
                guard parts.count == 2, let port = UInt16(parts[1]) else { return nil }
                return (String(parts[0]), port)
            }
        } else {
            targets = Self.localAddresses().map { ($0, 22) }
        }
        guard !targets.isEmpty else { sweep = .noNetwork; return }
        sweep = .sweeping(addresses: targets.count)
        sweeping = Task {
            await withTaskGroup(of: (String, UInt16)?.self) { group in
                var next = targets.makeIterator()
                // A few at a time, so the sweep stays a gentle one on someone's network.
                for _ in 0..<24 { if let target = next.next() { group.addTask { await Self.answersSignIn(target) ? target : nil } } }
                for await hit in group {
                    if Task.isCancelled { group.cancelAll(); return }
                    if let (host, port) = hit {
                        answered.append(NearbyComputer(name: host, host: host, port: Int(port), swept: true))
                        answered.sort { $0.host.localizedStandardCompare($1.host) == .orderedAscending }
                    }
                    if let target = next.next() { group.addTask { await Self.answersSignIn(target) ? target : nil } }
                }
            }
            guard !Task.isCancelled else { return }
            sweeping = nil; sweep = .done
        }
    }

    /// Whether an address answers on its port with an SSH banner (`SSH-`), within a few seconds.
    nonisolated private static func answersSignIn(_ target: (String, UInt16)) async -> Bool {
        guard let port = NWEndpoint.Port(rawValue: target.1) else { return false }
        let tcp = NWProtocolTCP.Options(); tcp.connectionTimeout = 2
        let connection = NWConnection(host: NWEndpoint.Host(target.0), port: port, using: NWParameters(tls: nil, tcp: tcp))
        let queue = DispatchQueue(label: "infinitary.sweep")
        return await withCheckedContinuation { continuation in
            let answer = Answer(continuation, connection)
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.receive(minimumIncompleteLength: 4, maximumLength: 255) { data, _, _, _ in
                        answer.give(data.map { $0.starts(with: Data("SSH-".utf8)) } ?? false)
                    }
                case .waiting, .failed, .cancelled: answer.give(false)
                default: break
                }
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + 3) { answer.give(false) }
        }
    }

    /// One answer per address, whichever of the banner, a refusal or the deadline comes first.
    private final class Answer: @unchecked Sendable {
        private let lock = NSLock()
        private var continuation: CheckedContinuation<Bool, Never>?
        private let connection: NWConnection
        init(_ continuation: CheckedContinuation<Bool, Never>, _ connection: NWConnection) {
            self.continuation = continuation; self.connection = connection
        }
        func give(_ value: Bool) {
            lock.lock(); let waiting = continuation; continuation = nil; lock.unlock()
            guard let waiting else { return }
            connection.cancel(); waiting.resume(returning: value)
        }
    }

    /// The other addresses of this phone's own private IPv4 network, at most the 254 around it.
    nonisolated private static func localAddresses() -> [String] {
        var list: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&list) == 0, let first = list else { return [] }
        defer { freeifaddrs(list) }
        for entry in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let flags = Int32(entry.pointee.ifa_flags)
            guard String(cString: entry.pointee.ifa_name).hasPrefix("en"), flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0,
                  let address = entry.pointee.ifa_addr, address.pointee.sa_family == UInt8(AF_INET),
                  let netmask = entry.pointee.ifa_netmask else { continue }
            let own = address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { UInt32(bigEndian: $0.pointee.sin_addr.s_addr) }
            var mask = netmask.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { UInt32(bigEndian: $0.pointee.sin_addr.s_addr) }
            // Only a private network: 10/8, 172.16/12 and 192.168/16.
            guard own >> 24 == 10 || own >> 20 == 0xAC1 || own >> 16 == 0xC0A8 else { continue }
            mask = max(mask, 0xFFFF_FF00)
            let network = own & mask, broadcast = network | ~mask
            guard broadcast > network + 1 else { continue }
            return (network + 1..<broadcast).filter { $0 != own }.map { value in
                "\(value >> 24).\(value >> 16 & 0xFF).\(value >> 8 & 0xFF).\(value & 0xFF)"
            }
        }
        return []
    }

    nonisolated private static func ipv4(_ data: Data) -> String? {
        data.withUnsafeBytes { raw -> String? in
            guard raw.count >= MemoryLayout<sockaddr_in>.size,
                  let base = raw.baseAddress, base.assumingMemoryBound(to: sockaddr.self).pointee.sa_family == UInt8(AF_INET) else { return nil }
            let value = UInt32(bigEndian: base.assumingMemoryBound(to: sockaddr_in.self).pointee.sin_addr.s_addr)
            return "\(value >> 24).\(value >> 16 & 0xFF).\(value >> 8 & 0xFF).\(value & 0xFF)"
        }
    }
}
