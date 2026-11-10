import CryptoKit
import Foundation
import Testing
@testable import InfinitaryKit

/// INF-1109's "phone's approval screen for remote decisions", built by INF-1202: the phone signs the exact
/// bytes the home checks and shows the code the home's card shows. Fixtures/secrets.json is a real challenge
/// from the home's SecretsSettings, signed here; the home's own verifier passes it in src/core/secrets/approvals.test.ts.
struct ApprovalTests {
    private struct Fields: Decodable {
        let home: String; let device: String; let generation: Int; let request: String
        let digest: String; let nonce: String; let expires: Int64
    }
    private struct Fixture: Decodable { let fields: Fields; let message: String; let key: String; let signature: String; let code: String }
    private func fixture() throws -> Fixture {
        let url = Bundle.module.url(forResource: "secrets", withExtension: "json", subdirectory: "Fixtures")!
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }
    private func message(_ fields: Fields) -> String {
        PhoneDecision.message(home: fields.home, device: fields.device, generation: fields.generation,
            request: fields.request, digest: fields.digest, nonce: fields.nonce, expires: fields.expires)
    }

    @Test func buildsTheMessageTheHomeChecks() throws {
        let sample = try fixture()
        #expect(message(sample.fields) == sample.message)
        let key = try P256.Signing.PublicKey(derRepresentation: try #require(Data(base64Encoded: sample.key)))
        let signature = try P256.Signing.ECDSASignature(derRepresentation: try #require(Data(base64Encoded: sample.signature)))
        #expect(key.isValidSignature(signature, for: Data(sample.message.utf8)))
    }

    @Test func showsTheCodeTheHomeShows() throws {
        let sample = try fixture()
        #expect(ApprovalKey.code(of: sample.key) == sample.code)
        #expect(ApprovalKey.code(of: "not base64") == nil)
    }

    @Test func signsWithTheKeyItOffers() async throws {
        let sample = try fixture()
        let key = try ApprovalKey(device: sample.fields.device, signer: .software(P256.Signing.PrivateKey().rawRepresentation))
        let offered = try P256.Signing.PublicKey(derRepresentation: try #require(Data(base64Encoded: key.publicKey)))
        let signed = try await key.sign(message(sample.fields), reason: "Give Planning calendar (version 1) to Google Calendar once")
        let signature = try P256.Signing.ECDSASignature(derRepresentation: try #require(Data(base64Encoded: signed)))
        #expect(offered.isValidSignature(signature, for: Data(sample.message.utf8)))
        #expect(!offered.isValidSignature(signature, for: Data(sample.message.replacingOccurrences(of: "decision:allow", with: "decision:deny").utf8)))
        #expect(key.code.count == 9 && key.code != sample.code)
    }
}
