import Foundation
import Security
import Testing
@testable import InfinitaryKit

/// INF-1250's finding in INF-1109's PhoneSecrets: a phone that could not read its kept approval key while it was
/// locked reads that key again when the person taps Set up approvals once it is unlocked, so the computer keeps
/// the enrollment it holds instead of asking to enroll a replacement. Only a record the phone refuses is replaced.
/// The Keychain stand-in answers as the phone's Keychain does; the home stand-in answers as the home's
/// SecretsSettings.approvals and enroll do (src/core/secrets/settings.ts).
@MainActor struct PhoneSecretsTests {
    /// One computer with Secrets set up and open. It offers to enroll a key only when it does not already hold
    /// that key for that device, and says which key it holds for the device a phone names.
    @MainActor final class Home: SecretsHome {
        var enrolled: (device: String, key: String)?
        /// The uses waiting now, each as SecretsSettings.approvals describes it.
        var waiting: [[String: Any]] = []
        private(set) var offered: [String] = []

        func request<T: Decodable & Sendable>(_ channel: PhoneRequest, args: [Any], as: T.Type) async throws -> T {
            let input = try #require(args.first as? [String: Any])
            let device = try #require(input["device"] as? String)
            switch channel {
            case .secretApprovals: break
            case .secretEnroll:
                let key = try #require(input["key"] as? String)
                if enrolled?.device != device || enrolled?.key != key { offered.append(key) }
            default: throw PhoneError.invalidReply
            }
            let holds = enrolled.flatMap { $0.device == device ? $0 : nil }
            let answer: [String: Any] = [
                "availability": "available", "home": "c41a5779-70bc-400b-929d-19f4c4ed06ea",
                "device": holds.map { ["label": "iPhone", "generation": 1, "key": $0.key] as [String: Any] } ?? NSNull(),
                "offered": !offered.isEmpty, "waiting": waiting,
            ]
            return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: answer))
        }
    }

    /// The phone's approvals over a Keychain stand-in, as a simulator keeps them.
    static func secrets(_ home: Home, _ keychain: ApprovalStorageTests.Keychain) -> PhoneSecrets {
        PhoneSecrets(home: home, loadKey: { try ApprovalKey.load(on: .simulator, from: keychain) },
                     createKey: { try ApprovalKey.create(on: .simulator, in: keychain) },
                     replaceKey: { try ApprovalKey.replace($0, on: .simulator, in: keychain) })
    }

    /// INF-3042: a later successful key read removes the earlier locked-store explanation without replacing the key.
    @Test func readingAfterUnlockClearsTheObsoleteProblem() async throws {
        let keychain = ApprovalStorageTests.Keychain()
        let kept = try ApprovalKey.create(on: .simulator, in: keychain)
        let writes = keychain.writes
        let home = Home()
        home.enrolled = (kept.device, kept.publicKey)
        let secrets = Self.secrets(home, keychain)
        keychain.reading = errSecInteractionNotAllowed
        await secrets.read()
        #expect(secrets.problem == ApprovalKey.notKept)
        keychain.reading = errSecSuccess
        await secrets.read()
        #expect(secrets.key == kept)
        #expect(secrets.problem == nil)
        #expect(secrets.standing == .enrolled)
        #expect(keychain.writes == writes)
    }

    /// INF-3042: real Secrets receipt states distinguish acceptance from waiting, refusal and uncertainty.
    @Test func onlyTheRequestedDecisionIsAccepted() {
        for state in ["executing", "completed"] {
            #expect(PhoneSecrets.Outcome(state: state, allowing: true) == .accepted)
            if case .refused = PhoneSecrets.Outcome(state: state, allowing: false) {} else { Issue.record("A running use cannot be denied") }
        }
        #expect(PhoneSecrets.Outcome(state: "denied", allowing: false) == .accepted)
        for allowing in [true, false] {
            #expect(PhoneSecrets.Outcome(state: "waiting", allowing: allowing) == .stillWaiting)
            for state in ["unavailable", "expired", "cancelled", "invalidated", "unknown"] {
                if case .refused = PhoneSecrets.Outcome(state: state, allowing: allowing) {} else { Issue.record("A refused or uncertain receipt is not acceptance") }
            }
        }
        if case .refused = PhoneSecrets.Outcome(state: "denied", allowing: true) {} else { Issue.record("Denied is not Allow") }
    }

    @Test func settingUpOnceUnlockedKeepsTheEnrolledKey() async throws {
        let keychain = ApprovalStorageTests.Keychain()
        let kept = try ApprovalKey.create(on: .simulator, in: keychain)
        let record = try #require(keychain.record)
        let writes = keychain.writes
        let home = Home()
        home.enrolled = (kept.device, kept.publicKey)
        let secrets = Self.secrets(home, keychain)

        // The phone is locked when it first reads: it holds no key, so Settings offers Set up approvals.
        keychain.reading = errSecInteractionNotAllowed
        await secrets.read()
        #expect(secrets.key == nil)
        #expect(secrets.standing == .none)
        #expect(secrets.problem == ApprovalKey.notKept)

        // Still locked: the tap says so, and nothing is written or offered.
        await secrets.setUp(label: "iPhone")
        #expect(secrets.problem == ApprovalKey.notKept)
        #expect(keychain.writes == writes)
        #expect(home.offered.isEmpty)

        // Unlocked: the tap reads the kept key, and the computer still holds it.
        keychain.reading = errSecSuccess
        await secrets.setUp(label: "iPhone")
        #expect(secrets.problem == nil)
        #expect(secrets.key == kept)
        #expect(secrets.standing == .enrolled)
        #expect(home.offered.isEmpty, "The computer asks to enroll nothing new")
        #expect(keychain.writes == writes, "The kept key is not replaced")
        #expect(keychain.record == record)
    }

    @Test func settingUpReplacesARecordThePhoneRefuses() async throws {
        // A software record on a physical device is refused for good, not unreadable for now.
        let keychain = ApprovalStorageTests.Keychain()
        let kept = try ApprovalKey.create(on: .simulator, in: keychain)
        let writes = keychain.writes
        let home = Home()
        home.enrolled = (kept.device, kept.publicKey)
        // This Mac reaches no Secure Enclave, so a simulator key stands in for the device's new one.
        let secrets = PhoneSecrets(home: home, loadKey: { try ApprovalKey.load(on: .device, from: keychain) },
                                   createKey: { try ApprovalKey.create(on: .simulator, in: keychain) },
                                   replaceKey: { try ApprovalKey.replace($0, on: .simulator, in: keychain) })

        await secrets.read()
        #expect(secrets.key == nil)
        #expect(secrets.problem == ApprovalKey.unusable)

        await secrets.setUp(label: "iPhone")
        let replacement = try #require(secrets.key)
        #expect(secrets.problem == nil)
        #expect(replacement.device == kept.device)
        #expect(replacement.publicKey != kept.publicKey)
        #expect(keychain.writes == writes + 1)
        #expect(home.offered == [replacement.publicKey])
        #expect(secrets.standing == .offered)
    }

    /// INF-1109's decision on a damaged record: Settings says so and offers Set up approvals again, and only that
    /// choice replaces the record. The new key takes a new device name, so the computer asks for its code
    /// comparison and confirmation as for a first key, and the earlier enrollment stays on the computer.
    @Test func onlySetUpApprovalsAgainReplacesADamagedRecord() async throws {
        let keychain = ApprovalStorageTests.Keychain()
        let kept = try ApprovalKey.create(on: .simulator, in: keychain)
        let damaged = try #require(keychain.record).prefix(20)
        keychain.record = damaged
        let writes = keychain.writes
        let home = Home()
        home.enrolled = (kept.device, kept.publicKey)
        let secrets = Self.secrets(home, keychain)

        await secrets.read()
        #expect(secrets.standing == .damaged)
        #expect(secrets.key == nil)
        #expect(secrets.problem == nil, "A damaged record is not a phone to unlock")

        // Set up approvals refuses the damaged record: nothing is written or offered.
        await secrets.setUp(label: "iPhone")
        #expect(secrets.standing == .damaged)
        #expect(secrets.problem == nil)
        #expect(keychain.writes == writes)
        #expect(keychain.record == damaged)
        #expect(home.offered.isEmpty)

        await secrets.setUpAgain(label: "iPhone")
        let fresh = try #require(secrets.key)
        #expect(secrets.problem == nil)
        #expect(fresh.device != kept.device)
        #expect(keychain.writes == writes + 1)
        #expect(try ApprovalKey.load(on: .simulator, from: keychain) == fresh)
        #expect(home.offered == [fresh.publicKey], "The computer asks to enroll the new key")
        #expect(secrets.standing == .offered)
        #expect(home.enrolled?.device == kept.device, "The earlier enrollment stays on the computer")
    }

    @Test func aRefusedSetUpAgainKeepsTheDamagedRecord() async throws {
        let keychain = ApprovalStorageTests.Keychain()
        _ = try ApprovalKey.create(on: .simulator, in: keychain)
        let damaged = try #require(keychain.record).prefix(20)
        keychain.record = damaged
        let writes = keychain.writes
        let home = Home()
        let secrets = Self.secrets(home, keychain)
        await secrets.read()
        #expect(secrets.standing == .damaged)

        // A write that fails leaves the damaged bytes, and Settings still offers the same choice.
        keychain.writing = errSecInteractionNotAllowed
        await secrets.setUpAgain(label: "iPhone")
        #expect(secrets.problem == ApprovalKey.notKept)
        #expect(secrets.standing == .damaged)
        #expect(secrets.key == nil)
        #expect(keychain.record == damaged)
        #expect(keychain.writes == writes + 1)
        #expect(home.offered.isEmpty)

        // Locked by the time of the tap: nothing is written, and the damaged record stays.
        keychain.writing = errSecSuccess
        keychain.reading = errSecInteractionNotAllowed
        await secrets.setUpAgain(label: "iPhone")
        #expect(secrets.problem == ApprovalKey.notKept)
        #expect(secrets.standing == .damaged)
        #expect(keychain.record == damaged)
        #expect(keychain.writes == writes + 1)
        #expect(home.offered.isEmpty)
    }

    @Test func aPhoneThatCannotReadItsRecordNeverOffersToSetUpAgain() async throws {
        let keychain = ApprovalStorageTests.Keychain()
        _ = try ApprovalKey.create(on: .simulator, in: keychain)
        let damaged = try #require(keychain.record).prefix(20)
        keychain.record = damaged
        keychain.reading = errSecInteractionNotAllowed
        let writes = keychain.writes
        let home = Home()
        let secrets = Self.secrets(home, keychain)

        await secrets.read()
        #expect(secrets.standing == .none)
        #expect(secrets.damage == nil)
        #expect(secrets.problem == ApprovalKey.notKept)
        await secrets.setUpAgain(label: "iPhone")
        await secrets.setUp(label: "iPhone")
        #expect(secrets.problem == ApprovalKey.notKept)
        #expect(secrets.standing == .none)
        #expect(keychain.writes == writes)
        #expect(keychain.record == damaged)
        #expect(home.offered.isEmpty)
    }

    /// INF-1109, the captain: "right now it's not even clear what secrets are being requested". Two secrets the
    /// captain gave the same name stay apart, by environment and reference, wherever the phone names a use,
    /// including the confirmation the system shows before the key signs, and a reading that leaves out a secret's
    /// reference shows no use at all.
    @Test func aWaitingUseNamesEachSecretByItsReference() async throws {
        let home = Home()
        let use: [String: Any] = [
            "request": "use-7f3a", "card": "card-secrets-use-7f3a", "digest": "5b0c1d", "expires": 1792900300000,
            "nonce": NSNull(), "reason": "Publish the staging build", "recipient": "Staging deploy check",
            "secrets": [
                ["ref": "github-token-2", "label": "GitHub token", "version": 3, "environment": "Production"],
                ["ref": "github-token", "label": "GitHub token", "version": 1, "environment": "Staging"],
                ["ref": "notes", "label": "Notes key", "version": 2, "environment": ""],
            ],
            "facts": [["name": "Destination", "value": "https://deploy.example.test/status"]],
        ]
        home.waiting = [use]
        let secrets = Self.secrets(home, ApprovalStorageTests.Keychain())
        await secrets.read()
        let read = try #require(secrets.use(card: "card-secrets-use-7f3a"))
        #expect(read.secrets.map(\.named) == ["GitHub token (Production, github-token-2, version 3)",
                                              "GitHub token (Staging, github-token, version 1)", "Notes key (notes, version 2)"])
        #expect(read.giving == "Give GitHub token (Production, github-token-2, version 3), GitHub token (Staging, github-token, version 1), Notes key (notes, version 2) to Staging deploy check once")

        var unnamed = use
        unnamed["secrets"] = [["label": "GitHub token", "version": 3, "environment": "Production"]]
        home.waiting = [unnamed]
        await secrets.read()
        #expect(secrets.approvals == nil)
        #expect(secrets.use(card: "card-secrets-use-7f3a") == nil)
    }
}
