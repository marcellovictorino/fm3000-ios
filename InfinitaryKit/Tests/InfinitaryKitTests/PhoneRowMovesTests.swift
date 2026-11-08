import Foundation
import Testing
@testable import InfinitaryKit

/// INF-2928 piece 3 (the captain's "Every move the Mac allows on that row"): a long press on a Tasks row offers the Mac's
/// task board menu for that row, and a swipe on a Backlog row the Mac's row Start. These replay the desktop's own reading
/// of one row in each state they read (`boardMenuOf`, `boardMoveOf`, `rowStartOf`, `dropAskOf`), which
/// scripts/generate-phone-scene.ts records, so the phone offers, refuses and asks what the Mac does for the same row.
struct PhoneRowMovesTests {
    private struct Fixture: Decodable { let readings: [Reading]; let drops: [Drop] }
    private struct Reading: Decodable {
        let name: String
        let row: PhoneTask
        let lane: String
        let menu: [MenuItem]
        let moves: [String: Move]
        let rowStart: Start?
    }
    private struct MenuItem: Decodable {
        let separator: Bool?
        let id: String?
        let label: String?
        let detail: String?
        let disabled: Bool?
        let danger: Bool?
        let target: String?
    }
    private struct Move: Decodable {
        let kind: String
        let text: String?
        let op: String?
        let done: String?
        let sentence: String?
        let confirm: String?
        let cardId: String?
    }
    private struct Start: Decodable { let label: String; let reason: String? }
    private struct Drop: Decodable {
        let name: String
        let key: String
        let effects: PhoneTask.DropEffects?
        let ask: DropAsk
    }
    private struct DropAsk: Decodable { let kind: String; let text: String?; let sentence: String?; let review: [String: [String]]? }

    private func fixture() throws -> Fixture {
        let url = try #require(Bundle.module.url(forResource: "PhoneRowMoves.generated", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }

    /// A phone move in the Mac's shape, so the two compare field by field.
    private func shape(_ move: PhoneRowMoves.Move) -> [String: String] {
        switch move {
        case .none(let text): ["kind": "none", "text": text]
        case .refused(let text): ["kind": "refused", "text": text]
        case .now(let op, let text, let done): ["kind": "now", "op": op, "text": text, "done": done]
        case .ask(let op, let sentence, let confirm): ["kind": "ask", "op": op, "sentence": sentence, "confirm": confirm]
        case .card(let card, let text): ["kind": "card", "cardId": card, "text": text]
        }
    }

    private func shape(_ move: Move) -> [String: String] {
        let fields: [String: String?] = ["kind": move.kind, "text": move.text, "op": move.op, "done": move.done,
                                         "sentence": move.sentence, "confirm": move.confirm, "cardId": move.cardId]
        return fields.compactMapValues(\.self)
    }

    @Test func eachRowOffersTheMacsMoves() throws {
        let recorded = try fixture()
        #expect(recorded.readings.count > 20)
        for reading in recorded.readings {
            let name = reading.name
            let lane = try #require(reading.lane == "earlier" ? .earlier : PhoneRowMoves.lane(reading.row), "\(name): its lane")
            #expect(lane.rawValue == reading.lane, "\(name): the lane")
            let menu = PhoneRowMoves.menu(reading.row, lane: lane)
            #expect(menu.count == reading.menu.count, "\(name): the menu's entries")
            for (item, want) in zip(menu, reading.menu) {
                switch item {
                case .separator: #expect(want.separator == true, "\(name): a line before Drop task")
                case .entry(let entry):
                    #expect(entry.id.rawValue == want.id, "\(name): the entry")
                    #expect(entry.label == want.label, "\(name): \(entry.id) is named")
                    #expect(entry.detail == want.detail, "\(name): what \(entry.label) does, or why it cannot")
                    #expect(entry.disabled == (want.disabled ?? false), "\(name): whether \(entry.label) can run")
                    #expect(entry.danger == (want.danger ?? false), "\(name): \(entry.label)'s tone")
                    #expect(entry.target?.rawValue == want.target, "\(name): where \(entry.label) moves it")
                }
            }
            for (target, want) in reading.moves {
                let move = PhoneRowMoves.move(reading.row, from: lane, to: try #require(PhoneRowMoves.Target(rawValue: target)))
                #expect(shape(move) == shape(want), "\(name): moving it to \(target)")
            }
            let start = PhoneRowMoves.rowStart(reading.row)
            #expect(start?.label == reading.rowStart?.label, "\(name): the row's Start")
            #expect(start?.reason == reading.rowStart?.reason, "\(name): why the row's Start cannot start")
        }
    }

    @Test func dropTaskAsksInTheRecordsWords() throws {
        let recorded = try fixture()
        #expect(recorded.drops.count > 4)
        for drop in recorded.drops {
            switch PhoneRowMoves.dropAsk(drop.key, effects: drop.effects) {
            case .ask(let sentence, let review):
                #expect(drop.ask.kind == "ask", "\(drop.name): it asks")
                #expect(sentence == drop.ask.sentence, "\(drop.name): the question")
                #expect(review == drop.ask.review, "\(drop.name): the review the host checks again")
            case .refused(let text):
                #expect(drop.ask.kind == "refused", "\(drop.name): it refuses")
                #expect(text == drop.ask.text, "\(drop.name): why it cannot be dropped")
            }
        }
    }
}
