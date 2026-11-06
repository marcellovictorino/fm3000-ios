import XCTest

/// The relaunch-first part (scripts/phone-test-plan.ts): its test and the steps only it takes.
extension PhoneJourney {
    /// The relaunch parts: INF-1735's 20 dark/light relaunch pairs, each lighting Tasks with one press.
    /// Their own parts, so the talk part keeps room within its 20-minute allowance on a loaded Mac (INF-1878); INF-2125
    /// direction C runs them as two tests of ten pairs, so a pull request's check can afford one.
    /// Data: the hero card, the on-request harbour task and a sent captain ask, so each launch restores a last turn.
    /// Completion: every pair draws the requested appearance, then lights Tasks and shows its list after a single press.
    /// Resources: this part's own fresh simulator and home; no photo, signing material or real account.
    func testRelaunchPairsFirstTen() async throws {
        _ = try await launchWithLastTurn()
        try await relaunchPairs(soakPairs)
    }
}
