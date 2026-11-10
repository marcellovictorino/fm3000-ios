import Foundation
import LocalAuthentication
import Testing
@testable import InfinitaryKit

/// INF-1109: the captain asks for the native error in a failed approval journey, never a successful refusal.
struct ApprovalAuthenticationTests {
    @Test func isolatedRefusalKeepsTheObservedNativeFailure() throws {
        // The earlier retained native failure was LAError -1000: UI activation timed out after 5 seconds.
        // Its absence from the later run's generic refusal is an evidence gap, not proof of the same cause.
        let failure = NSError(domain: LAError.errorDomain, code: -1000,
            userInfo: [NSLocalizedDescriptionKey: "UI activation timed out after 5 seconds"])
        let refusal = ApprovalKey.confirmationFailure(failure, isolatedPhoneTest: true)
        guard case .refused(let words) = refusal else {
            Issue.record("An authentication failure must remain a refusal")
            return
        }
        #expect(words == "\(ApprovalKey.notConfirmed) LocalAuthentication: domain=\(failure.domain), code=\(failure.code), description=\(failure.localizedDescription)")
    }

    @Test func ordinaryRefusalKeepsItsPlainWords() {
        let failure = LAError(.authenticationFailed)
        let refusal = ApprovalKey.confirmationFailure(failure, isolatedPhoneTest: false)
        #expect(refusal.errorDescription == ApprovalKey.notConfirmed)
    }
}
