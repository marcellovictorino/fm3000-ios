import Foundation
import Network
import Security

public enum DialError: Error, LocalizedError, Equatable {
    /// The Mac's key did not hash to the pin in the link. Nothing was sent.
    case homeKeyMismatch
    case unreachable(String)
    case timedOut

    public var errorDescription: String? {
        switch self {
        case .homeKeyMismatch: return "That is not your Mac: its key does not match the link. Nothing was sent."
        case .unreachable(let why): return "Could not reach your Mac (\(why)). Is Tailscale on?"
        case .timedOut: return "Your Mac did not answer."
        }
    }
}

/// Collects what the pin check saw, since a failed handshake alone does not say why.
final class PinCheck: @unchecked Sendable {
    private let lock = NSLock()
    private var _mismatch = false
    private var _tlsVersion: String?
    var mismatch: Bool { lock.lock(); defer { lock.unlock() }; return _mismatch }
    func fail() { lock.lock(); _mismatch = true; lock.unlock() }
}

enum PinnedTLS {
    /// TLS 1.3 only, no resumption, the device's own certificate offered, and the Mac trusted only
    /// when its public key hashes to `homePin` (docs/devices.md, "Joining"). The certificate's
    /// name and dates are never read.
    static func options(homePin: String, identity: DeviceIdentity, check: PinCheck) -> NWProtocolTLS.Options {
        let tls = NWProtocolTLS.Options()
        let sec = tls.securityProtocolOptions
        sec_protocol_options_set_min_tls_protocol_version(sec, .TLSv13)
        sec_protocol_options_set_max_tls_protocol_version(sec, .TLSv13)
        sec_protocol_options_set_tls_resumption_enabled(sec, false)
        if let local = sec_identity_create(identity.identity) {
            sec_protocol_options_set_local_identity(sec, local)
        }
        sec_protocol_options_set_verify_block(sec, { _, trust, complete in
            let secTrust = sec_trust_copy_ref(trust).takeRetainedValue()
            let chain = SecTrustCopyCertificateChain(secTrust) as? [SecCertificate]
            guard let leaf = chain?.first, Pin.ofCertificate(leaf) == homePin else {
                check.fail()
                complete(false)
                return
            }
            complete(true)
        }, DispatchQueue(label: "fm3000.pin"))
        return tls
    }
}
