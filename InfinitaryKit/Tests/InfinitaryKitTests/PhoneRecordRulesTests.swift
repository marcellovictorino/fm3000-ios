import Foundation
import Testing
@testable import InfinitaryKit

/// INF-2935 (INF-2928 piece 2, the captain's direction A): the phone's task record follows the Mac's. These replay the
/// desktop record's own reading of one task in each state it draws (`recordBarOf`, `recordPillToneOf`, the record's
/// status reason, `taskTabsOf`, `recordAttentionOf`, `recordClosedLineOf`, the fold under the goal, Drop task's question
/// and `crewStateOf`), which scripts/generate-phone-scene.ts records, so the phone's record says and offers what the
/// Mac's does for the same task.
struct PhoneRecordRulesTests {
    private struct Fixture: Decodable { let now: Double; let cases: [Case] }
    private struct Case: Decodable {
        let name: String
        let row: PhoneTask
        let live: PhoneCrewLive?
        let bar: Bar?
        let pillTone: String
        let status: Status
        let tabs: [Tab]
        let crew: String
        let attention: Attention?
        let closed: String?
        let fold: String?
        let asks: [String]
        let drop: Drop?
    }
    private struct Bar: Decodable { let end: String?; let next: String?; let blocked: Bool }
    private struct Status: Decodable { let mark: String; let word: String; let reason: String }
    private struct Tab: Decodable { let kind: String; let label: String; let count: Int? }
    private struct Attention: Decodable { let title: String; let guidance: String; let urgent: Bool; let danger: Bool }
    private struct Drop: Decodable { let refusal: String?; let question: String? }

    private func fixture() throws -> Fixture {
        let url = try #require(Bundle.module.url(forResource: "PhoneTaskRecord.generated", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }

    @Test func theRecordReadsAsTheMacsRecord() throws {
        let recorded = try fixture()
        #expect(recorded.cases.count > 30)
        for reading in recorded.cases {
            let task = reading.row
            let name = reading.name
            let bar = PhoneRecord.bar(task)
            #expect(bar?.end?.rawValue == reading.bar?.end, "\(name): the bar's end")
            #expect(bar?.next?.rawValue == reading.bar?.next, "\(name): the bar's next step")
            #expect(bar?.blocked == reading.bar?.blocked, "\(name): whether the next step waits")
            #expect(PhoneRecord.pillTone(task) == reading.pillTone, "\(name): the pill's tone")
            let status = PhoneRecord.status(task, now: recorded.now)
            #expect(status.mark == reading.status.mark && status.word == reading.status.word, "\(name): the pill")
            #expect(status.reason == reading.status.reason, "\(name): the reason beside the pill")
            let tabs = PhoneRecord.tabs(task)
            #expect(tabs.map(\.id) == reading.tabs.map(\.kind), "\(name): the tabs")
            #expect(tabs.map(\.label) == reading.tabs.map(\.label), "\(name): the tabs' words")
            for (tab, want) in zip(tabs, reading.tabs) where want.count != nil {
                if case .cards(let count) = tab { #expect(count == want.count, "\(name): the Cards tab's count") }
            }
            #expect(PhoneRecord.crewState(task, live: reading.live).rawValue == reading.crew, "\(name): the crewmate's state")
            let attention = PhoneRecord.attention(task, now: recorded.now)
            #expect(attention?.title == reading.attention?.title, "\(name): what needs attention")
            #expect(attention?.guidance == reading.attention?.guidance, "\(name): its guidance")
            #expect(attention?.urgent == reading.attention?.urgent && attention?.danger == reading.attention?.danger,
                    "\(name): where it sits and its tone")
            #expect(PhoneRecord.closedLine(task)?.words(now: recorded.now) == reading.closed, "\(name): how it closed")
            #expect(PhoneRecord.wordsFoldName(task) == reading.fold, "\(name): the fold under the goal")
            #expect(PhoneRecord.asks(task).map(\.id) == reading.asks, "\(name): the captain's later messages")
            if let end = bar?.end, end != .dismissQuestion {
                let refusal = PhoneRecord.dropRefusal(task, end: end)
                #expect(refusal == reading.drop?.refusal, "\(name): why it cannot be dropped")
                #expect((refusal == nil ? PhoneRecord.dropQuestion(task, end: end) : nil) == reading.drop?.question,
                        "\(name): Drop task's question")
            } else {
                #expect(reading.drop == nil, "\(name): no Drop task")
            }
        }
    }
}
