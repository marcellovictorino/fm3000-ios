import Foundation
import Testing
@testable import InfinitaryKit

/// INF-2928 piece 1, the captain's direction A: the phone's Tasks list reads as the Mac's Tasks panel. These replay the
/// desktop panel's own reading of one board (`rowsOf`, `earlierRowsOf`, `wordOf`, `trailingOf` and the folding
/// headers' counts), which scripts/generate-phone-scene.ts records, so the phone's groups, order, depth, words and
/// trailing words are the Mac's for the same rows.
struct PhoneTaskListTests {
    private struct Fixture: Decodable { let readings: [Reading] }
    private struct Reading: Decodable {
        let name: String
        let query: String
        let now: Double
        let board: PhoneBoard
        let earlier: [PhoneTask]
        let sections: [Section]
    }
    private struct Section: Decodable {
        let section: String
        let folds: Bool
        let count: Int
        let newWords: String?
        let failedWords: String?
        let rows: [Row]
    }
    private struct Row: Decodable {
        let key: String
        let depth: Int
        let word: String
        let trailing: Trailing
        let wait: String?
        let mark: String
        let reason: String
    }
    private struct Trailing: Decodable {
        let name: String; let place: String; let outOfReach: Bool; let connecting: Bool; let reach: String
    }

    private func readings() throws -> [Reading] {
        let url = try #require(Bundle.module.url(forResource: "PhoneTaskList.generated", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url)).readings
    }

    @Test func theListReadsAsTheMacsTasksPanel() throws {
        let all = try readings()
        #expect(all.count == 3)
        for reading in all {
            let list = PhoneTaskList(board: reading.board, cards: [], query: reading.query, earlier: reading.earlier)
            #expect(list.parts.map(\.section.id) == reading.sections.map(\.section),
                    "\(reading.name): the groups that show")
            for (part, expected) in zip(list.parts, reading.sections) {
                #expect(part.section.folds == expected.folds, "\(reading.name) \(expected.section): whether it folds")
                #expect(part.count == expected.count, "\(reading.name) \(expected.section): its count")
                #expect((part.new > 0 ? PhoneTaskRowWords.newCount(part.new) : nil) == expected.newWords)
                #expect((part.section == .group(.backlog) && part.failed > 0 ? PhoneTaskRowWords.failedCount(part.failed) : nil)
                        == expected.failedWords)
                #expect(part.rows.map(\.task.key) == expected.rows.map(\.key), "\(reading.name) \(expected.section): the order")
                for (row, want) in zip(part.rows, expected.rows) {
                    #expect(row.depth == want.depth, "\(want.key): its depth")
                    #expect(PhoneTaskList.word(row.task) == want.word, "\(want.key): its word")
                    let trailing = list.trailing(of: row.task)
                    #expect(trailing == PhoneTaskList.Trailing(name: want.trailing.name, place: want.trailing.place,
                                                               outOfReach: want.trailing.outOfReach,
                                                               connecting: want.trailing.connecting, reach: want.trailing.reach),
                            "\(want.key): its trailing words")
                    #expect(part.waitLine(of: row.task) == want.wait, "\(want.key): its wait line")
                    let status = PhoneTaskFacts.status(row.task, now: reading.now)
                    #expect(status.mark == want.mark, "\(want.key): its mark")
                    #expect(status.reason == want.reason, "\(want.key): its reason")
                }
            }
        }
    }
}
