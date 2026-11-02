import Foundation
import Observation

struct NearbyMac: Identifiable {
    let id: String
    let name: String
    let address: String
}

/// Bonjour says where to try, never who to trust. The transport still checks the saved public key.
@MainActor @Observable final class NearbyMacs: NSObject, @preconcurrency NetServiceBrowserDelegate, @preconcurrency NetServiceDelegate {
    private(set) var macs: [NearbyMac] = []
    private(set) var problem: String?
    private var browser: NetServiceBrowser?
    private var services: [NetService] = []
    var changed: (([String]) -> Void)?

    func start() {
        #if targetEnvironment(simulator)
        // The hermetic gate must never discover or try a person's real Macs.
        if ProcessInfo.processInfo.environment["INFINITARY_ISOLATED_PHONE_TEST"] == "1" { return }
        #endif
        guard browser == nil else { return }
        let browser = NetServiceBrowser()
        self.browser = browser; browser.delegate = self
        browser.searchForServices(ofType: "_infinitary._tcp.", inDomain: "local.")
    }

    func stop() {
        browser?.stop(); browser = nil
        services.forEach { $0.stop() }; services = []; macs = []; changed?([])
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        guard browser === self.browser, services.count < 16, !services.contains(service) else { return }
        services.append(service); service.delegate = self; service.resolve(withTimeout: 5)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        guard browser === self.browser else { return }
        service.stop(); services.removeAll { $0 == service }
        macs.removeAll { $0.id == service.name + service.domain }
        changed?(macs.map(\.address))
    }

    func netServiceDidResolveAddress(_ service: NetService) {
        guard services.contains(service), let host = service.hostName, service.port > 0 else { return }
        let name = service.name
        guard !name.isEmpty, name.count <= 64 else { return }
        let address = "\(host.trimmingCharacters(in: CharacterSet(charactersIn: "."))):\(service.port)"
        let id = service.name + service.domain
        macs.removeAll { $0.id == id }
        macs.append(NearbyMac(id: id, name: name, address: address)); macs.sort { $0.name < $1.name }
        problem = nil; changed?(macs.map(\.address))
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        guard browser === self.browser else { return }
        problem = "Nearby could not look on your network. Allow Local Network for Infinitary in Settings, or paste your computer’s link."
    }
}
