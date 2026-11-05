import Foundation
import Testing
@testable import InfinitaryKit

/// INF-2553, the captain's direction B ("it is the only one with a single place to reason about rollback, conflicts and
/// reconnects") with their answers: a closed card leaves at the tap; a refusal brings it back to its place; a lost
/// result keeps the change shown until the next snapshot after reconnecting says otherwise; a sent message clears the
/// box and shows as the last turn; and the task record is included.
struct PhoneIntentsTests {
    private struct Fixture: Decodable {
        let home: [PhoneCard]
        let folds: [Fold]
        let evidence: [Evidence]
        struct Fold: Decodable { let name: String; let intents: [PhoneJSON]; let stage: [String]; let aside: [String] }
        struct Evidence: Decodable { let name: String; let intent: PhoneJSON; let snapshot: [PhoneJSON]; let says: String }
    }

    private static let fixture: Fixture = {
        let url = Bundle.module.url(forResource: "PhoneIntents", withExtension: "json", subdirectory: "Fixtures")!
        return try! JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }()

    private func kind(_ json: PhoneJSON) -> PhoneIntent.Kind {
        let card = json["card"].text!, lifecycle = json["lifecycle"].text, offer = json["offer"].text
        switch json["kind"].text {
        case "close": return .close(card: card, lifecycle: lifecycle, offer: offer)
        case "choose": return .choose(card: card, lifecycle: lifecycle, offer: offer)
        case "putAside": return .putAside(card: card, lifecycle: lifecycle, offer: offer)
        default: return .bringBack(card: card)
        }
    }

    private func snapshot(_ entries: [PhoneJSON]) throws -> [PhoneCard] {
        try entries.map { entry in
            let card = Self.fixture.home.first { $0.id == entry["of"].text }!
            guard case .object(var value) = card.value else { throw PhoneError.invalidReply }
            if case .object(let fields) = entry["with"] { for (key, field) in fields { value[key] = field } }
            return try PhoneCard(.object(value))
        }
    }

    private func json(_ value: Any) -> PhoneJSON { try! PhoneJSON.read(value) }

    private func ledger(_ kinds: [PhoneIntent.Kind]) -> PhoneIntentLedger {
        var ledger = PhoneIntentLedger()
        for kind in kinds { ledger.add(kind) }
        return ledger
    }

    /// The stage's own rule (`ReadOnlySession.stack`) and the cards put aside.
    private func stage(_ cards: [PhoneCard]) -> [String] {
        cards.filter { ($0.awaiting == nil || $0.sentBackAt != nil) && !$0.minimized }.map(\.id)
    }

    @Test func foldsAsTheSharedTableDoes() {
        for fold in Self.fixture.folds {
            let shown = PhoneIntentFold.cards(Self.fixture.home, ledger(fold.intents.map(kind)).intents)
            #expect(stage(shown) == fold.stage, "\(fold.name)")
            #expect(shown.filter(\.minimized).map(\.id) == fold.aside, "\(fold.name)")
        }
    }

    @Test func readsEvidenceAsTheSharedTableDoes() throws {
        for entry in Self.fixture.evidence {
            let says = PhoneIntentLedger.evidence(kind(entry.intent), .cards(try snapshot(entry.snapshot)))
            #expect(says.map { "\($0)" } == entry.says, "\(entry.name)")
        }
    }

    private var close: PhoneIntent.Kind { .close(card: "c-chart", lifecycle: "life-chart-1", offer: "offer-chart-1") }

    @Test func aRefusedCloseReturnsTheCardToItsPlace() {
        var ledger = ledger([close])
        #expect(stage(PhoneIntentFold.cards(Self.fixture.home, ledger.intents)) == ["c-buoys"])
        let id = ledger.intents[0].id
        #expect(ledger.drop(id)?.kind == close)
        #expect(stage(PhoneIntentFold.cards(Self.fixture.home, ledger.intents)) == ["c-chart", "c-buoys"])
    }

    @Test func aPushThatHoldsTheChangeRetiresItBeforeItsResult() throws {
        var ledger = ledger([close])
        let contradicted = ledger.saw(.cards(try snapshot([json(["of": "c-buoys"])])), welcome: 1)
        #expect(contradicted.isEmpty && ledger.isEmpty)
    }

    @Test func anAcceptedChangeWaitsForTheSnapshotThatShowsIt() throws {
        var ledger = ledger([close])
        ledger.accept(ledger.intents[0].id)
        #expect(ledger.saw(.cards(Self.fixture.home), welcome: 1).isEmpty)
        #expect(ledger.intents.map(\.state) == [.accepted], "A snapshot still holding the card keeps the prediction")
        _ = ledger.saw(.cards(try snapshot([json(["of": "c-buoys"])])), welcome: 1)
        #expect(ledger.isEmpty)
    }

    @Test func aLostResultKeepsTheChangeUntilASnapshotAfterReconnecting() throws {
        var ledger = ledger([close])
        ledger.lose(ledger.intents[0].id, welcome: 1)
        // A push on the connection that lost the result says nothing yet.
        #expect(ledger.saw(.cards(Self.fixture.home), welcome: 1).isEmpty)
        #expect(stage(PhoneIntentFold.cards(Self.fixture.home, ledger.intents)) == ["c-buoys"])
        // The first snapshot after reconnecting still holds the card: the close did not happen, so it comes back.
        let contradicted = ledger.saw(.cards(Self.fixture.home), welcome: 2)
        #expect(contradicted.map(\.kind) == [close] && ledger.isEmpty)
    }

    /// INF-2584's review: a push the reconnect replays can predate the change, so only a snapshot after the welcome
    /// (the session passes a replayed push as `Int.min`) takes a lost change back.
    @Test func aReplayedPushNeverTakesALostChangeBack() throws {
        var ledger = ledger([close])
        ledger.lose(ledger.intents[0].id, welcome: 1)
        #expect(ledger.saw(.cards(Self.fixture.home), welcome: .min).isEmpty)
        #expect(ledger.intents.count == 1, "The replayed push still holding the card says nothing of the close")
        #expect(ledger.saw(.cards(Self.fixture.home), welcome: 2).map(\.kind) == [close])
    }

    @Test func aLostResultTheHomeCarriedOutRetiresQuietly() throws {
        var ledger = ledger([close])
        ledger.lose(ledger.intents[0].id, welcome: 1)
        #expect(ledger.saw(.cards(try snapshot([json(["of": "c-buoys"])])), welcome: 2).isEmpty)
        #expect(ledger.isEmpty)
    }

    @Test func aCardRevisedUnderACloseFreesIt() throws {
        var ledger = ledger([close])
        let revised = try snapshot([json(["of": "c-chart", "with": ["offerId": "offer-chart-2"]])])
        #expect(ledger.saw(.cards(revised), welcome: 1).isEmpty)
        #expect(ledger.isEmpty)
        #expect(stage(PhoneIntentFold.cards(revised, ledger.intents)) == ["c-chart"])
    }

    @Test func aReplyJoinsItsThreadMarkedSendingUntilTheThreadCarriesIt() {
        let words = "Keep the northern entrance clear."
        let held = json(["cardId": "c-chart", "messages": [["who": "captain", "text": words, "at": 1_793_000_000_000]]])
        let before = PhoneIntentLedger.captainMessages(held)
        var ledger = ledger([.reply(card: "c-chart", text: words, before: before)])
        let shown = PhoneIntentFold.threads(["c-chart": held], ledger.intents)["c-chart"]!["messages"].list
        #expect(shown.count == 2 && shown.last?["sending"] == .bool(true) && shown.last?["text"].text == words)
        // The same words sent before are not this reply.
        #expect(ledger.saw(.thread(card: "c-chart", held), welcome: 1).isEmpty && !ledger.isEmpty)
        let carried = json(["cardId": "c-chart", "messages": [["who": "captain", "text": words, "at": 1_793_000_000_000],
                                                             ["who": "captain", "text": words, "at": 1_793_000_100_000]]])
        _ = ledger.saw(.thread(card: "c-chart", carried), welcome: 1)
        #expect(ledger.isEmpty)
    }

    /// INF-2584's review: the home keeps a reply trimmed with a line for its picture, so a reply typed with a trailing
    /// space and a photo settles on that message; a second reply sent before the first shows waits for its own.
    @Test func aReplySettlesOnTheMessageTheHomeWroteWhateverItsWords() {
        let empty = json(["cardId": "c-chart", "messages": []])
        var ledger = ledger([.reply(card: "c-chart", text: "Keep it clear. ", before: PhoneIntentLedger.captainMessages(empty))])
        let shown = PhoneIntentFold.threads(["c-chart": empty], ledger.intents)["c-chart"]
        ledger.add(.reply(card: "c-chart", text: "And the south one.", before: PhoneIntentLedger.captainMessages(shown)))
        let first = json(["cardId": "c-chart", "messages": [["who": "captain", "text": "Keep it clear.\n[attached a photo]", "at": 1]]])
        _ = ledger.saw(.thread(card: "c-chart", first), welcome: 1)
        #expect(ledger.intents.map(\.id) == [2], "The first reply settles; the second still shows, sending")
        let both = json(["cardId": "c-chart", "messages": [["who": "captain", "text": "Keep it clear.\n[attached a photo]", "at": 1],
                                                          ["who": "captain", "text": "And the south one.", "at": 2]]])
        _ = ledger.saw(.thread(card: "c-chart", both), welcome: 1)
        #expect(ledger.isEmpty)
    }

    // INF-2584 review: a later reply counted the earlier one still sending, so it settles on its own message once
    // the computer refuses the earlier one.
    @Test func aRefusedReplyNoLongerCountsBeforeTheNextOne() {
        let empty = json(["cardId": "c-chart", "messages": []])
        var ledger = ledger([.reply(card: "c-chart", text: "Keep it clear.", before: 0)])
        let shown = PhoneIntentFold.threads(["c-chart": empty], ledger.intents)["c-chart"]
        ledger.add(.reply(card: "c-chart", text: "And the south one.", before: PhoneIntentLedger.captainMessages(shown)))
        ledger.drop(ledger.intents[0].id)
        let second = json(["cardId": "c-chart", "messages": [["who": "captain", "text": "And the south one.", "at": 2]]])
        _ = ledger.saw(.thread(card: "c-chart", second), welcome: 1)
        #expect(ledger.isEmpty, "The second reply settles on the one message the computer holds")
    }

    private func turn(_ you: String, reply: String?, previous: String? = nil) throws -> PhoneLastTurn {
        var json: [String: Any] = ["you": you, "previous": previous.map { ["you": $0, "reply": NSNull()] } ?? NSNull()]
        json["reply"] = reply.map { ["text": $0, "eligibility": "completed"] } ?? NSNull()
        return try JSONDecoder().decode(PhoneLastTurn.self, from: JSONSerialization.data(withJSONObject: json))
    }

    @Test func aSentMessageIsTheLastTurnUntilTheHomeShowsIt() throws {
        let earlier = try turn("Count the buoys", reply: "Forty-two are on station.")
        var ledger = ledger([.send(text: "Chart the northern entrance", before: PhoneTurnMark(earlier))])
        let shown = try #require(PhoneIntentFold.lastTurn(earlier, ledger.intents))
        #expect(shown.you == "Chart the northern entrance" && shown.reply == nil)
        #expect(shown.previous?.you == "Count the buoys" && shown.previous?.reply?.text == "Forty-two are on station.")
        #expect(ledger.saw(.turn(earlier), welcome: 1).isEmpty && !ledger.isEmpty)
        _ = ledger.saw(.turn(try turn("Chart the northern entrance", reply: nil, previous: "Count the buoys")), welcome: 1)
        #expect(ledger.isEmpty)
    }

    /// INF-2584's review: the same words sent again are told apart from the turn already there, so the prediction
    /// stays until the home's turn for this message, and a lost one whose home never took it comes back.
    @Test func aRepeatedMessageWaitsForItsOwnTurn() throws {
        let earlier = try turn("Count the buoys", reply: "Forty-two.", previous: "Chart the entrance")
        var ledger = ledger([.send(text: "Count the buoys", before: PhoneTurnMark(earlier))])
        #expect(ledger.saw(.turn(earlier), welcome: 1).isEmpty && !ledger.isEmpty, "The earlier turn with the same words is not this one")
        _ = ledger.saw(.turn(try turn("Count the buoys", reply: nil, previous: "Count the buoys")), welcome: 1)
        #expect(ledger.isEmpty)
        var lost = self.ledger([.send(text: "Count the buoys", before: PhoneTurnMark(earlier))])
        lost.lose(lost.intents[0].id, welcome: 1)
        #expect(lost.saw(.turn(earlier), welcome: 2).count == 1, "After reconnecting, an unchanged last turn takes it back")
    }

    // INF-2584 review: a later message followed the earlier one still sending, so it follows the turn before that
    // once the earlier one is refused, or taken back after reconnecting.
    @Test func aMessageTakenBackHandsTheNextOneItsPlace() throws {
        let earlier = try turn("Count the buoys", reply: "Forty-two.")
        var refused = ledger([.send(text: "Chart the entrance", before: PhoneTurnMark(earlier))])
        refused.add(.send(text: "Mark the reef", before: PhoneTurnMark(PhoneIntentFold.lastTurn(earlier, refused.intents))))
        refused.drop(refused.intents[0].id)
        _ = refused.saw(.turn(try turn("Mark the reef", reply: nil, previous: "Count the buoys")), welcome: 1)
        #expect(refused.isEmpty, "The second message settles on its own turn")
        // The first message's answer was lost; the second goes on the new connection, then the read after the
        // welcome shows the computer never took the first.
        var lost = ledger([.send(text: "Chart the entrance", before: PhoneTurnMark(earlier))])
        lost.lose(lost.intents[0].id, welcome: 1)
        lost.add(.send(text: "Mark the reef", before: PhoneTurnMark(PhoneIntentFold.lastTurn(earlier, lost.intents))))
        #expect(lost.saw(.turn(earlier), welcome: 2).map(\.id) == [1], "The message the computer never took comes back")
        _ = lost.saw(.turn(try turn("Mark the reef", reply: nil, previous: "Count the buoys")), welcome: 2)
        #expect(lost.isEmpty, "The second message settles on its own turn")
    }

    private func task(status: String, activity: String?, moves: [String: Bool]? = nil, phase: String? = nil) throws -> PhoneTask {
        var row: [String: Any] = [
            "id": "t-buoys", "key": "INF-13", "projectId": "proj-harbour", "parentId": NSNull(), "kind": "work",
            "title": "Count the buoys", "status": status, "createdAt": 1_793_000_000_000, "startPolicy": "when-ready",
            "blockedBy": [], "waitingCardId": NSNull(),
        ]
        if let activity { row["activity"] = activity }
        if let moves { row["moves"] = moves.mapValues { ["ok": $0] } }
        if let phase { row["startAttempt"] = ["phase": phase] }
        return try JSONDecoder().decode(PhoneTask.self, from: JSONSerialization.data(withJSONObject: row))
    }

    private func board(_ tasks: [PhoneTask]) throws -> PhoneBoard {
        let json: [String: Any] = ["seq": 41, "tasks": [], "projects": [["id": "proj-harbour", "name": "Harbour"]]]
        var board = try JSONDecoder().decode(PhoneBoard.self, from: JSONSerialization.data(withJSONObject: json))
        board.tasks = tasks
        return board
    }

    @Test func aStartReadsStartingOnTheRecordAndItsRowUntilTheHomeShowsIt() throws {
        let queued = try task(status: "open", activity: nil, moves: ["start-task": true])
        var ledger = ledger([.start(task: "t-buoys", move: "start-task")])
        let shown = PhoneIntentFold.task(queued, ledger.intents)
        #expect(shown.state == "Starting" && shown.moves?["start-task"]?.ok == false)
        #expect(PhoneIntentFold.board(try board([queued]), ledger.intents)?.tasks.first?.state == "Starting")
        #expect(ledger.saw(.task(queued), welcome: 1).isEmpty && !ledger.isEmpty)
        _ = ledger.saw(.board(try board([try task(status: "active", activity: "running")])), welcome: 1)
        #expect(ledger.isEmpty)
    }

    @Test func aTaskClosedUnderAStartFreesIt() throws {
        var ledger = ledger([.start(task: "t-buoys", move: "start-task")])
        _ = ledger.saw(.task(try task(status: "dropped", activity: nil)), welcome: 1)
        #expect(ledger.isEmpty)
    }

    @Test func anInterruptReadsStoppingUntilTheTurnEnds() throws {
        let running = try task(status: "active", activity: "running")
        var ledger = ledger([.interrupt(task: "t-buoys")])
        #expect(PhoneIntentFold.task(running, ledger.intents).state == "Stopping")
        #expect(ledger.saw(.task(running), welcome: 1).isEmpty && !ledger.isEmpty)
        _ = ledger.saw(.task(try task(status: "active", activity: "interrupted")), welcome: 1)
        #expect(ledger.isEmpty)
    }

    private func crew(_ sent: [String]) throws -> PhoneCrew {
        let lines = sent.enumerated().map { ["id": "line-\($0.offset)", "kind": "sent", "from": "captain", "text": $0.element] }
        let json: [String: Any] = ["taskId": "t-buoys", "earlier": 0, "lines": [["id": "brief", "kind": "brief", "text": "Count the buoys."]] + lines]
        return try JSONDecoder().decode(PhoneCrew.self, from: JSONSerialization.data(withJSONObject: json))
    }

    @Test func aSteerShowsAsSentUntilTheTranscriptCarriesIt() throws {
        let words = "Count the ones by the breakwater first."
        let held = try crew([words])
        var ledger = ledger([.steer(task: "t-buoys", text: words, before: PhoneIntentLedger.captainSteers(held))])
        let shown = PhoneIntentFold.crew(held, ledger.intents)
        #expect(shown.lines.count == 3 && shown.lines.last?.sending == true && shown.lines.last?.words == words)
        #expect(ledger.saw(.crew(held), welcome: 1).isEmpty && !ledger.isEmpty)
        _ = ledger.saw(.crew(try crew([words, words])), welcome: 1)
        #expect(ledger.isEmpty)
    }

    /// INF-2584's review: the home keeps a steer trimmed, so one typed with a trailing space settles on it.
    @Test func aSteerSettlesOnTheLineTheHomeWroteWhateverItsWords() throws {
        let held = try crew([])
        var ledger = ledger([.steer(task: "t-buoys", text: "Count the hatch too ", before: PhoneIntentLedger.captainSteers(held))])
        _ = ledger.saw(.crew(try crew(["Count the hatch too"])), welcome: 1)
        #expect(ledger.isEmpty)
    }
}
