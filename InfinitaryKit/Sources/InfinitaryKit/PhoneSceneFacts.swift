import Foundation

/// Public observations only. These carry no address, sign-in or device-management operation.
public struct PhoneComputerPresence: Decodable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let inReach: Bool?
}
public struct PhoneConversationState: Decodable, Sendable { public let busy: Bool }

/// Transient effects heard live, never reconstructed from a replay or a board snapshot.
public struct PhoneSceneSignal: Sendable {
    public enum Kind: Sendable { case report, steer, failed, usage }
    public let kind: Kind
    public let taskID: String
    public let tokens: Double

    static func read(_ event: [String: Any]) -> Self? {
        guard let type = event["type"] as? String, let id = event["taskId"] as? String else { return nil }
        switch type {
        case "task_report": return Self(kind: .report, taskID: id, tokens: 0)
        case "task_event" where event["reached"] as? Bool == true: return Self(kind: .steer, taskID: id, tokens: 0)
        case "turn_failed" where event["crewmate"] as? Bool == true: return Self(kind: .failed, taskID: id, tokens: 0)
        case "turn_end":
            guard let usage = event["usage"] as? [String: Any] else { return nil }
            let total = ["input", "output", "cacheRead", "cacheWrite"].reduce(0.0) { $0 + ((usage[$1] as? NSNumber)?.doubleValue ?? 0) }
            guard total > 0, total.isFinite else { return nil }
            return Self(kind: .usage, taskID: id, tokens: total)
        default: return nil
        }
    }
}
