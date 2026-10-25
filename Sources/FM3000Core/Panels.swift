import Foundation

/// The desktop's "Open pull requests" panel, as its server action stores it under `prs` in the `open-prs` extension
/// (read with `inf:plugins:db`): every open pull request the captain authored, read through the GitHub command line on the Mac.
public struct OpenPRs: Codable, Equatable {
    public struct Change: Codable, Equatable, Identifiable {
        public let host: String
        public let project: String
        public let number: Int
        public let label: String?
        public let title: String
        public let url: String
        public let draft: Bool
        public let checks: String
        public let updatedAt: String?
        public let createdAt: String?
        public var id: String { url }

        public init(host: String = "github.com", project: String, number: Int, label: String? = nil, title: String, url: String,
                    draft: Bool = false, checks: String, updatedAt: String? = nil, createdAt: String? = nil) {
            self.host = host; self.project = project; self.number = number; self.label = label; self.title = title; self.url = url
            self.draft = draft; self.checks = checks; self.updatedAt = updatedAt; self.createdAt = createdAt
        }

        /// The project's own name without its owner: `owner/name` reads as `name`.
        public var projectName: String { project.split(separator: "/").last.map(String.init) ?? project }
        public var shownLabel: String { label ?? "#\(number)" }
    }

    /// "ok", or why there are no rows: the command line is missing, signed out, or GitHub did not answer.
    public let status: String
    public let changes: [Change]
    public init(status: String, changes: [Change]) { self.status = status; self.changes = changes }

    /// Why there are no rows, in one calm line; nil when the rows are the answer.
    public var blocked: String? {
        switch status {
        case "missing": return "GitHub's command line is not installed on this Mac"
        case "signed-out": return "Sign in to GitHub's command line on this Mac"
        default: return nil
        }
    }

    public enum Group: String, CaseIterable, Identifiable {
        case ready, attention, waiting
        public var id: String { rawValue }
        public var label: String {
            switch self { case .ready: "Ready to merge"; case .attention: "Needs attention"; case .waiting: "Waiting" }
        }
    }

    /// A draft is never ready to merge, even with its checks passed.
    public static func group(of change: Change) -> Group {
        change.checks == "failed" ? .attention : (change.checks == "passed" && !change.draft ? .ready : .waiting)
    }

    public enum Age: String, CaseIterable, Identifiable {
        case today, week, older
        public var id: String { rawValue }
        public var label: String { rawValue }
        public var title: String {
            switch self { case .today: "Opened today"; case .week: "Opened within the last week, before today"; case .older: "Open longer than a week" }
        }
    }

    /// Today starts at local midnight; nil when the row does not say when it was opened.
    public static func age(of change: Change, now: Date = Date(), calendar: Calendar = .current) -> Age? {
        guard let text = change.createdAt, let opened = parseDate(text) else { return nil }
        if opened >= calendar.startOfDay(for: now) { return .today }
        return now.timeIntervalSince(opened) <= 7 * 24 * 3600 ? .week : .older
    }

    static func parseDate(_ text: String) -> Date? {
        let plain = ISO8601DateFormatter()
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return plain.date(from: text) ?? fractional.date(from: text)
    }

    public func counts(now: Date = Date()) -> [Age: Int] {
        var result: [Age: Int] = [.today: 0, .week: 0, .older: 0]
        for change in changes { if let bucket = Self.age(of: change, now: now) { result[bucket, default: 0] += 1 } }
        return result
    }

    public var failedCount: Int { changes.filter { $0.checks == "failed" }.count }
}

/// What the `machine-load` panel's Mac side saves under `latest` in its store every minute (its server.ts): the time of the reading,
/// the GPU's busy share, and memory used the way btop counts it (active plus wired pages over physical RAM).
public struct MachineSample: Codable, Equatable {
    public struct Memory: Codable, Equatable { public let usedBytes: Double; public let totalBytes: Double }
    public let at: Double?
    public let gpu: Double?
    public let memory: Memory?

    public init(at: Double?, gpu: Double?, memory: Memory?) { self.at = at; self.gpu = gpu; self.memory = memory }

    /// Used memory as a percentage of the total.
    public var memoryPercent: Double? { memory.map { $0.totalBytes > 0 ? 100 * $0.usedBytes / $0.totalBytes : 0 } }

    /// The Mac saves a reading every minute; one older than three is the Mac's last word, not its present state.
    public func isFresh(now: Double = Date().timeIntervalSince1970 * 1000) -> Bool {
        guard let at else { return false }
        return now - at < 180_000
    }
}

/// The answer of `inf:plugins:invoke` for a panel's server action.
public struct InvokeResult<T: Decodable>: Decodable {
    public let ok: Bool
    public let result: T?
    public let error: String?
}

/// The answer of `inf:plugins:db` for a `get`.
public struct StoreValue<T: Decodable>: Decodable { public let value: T? }
