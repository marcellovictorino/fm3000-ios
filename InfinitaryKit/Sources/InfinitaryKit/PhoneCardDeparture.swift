import Foundation

/// FI3-711 and INF-3155: the card that comes up when the shown card leaves the stack, by the Mac's own rule
/// (`departureIndex` with `neighboursOf`, src/renderer/src/app/stack.ts). The first unread card in stack order, else the
/// card nearest after where the shown card was, else the nearest before it, else the first card. PhoneCardDepartureTests
/// replays the Mac's own choices, recorded by scripts/generate-phone-scene.ts.
public enum PhoneCardDeparture {
    /// `previous` is the stack as it stood with `left` shown, `ids` the stack now; nil when no card is left.
    public static func comesUp(after left: String?, previous: [String], ids: [String], unread: (String) -> Bool) -> String? {
        if let first = ids.first(where: unread) { return first }
        if let left, let at = previous.firstIndex(of: left) {
            let neighbours = previous[(at + 1)...] + previous[..<at].reversed()
            if let near = neighbours.first(where: ids.contains) { return near }
        }
        return ids.first
    }
}
