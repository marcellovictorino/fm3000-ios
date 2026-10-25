import Foundation

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

        /// The rolling five-hour window, found by its length (the vendors name it differently).
        public var fiveHour: Window? { windows.first { $0.windowSeconds == 18_000 || $0.id == "five_hour" } }
        /// The weekly window.
        public var weekly: Window? { windows.first { $0.windowSeconds == 604_800 || $0.id == "seven_day" || $0.id == "weekly" } }

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

/// The short name for the model pill: the Mac's own label when it has one, else the model id made readable
/// (`claude-sonnet-5-5` reads `Sonnet 5.5`, `gpt-5.5-codex` reads `GPT 5.5 Codex`). Nil when the Mac named none.
public func modelPill(label: String?, id: String?) -> String? {
    if let label, !label.trimmingCharacters(in: .whitespaces).isEmpty { return label }
    guard var id, !id.isEmpty else { return nil }
    if id.hasPrefix("claude-") { id.removeFirst("claude-".count) }
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
    return words.joined(separator: " ")
}
