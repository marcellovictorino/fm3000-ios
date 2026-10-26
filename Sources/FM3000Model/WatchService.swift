import FM3000Core
import FM3000WatchLink
import Foundation

public extension WatchCard {
    /// What the watch gets of a card: the body as plain text (`HTMLText.plain`), its buttons, and whether it needs a filled-in answer.
    init(_ card: Card) {
        var text = HTMLText.plain(card.body)
        if text.count > Self.textLimit { text = String(text.prefix(Self.textLimit)).trimmingCharacters(in: .whitespacesAndNewlines) + "…" }
        let lower = card.body.lowercased()
        let form = card.asking == true || ["<input", "<select", "<textarea"].contains { lower.contains($0) }
        self.init(id: card.id, title: card.title, meta: card.meta, text: text,
                  choices: form ? [] : card.actions.map { WatchChoice(id: $0.id, label: $0.label, isDefault: $0.isDefault) },
                  needsPhone: form)
    }

    /// The cards the watch lists: the ones the captain's turn is on, most recent first, as the phone's Waiting on you chip counts them.
    static func waiting(_ cards: [Card]) -> [WatchCard] {
        filterCards(cards, by: .waiting, board: nil).sorted { $0.createdAt > $1.createdAt }.map(WatchCard.init)
    }
}

/// Answers the watch for the phone. Kept apart from WatchConnectivity so the end-to-end run can drive it against the fake Mac.
@MainActor
public final class WatchService {
    private let model: AppModel
    public init(model: AppModel) { self.model = model }

    public func handle(_ request: WatchRequest) async -> WatchReply {
        model.start()
        guard await model.waitUntilConnected(seconds: 12) else {
            return WatchReply(cards: nil, problem: "Your phone could not reach your Mac.")
        }
        var problem: String?
        switch request {
        case .cards:
            break
        case .choose(let cardId, let choiceId):
            if !model.canChange { problem = "This phone can only read; answer on your Mac." }
            else if let card = model.cards.first(where: { $0.id == cardId }), let action = card.actions.first(where: { $0.id == choiceId }) {
                model.notice = nil
                await model.choose(action, on: card)
                problem = model.notice
            } else { problem = "That card is gone." }
        case .putAside(let cardId):
            if let card = model.cards.first(where: { $0.id == cardId }) {
                model.notice = nil
                if !(await model.putAside(card)) { problem = model.notice ?? "The Mac did not put it aside." }
            } else { problem = "That card is gone." }
        }
        await model.refreshCards()
        return WatchReply(cards: WatchCard.waiting(model.cards), problem: problem)
    }
}
