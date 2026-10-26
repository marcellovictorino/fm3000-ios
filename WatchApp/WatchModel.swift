import FM3000WatchLink
import Foundation
import WatchConnectivity

/// The watch's whole state. It holds no pairing and no connection: every read and every choice is one message to the phone,
/// which asks the Mac and answers with the cards still waiting on the captain.
@MainActor
final class WatchModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var cards: [WatchCard] = []
    @Published private(set) var loading = false
    /// Why the last request failed, in words for the wrist; nil when it went through.
    @Published private(set) var problem: String?
    /// Set once the first answer arrives, so "Nothing waiting" is never shown before the phone has answered.
    @Published private(set) var loaded = false
    @Published private(set) var sending: String?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor in await refresh() }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in if session.isReachable, !loaded, !loading { await refresh() } }
    }

    func refresh() async { await run(.cards) }

    /// Presses one of a card's buttons; true when the Mac took it.
    func choose(_ choice: WatchChoice, on card: WatchCard) async -> Bool {
        sending = choice.id
        defer { sending = nil }
        return await run(.choose(cardId: card.id, choiceId: choice.id))
    }

    func putAside(_ card: WatchCard) async -> Bool {
        sending = "aside"
        defer { sending = nil }
        return await run(.putAside(cardId: card.id))
    }

    @discardableResult
    private func run(_ request: WatchRequest) async -> Bool {
        loading = true
        defer { loading = false }
        let reply = await ask(request)
        if let list = reply.cards { cards = list; loaded = true }
        problem = reply.problem
        return reply.problem == nil && reply.cards != nil
    }

    private func ask(_ request: WatchRequest) async -> WatchReply {
        let session = WCSession.default
        guard session.activationState == .activated else { return WatchReply(cards: nil, problem: "Starting up. Try again.") }
        // Reachability lags behind activation, and a sleeping phone app takes a moment to wake: give it a few seconds.
        for _ in 0..<50 where !session.isReachable { try? await Task.sleep(nanoseconds: 100_000_000) }
        guard session.isReachable else { return WatchReply(cards: nil, problem: "Your iPhone is out of reach.") }
        return await withCheckedContinuation { continuation in
            session.sendMessage(WatchWire.message(request)) { answer in
                continuation.resume(returning: WatchWire.reply(from: answer) ?? WatchReply(cards: nil, problem: "The phone sent something unreadable."))
            } errorHandler: { _ in
                continuation.resume(returning: WatchReply(cards: nil, problem: "Your iPhone did not answer."))
            }
        }
    }
}
