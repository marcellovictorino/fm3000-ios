import Foundation
import Testing
@testable import InfinitaryKit

/// INF-1879: Done answers a saved answer, the question's explicit ending answers it, and hiding does neither.
/// INF-3108: that ending is Decline, the captain's answer no to every choice, so it closes as answered.
/// INF-2553's intent owner must preserve that distinction after the conflict update.
/// These pure folds use the existing home-shaped task-facts readings; the device journey owns the writes.
struct CardLeaveIntentTests {
    private struct Fixture: Decodable {
        let cases: [Entry]
        struct Entry: Decodable { let name: String; let row: PhoneTask }
    }

    private func reading(_ name: String) throws -> PhoneTask {
        let url = try #require(Bundle.module.url(forResource: "PhoneTaskFacts.generated", withExtension: "json", subdirectory: "Fixtures"))
        let fixture = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
        return try #require(fixture.cases.first { $0.name == name }?.row)
    }

    @Test(arguments: PhoneTaskEnding.allCases)
    func theExplicitEndingShowsWithoutEditingTheHomeReading(_ ending: PhoneTaskEnding) throws {
        let before = try reading("a decision card is ready")
        var ledger = PhoneIntentLedger()
        ledger.add(.finish(task: before.id, ending: ending))
        let shown = PhoneIntentFold.task(before, ledger.intents)
        #expect(before.state == "Waiting on you")
        switch ending {
        case .answerDone, .dismissQuestion:
            #expect(shown.status == "done" && shown.closedReason == "answered" && shown.state == "Done")
        }
        #expect(before.status == "active" && before.closedReason == nil)
        #expect(ledger.intents.first?.taskID == before.id)
        #expect(ledger.saw(.task(before), welcome: 1).isEmpty && !ledger.isEmpty)
        _ = ledger.drop(try #require(ledger.intents.first?.id))
        #expect(PhoneIntentFold.task(before, ledger.intents).status == before.status)
    }

    @Test func doneWaitsForTheHomesAnsweredReading() throws {
        let before = try reading("working before its record answers")
        var ledger = PhoneIntentLedger()
        let id = ledger.add(.finish(task: before.id, ending: .answerDone))
        ledger.accept(id)
        #expect(ledger.saw(.task(before), welcome: 1).isEmpty && !ledger.isEmpty)
        _ = ledger.saw(.task(try reading("done and answered")), welcome: 1)
        #expect(ledger.isEmpty)
    }

    @Test func aFailureIsNotEvidenceOfTheCaptainsDismiss() throws {
        let before = try reading("working before its record answers")
        let failed = try reading("dropped after failing")
        #expect(PhoneIntentLedger.evidence(.finish(task: before.id, ending: .dismissQuestion), .task(failed)) == .void)
    }
}
