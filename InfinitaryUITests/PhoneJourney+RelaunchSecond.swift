import XCTest

/// The relaunch-second part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// The second ten of INF-1735's 20 pairs, from its own fresh home as the first ten.
    func testRelaunchPairsSecondTen() async throws {
        _ = try await launchWithLastTurn()
        try await relaunchPairs(soakPairs)
    }
}
