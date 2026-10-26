import Foundation

/// Daily counts of what the person does in the app, kept in `usage.json` on the phone: `{day: {event: count}}`.
/// Counts only: no text, titles, names or ids ever reach it, and nothing leaves the phone unless the person exports it.
public final class UsageLog: @unchecked Sendable {
    /// Days kept; older ones roll off on every write.
    public static let keepDays = 90
    public static let shared = UsageLog(file: defaultFile)
    public static var defaultFile: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("usage.json")
    }

    private let file: URL?
    private let lock = NSLock()
    private var days: [String: [String: Int]]

    public init(file: URL?) {
        self.file = file
        days = file.flatMap { try? Data(contentsOf: $0) }.flatMap { try? JSONDecoder().decode([String: [String: Int]].self, from: $0) } ?? [:]
    }

    /// `2026-10-26`, in the phone's own calendar day.
    public static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    public func record(_ event: String, count: Int = 1, now: Date = Date(), calendar: Calendar = .current) {
        guard count > 0 else { return }
        lock.lock(); defer { lock.unlock() }
        days[Self.dayKey(now, calendar: calendar), default: [:]][event, default: 0] += count
        let oldest = Self.dayKey(calendar.date(byAdding: .day, value: -(Self.keepDays - 1), to: now) ?? now, calendar: calendar)
        days = days.filter { $0.key >= oldest }
        if let file, let data = try? Self.encode(days) {
            try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: file, options: .atomic)
        }
    }

    /// Each event's count over the last `window` days, today included, most used first.
    public func totals(days window: Int, now: Date = Date(), calendar: Calendar = .current) -> [(event: String, count: Int)] {
        lock.lock(); defer { lock.unlock() }
        let oldest = Self.dayKey(calendar.date(byAdding: .day, value: -(window - 1), to: now) ?? now, calendar: calendar)
        var sums: [String: Int] = [:]
        for (day, events) in days where day >= oldest { for (event, n) in events { sums[event, default: 0] += n } }
        return sums.map { (event: $0.key, count: $0.value) }.sorted { ($1.count, $0.event) < ($0.count, $1.event) }
    }

    /// The whole file, for the share sheet.
    public func exportJSON() -> Data {
        lock.lock(); defer { lock.unlock() }
        return (try? Self.encode(days)) ?? Data("{}".utf8)
    }

    private static func encode(_ days: [String: [String: Int]]) throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(days)
    }
}
