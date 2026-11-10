import Foundation
import Observation

/// What the home says of this phone's Secrets approvals (`inf:secrets:approvals`).
public struct PhoneApprovals: Decodable, Sendable, Equatable {
    public struct Enrollment: Decodable, Sendable, Equatable {
        public let label: String
        public let generation: Int
        /// The approval key the home holds for this phone, SPKI DER, base64.
        public let key: String
    }
    /// One requested secret as the use prepared it: the captain's own name for it, the environment label and
    /// reference that tell two secrets with the same name apart, and the version this use reads. Never its value.
    public struct Secret: Decodable, Sendable, Equatable {
        public let ref: String
        public let label: String
        public let version: Int
        /// The captain's own label for where it belongs, such as Staging; empty when they gave none.
        public let environment: String
        /// What tells it apart, after its name: the environment when there is one, the reference and version.
        public var detail: [String] { (environment.isEmpty ? [] : [environment]) + [ref, "version \(version)"] }
        /// How the phone names it wherever it asks: the name first, then what tells it apart.
        public var named: String { "\(label) (\(detail.joined(separator: ", ")))" }
    }
    public struct Fact: Decodable, Sendable, Equatable { public let name: String; public let value: String }
    /// One waiting use, described as the home's approval card describes it.
    public struct Use: Decodable, Sendable, Equatable, Identifiable {
        public let request: String
        public let card: String?
        public let digest: String
        public let expires: Int64
        public let nonce: String?
        public let reason: String
        public let recipient: String
        public let secrets: [Secret]
        public let facts: [Fact]
        public var id: String { request }
        /// The sentence the system's confirmation shows, naming exactly what this Allow gives.
        public var giving: String {
            "Give \(secrets.map(\.named).joined(separator: ", ")) to \(recipient) once"
        }
    }
    public let availability: String
    public let home: String?
    public let device: Enrollment?
    public let offered: Bool
    public let waiting: [Use]
}

/// This phone's side of Secrets approvals: its key, its enrollment on the home and its decisions. The home
/// decides; the phone only offers its key, signs an Allow the person confirmed, or refuses.
@MainActor @Observable public final class PhoneSecrets {
    public private(set) var approvals: PhoneApprovals?
    public private(set) var key: ApprovalKey?
    /// The damaged record this phone last read in place of a key, which only `setUpAgain` replaces.
    public private(set) var damage: ApprovalKey.Damage?
    public private(set) var problem: String?
    public private(set) var busy = false
    @ObservationIgnored private let session: any SecretsHome
    @ObservationIgnored private let loadKey: () throws -> ApprovalKey?
    @ObservationIgnored private let createKey: () throws -> ApprovalKey
    @ObservationIgnored private let replaceKey: (ApprovalKey.Damage) throws -> ApprovalKey
    @ObservationIgnored private var loaded = false
    @ObservationIgnored private var reading = 0

    public convenience init(session: ReadOnlySession, loadKey: @escaping () throws -> ApprovalKey? = ApprovalKey.load,
                            createKey: @escaping () throws -> ApprovalKey = ApprovalKey.create,
                            replaceKey: @escaping (ApprovalKey.Damage) throws -> ApprovalKey = ApprovalKey.replace) {
        self.init(home: session, loadKey: loadKey, createKey: createKey, replaceKey: replaceKey)
    }

    init(home: any SecretsHome, loadKey: @escaping () throws -> ApprovalKey?, createKey: @escaping () throws -> ApprovalKey,
         replaceKey: @escaping (ApprovalKey.Damage) throws -> ApprovalKey) {
        self.session = home; self.loadKey = loadKey; self.createKey = createKey; self.replaceKey = replaceKey
    }

    public enum Standing: Equatable { case unavailable, none, damaged, offered, enrolled, replaced }
    /// Where this phone stands: enrolled only while the home holds this phone's own key, and nothing to set
    /// up until Secrets on the computer is set up and open.
    public var standing: Standing {
        guard let approvals, approvals.availability == "available" else { return .unavailable }
        if key == nil, damage != nil { return .damaged }
        if approvals.offered { return .offered }
        guard let enrolled = approvals.device else { return .none }
        return enrolled.key == key?.publicKey ? .enrolled : .replaced
    }

    /// The waiting use the home raised this card for, if it is one.
    public func use(card: String) -> PhoneApprovals.Use? { approvals?.waiting.first { $0.card == card } }

    /// Reads the home's answer again. A home without phone approvals refuses the read, and the phone shows none.
    public func read() async {
        if !loaded { loadKept() }
        reading += 1
        let current = reading
        do {
            let answer = try await session.request(.secretApprovals, args: [["device": key?.device ?? Self.unenrolled]], as: PhoneApprovals.self)
            if current == reading { approvals = answer }
        } catch {
            if current == reading { approvals = nil }
        }
    }

    /// Offers this phone's key to the home, which asks the captain to compare the code and confirm there.
    /// A phone whose enrollment the home no longer holds offers a new key. A kept key the phone could not read
    /// before, as while it was locked, is read again first, so the home keeps the enrollment it holds.
    public func setUp(label: String) async {
        guard !busy else { return }
        busy = true; problem = nil
        defer { busy = false }
        do {
            if key == nil, !loaded { key = try keptKey(); damage = nil; loaded = true }
            if key == nil || standing == .replaced { key = try createKey(); loaded = true }
            try await offer(label: label)
        } catch PhoneError.damagedApproval(let found) { damage = found }
        catch { problem = error.localizedDescription }
    }

    /// Set up approvals again, the person's choice for a damaged record. Only the damaged record this phone
    /// read is replaced, by a new key under a new device name, which the home enrolls like a first key: the
    /// person compares its code and confirms on the computer. An earlier enrollment the home holds stays
    /// there, and nothing it allowed carries over. When the replacement is refused, the phone reads its
    /// record again and shows what it keeps now.
    public func setUpAgain(label: String) async {
        guard !busy, let damage else { return }
        busy = true; problem = nil
        defer { busy = false }
        do {
            key = try replaceKey(damage)
        } catch {
            let refusal = error.localizedDescription
            loaded = false
            await read()
            problem = refusal
            return
        }
        self.damage = nil; loaded = true
        do { try await offer(label: label) } catch { problem = error.localizedDescription }
    }

    private func offer(label: String) async throws {
        guard let key else { return }
        approvals = try await session.request(.secretEnroll, args: [["device": key.device, "label": label, "key": key.publicKey]], as: PhoneApprovals.self)
    }

    /// Reads the kept key. A damaged record is its own state and is kept as it is; any other failure is a
    /// problem to show, never an absence.
    private func loadKept() {
        do { key = try loadKey(); damage = nil; loaded = true; problem = nil }
        catch PhoneError.damagedApproval(let found) { key = nil; damage = found; problem = nil }
        catch { problem = error.localizedDescription }
    }

    /// The key this phone keeps, or nil when it keeps none or only a record it refuses, which a new key replaces.
    /// A Keychain it cannot read now is an error, never a reason to replace the key, and so is a damaged record.
    private func keptKey() throws -> ApprovalKey? {
        do { return try loadKey() } catch PhoneError.unusableApproval { return nil }
    }

    /// The result of one decision, in the words the phone shows.
    public enum Outcome: Equatable {
        case accepted, stillWaiting, refused(String)

        /// A receipt is not acceptance of a different choice, nor permission to repeat an uncertain use.
        init(state: String, allowing: Bool) {
            if (allowing && ["executing", "completed"].contains(state)) || (!allowing && state == "denied") {
                self = .accepted
            } else if state == "waiting" {
                self = .stillWaiting
            } else {
                let words: String
                switch state {
                case "unavailable": words = "Protected storage is unavailable. Your decision was not accepted."
                case "expired": words = "This request expired. Your decision was not accepted."
                case "denied": words = "This request was denied. Nothing was allowed."
                case "cancelled", "invalidated": words = "This request is no longer available. Your decision was not accepted."
                case "executing", "completed": words = "This use already started. It could not be denied."
                default: words = "The result is unknown. Check what happened on your computer before requesting another use."
                }
                self = .refused(words)
            }
        }
    }

    /// Allows one use: the person confirms now, and the signature covers this home, request, digest,
    /// challenge, expiry and decision. Nothing is sent when the confirmation fails.
    public func allow(_ use: PhoneApprovals.Use) async throws -> Outcome {
        guard let key, standing == .enrolled, let enrolled = approvals?.device, let home = approvals?.home, let nonce = use.nonce
        else { throw PhoneError.refused("Set up approvals in Settings first.") }
        let message = PhoneDecision.message(home: home, device: key.device, generation: enrolled.generation,
            request: use.request, digest: use.digest, nonce: nonce, expires: use.expires)
        let signature = try await key.sign(message, reason: use.giving)
        return try await decide(["kind": "allow", "request": use.request, "device": key.device,
            "generation": enrolled.generation, "nonce": nonce, "signature": signature])
    }

    /// Refuses one use. A refusal needs no key.
    public func deny(_ use: PhoneApprovals.Use) async throws -> Outcome {
        try await decide(["kind": "deny", "request": use.request])
    }

    private func decide(_ decision: [String: Any]) async throws -> Outcome {
        struct Decided: Decodable { let state: String }
        let decided = try await session.request(.secretDecide, args: [decision], as: Decided.self)
        await read()
        return Outcome(state: decided.state, allowing: decision["kind"] as? String == "allow")
    }

    /// A device name no phone keeps, for reading before this phone has a key.
    static let unenrolled = "unenrolled"
}

/// What this phone's approvals ask of the home: the session to the joined computer. Tests give a stand-in home.
@MainActor protocol SecretsHome: AnyObject {
    func request<T: Decodable & Sendable>(_ channel: PhoneRequest, args: [Any], as: T.Type) async throws -> T
}

extension ReadOnlySession: SecretsHome {}
