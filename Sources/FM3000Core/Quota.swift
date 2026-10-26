import Foundation

/// How a window's use compares with an even spread over its time: within pace, up to ten points ahead, or further.
public enum QuotaPace: Equatable { case withinPace, slightlyAhead, wellAhead, unknown }

/// Subscription allowance as the Mac's quota panel keeps it (`inf:quota:snapshot`): per provider, the share of each window left.
public struct QuotaSnapshot: Codable, Equatable {
    public struct Window: Codable, Equatable, Identifiable {
        public let id: String
        public let label: String
        public let percentRemaining: Double?
        public let resetText: String?
        public let resetsAtMs: Double?
        public let windowSeconds: Double?
        public init(id: String, label: String, percentRemaining: Double? = nil, resetText: String? = nil, resetsAtMs: Double? = nil, windowSeconds: Double? = nil) {
            self.id = id; self.label = label; self.percentRemaining = percentRemaining; self.resetText = resetText
            self.resetsAtMs = resetsAtMs; self.windowSeconds = windowSeconds
        }

        /// A limit on one model (`model:fable`) or model family (`seven_day_opus`), not the account's own allowance.
        var isModelScoped: Bool { id.hasPrefix("model:") || id.hasPrefix("seven_day_") }

        /// The share of the window already used, 0 to 100.
        public var percentUsed: Double? { percentRemaining.map { min(max(100 - $0, 0), 100) } }

        /// Where use would sit now if it were spread evenly over the window: the share of the window's time gone.
        public func idealUsedPercent(nowMs: Double) -> Double? {
            guard let resetsAtMs, let windowSeconds, windowSeconds > 0 else { return nil }
            let left = (resetsAtMs - nowMs) / 1000
            return min(max(100 * (windowSeconds - left) / windowSeconds, 0), 100)
        }

        /// Use against that even spread. Within a point either side is on pace, as the Mac's own pace reads it.
        public func pace(nowMs: Double) -> QuotaPace {
            guard let used = percentUsed, let ideal = idealUsedPercent(nowMs: nowMs) else { return .unknown }
            let over = used - ideal
            return over <= 1 ? .withinPace : (over <= 10 ? .slightlyAhead : .wellAhead)
        }

        /// Time until the window resets, in its two largest units: `1d 3h`, `3h 05m`, `12 min`, `now`.
        public func resetsIn(nowMs: Double) -> String? {
            guard let resetsAtMs else { return nil }
            let minutes = Int(((resetsAtMs - nowMs) / 60_000).rounded(.down))
            if minutes <= 0 { return "now" }
            if minutes < 60 { return "\(minutes) min" }
            let hours = minutes / 60
            if hours < 24 { return String(format: "%dh %02dm", hours, minutes % 60) }
            return "\(hours / 24)d \(hours % 24)h"
        }
    }

    public struct Provider: Codable, Equatable, Identifiable {
        public let provider: String
        public let label: String
        public let plan: String?
        public let status: String
        public let stale: Bool
        public let reason: String?
        public let measuredAt: Double?
        public let windows: [Window]
        public var id: String { provider }
        public init(provider: String, label: String, plan: String? = nil, status: String, stale: Bool = false, reason: String? = nil, measuredAt: Double? = nil, windows: [Window]) {
            self.provider = provider; self.label = label; self.plan = plan; self.status = status; self.stale = stale
            self.reason = reason; self.measuredAt = measuredAt; self.windows = windows
        }

        /// The rolling five-hour window: its own id first, then any account-wide window of that length.
        public var fiveHour: Window? { window(ids: ["five_hour", "session"], seconds: 18_000) }
        /// The account's weekly window. The Mac sorts windows by id, so a model-scoped week (`model:fable`, also
        /// 604,800 seconds) comes before `seven_day`; matching on length alone showed that model's 100% instead.
        public var weekly: Window? { window(ids: ["seven_day", "weekly"], seconds: 604_800) }

        private func window(ids: [String], seconds: Double) -> Window? {
            for id in ids { if let match = windows.first(where: { $0.id == id }) { return match } }
            return windows.first { $0.windowSeconds == seconds && !$0.isModelScoped }
        }

        /// Why there is no figure, in one calm line; nil when the windows are the answer.
        public var unavailable: String? {
            switch status {
            case "ok": return nil
            case "auth_required": return "Sign in again on the Mac"
            case "rate_limited": return "The provider is limiting reads right now"
            case "not_measured", "skipped": return "Not measured on this Mac"
            default: return reason ?? "No reading right now"
            }
        }
    }

    public let fetchedAt: Double
    public let providers: [Provider]
    public init(fetchedAt: Double, providers: [Provider]) { self.fetchedAt = fetchedAt; self.providers = providers }

    /// Claude and Codex, in that order, whichever the Mac measures.
    public var shown: [Provider] {
        ["claude", "codex"].compactMap { name in providers.first { $0.provider == name } }
    }
}

/// The model pill's text: the model's own name without its provider, then the reasoning effort in brackets
/// (`Claude Sonnet 5.5 (Medium)`). The Mac's label wins over the id; an id reads as a name (`claude-sonnet-5-5` reads
/// `Claude Sonnet 5.5`, `gpt-5.5-codex` reads `GPT 5.5 Codex`). The effort is left out when the Mac sets none ("default", "off").
/// Nil when the Mac named no model.
public func modelPill(label: String?, id: String?, effort: String? = nil) -> String? {
    var name: String
    if let label, !label.trimmingCharacters(in: .whitespaces).isEmpty {
        name = label.trimmingCharacters(in: .whitespaces)
        for provider in ["Anthropic ", "OpenAI "] where name.hasPrefix(provider) { name.removeFirst(provider.count) }
    } else {
        guard let id, !id.isEmpty else { return nil }
        var words: [String] = []
        var numbers: [String] = []
        for part in id.split(whereSeparator: { $0 == "-" || $0 == " " }) {
            if part.allSatisfy({ $0.isNumber }) { numbers.append(String(part)) }
            else {
                if !numbers.isEmpty { words.append(numbers.joined(separator: ".")); numbers = [] }
                let text = String(part)
                words.append(text.lowercased() == "gpt" ? "GPT" : text.prefix(1).uppercased() + text.dropFirst())
            }
        }
        if !numbers.isEmpty { words.append(numbers.joined(separator: ".")) }
        name = words.joined(separator: " ")
    }
    guard let effort, !["", "default", "off"].contains(effort) else { return name }
    return "\(name) (\(effort.prefix(1).uppercased() + effort.dropFirst()))"
}
