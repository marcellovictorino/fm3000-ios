import Foundation

/// INF-2928 piece 1, the captain's direction A: the phone's Tasks list is the Mac's Tasks panel (src/panels/now/rows.ts),
/// read from one board in one pass. Only groups with rows show, each in the Mac's order: priority, then oldest first, and
/// Done newest closed first, with a part under its parent in the same group. A search keeps the groups, narrows them by
/// title or key as the Mac's does, and adds the computer's older matches as Earlier.
/// INF-2764: it is built only while the list shows, and sorts positions in the board rather than copies of every task.
public struct PhoneTaskList: Sendable {
    /// Where a section comes from: one of the board's groups, or the search's older closed work.
    public enum Section: Hashable, Sendable {
        case group(PhoneTaskGroup)
        case earlier

        public var id: String {
            switch self {
            case .group(let group): group.rawValue
            case .earlier: "earlier"
            }
        }
        public var title: String {
            switch self {
            case .group(let group): group.title
            case .earlier: PhoneTaskRowWords.earlier
            }
        }
        /// The Mac's `OPEN_BY_DEFAULT`: Waiting on you, Working, Queued and Earlier always show their rows, with no count.
        public var folds: Bool { self == .group(.backlog) || self == .group(.landed) }
    }

    /// A task's row: how deep it sits under its parent, at most the Mac's `MAX_DEPTH`.
    public struct Row: Identifiable, Sendable {
        public let task: PhoneTask
        public let depth: Int
        public var id: String { task.id }
    }

    /// A section that has rows, with the cards put aside that belong to no task, which list under Waiting on you.
    public struct Part: Identifiable, Sendable {
        public let section: Section
        public let rows: [Row]
        public let aside: [PhoneCard]
        public var id: String { section.id }
        public var count: Int { rows.count + aside.count }
        /// Crew filings here not opened yet, and starts that failed (`newFilingCount`, `failedStartCount`).
        public var new: Int { rows.filter { $0.task.filingNew == true }.count }
        public var failed: Int { rows.filter { $0.task.startNotice != nil }.count }
        /// The home's dated wait line, under a Queued row only, as on the Mac.
        public func waitLine(of task: PhoneTask) -> String? {
            section == .group(.queued) && task.status == "open" ? task.queueWait?.line : nil
        }
    }

    /// The trailing words of a row (the Mac's `rowTrailing`): the project's name, where the task runs, and why that
    /// computer cannot take work now.
    public struct Trailing: Equatable, Sendable {
        public let name: String
        public let place: String
        public let outOfReach: Bool
        public let connecting: Bool
        public let reach: String
    }

    /// The board as the Mac's Tasks presents it, with each card put aside under Waiting on you (INF-1517).
    public let board: PhoneBoard?
    public let parts: [Part]
    private let projectNames: [String: String]

    public static let maxDepth = 3

    public init(board raw: PhoneBoard?, cards: [PhoneCard], query: String = "", earlier: [PhoneTask] = []) {
        let board = raw?.presenting(cards)
        self.board = board
        let tasks = board?.tasks ?? []
        let groups = board?.groups ?? [:]
        let words = Self.fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        func matches(_ title: String, _ key: String = "") -> Bool {
            words.isEmpty || Self.fold(title).contains(words) || Self.fold(key).contains(words)
        }
        var positions: [PhoneTaskGroup: [Int]] = [:]
        var groupOf: [String: PhoneTaskGroup] = [:]
        for (at, task) in tasks.enumerated() {
            guard let group = groups[task.id], matches(task.title, task.key) else { continue }
            positions[group, default: []].append(at)
            groupOf[task.id] = group
        }
        var parts: [Part] = []
        for group in PhoneTaskGroup.allCases {
            var rows: [Row] = []
            if var members = positions[group] {
                // The board's position breaks a tie, as the Mac's stable sort keeps the board's order.
                members.sort { a, b in
                    let x = tasks[a], y = tasks[b]
                    if group == .landed {
                        let (p, q) = (x.closedAt ?? 0, y.closedAt ?? 0)
                        return p != q ? p > q : a < b
                    }
                    let (p, q) = (x.priority ?? 0, y.priority ?? 0)
                    if p != q { return p < q }
                    return x.createdAt != y.createdAt ? x.createdAt < y.createdAt : a < b
                }
                var children: [String: [Int]] = [:]
                var roots: [Int] = []
                for at in members {
                    if let parent = tasks[at].parentId, groupOf[parent] == group { children[parent, default: []].append(at) }
                    else { roots.append(at) }
                }
                var placed = Set<String>()
                func place(_ at: Int, _ depth: Int) {
                    let task = tasks[at]
                    guard placed.insert(task.id).inserted else { return }
                    rows.append(Row(task: task, depth: min(depth, Self.maxDepth)))
                    for child in children[task.id] ?? [] { place(child, depth + 1) }
                }
                for at in roots { place(at, 0) }
                // A part whose parents only name each other has no root; it still lists, at the top level.
                for at in members where !placed.contains(tasks[at].id) { place(at, 0) }
            }
            let aside = group == .waiting ? (board?.tasklessMinimized(cards) ?? []).filter { matches($0.title) } : []
            if !rows.isEmpty || !aside.isEmpty { parts.append(Part(section: .group(group), rows: rows, aside: aside)) }
        }
        // A search's older closed work from the computer, minus what the groups list, newest closed first.
        if !words.isEmpty {
            let shown = Set(parts.flatMap { $0.rows.map(\.id) })
            let older = earlier.filter { !shown.contains($0.id) }.enumerated()
                .sorted { a, b in
                    let (p, q) = (a.element.closedAt ?? 0, b.element.closedAt ?? 0)
                    return p != q ? p > q : a.offset < b.offset
                }
                .map { Row(task: $0.element, depth: 0) }
            if !older.isEmpty { parts.append(Part(section: .earlier, rows: older, aside: [])) }
        }
        self.parts = parts
        let projects = board?.projects ?? []
        // The Mac's `hasSingleRegisteredRepoProject`: with one project a repository backs, its name says nothing.
        let single = projects.filter { $0.repo != nil && $0.archived != true }.count == 1
        projectNames = single ? [:] : Dictionary(projects.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
    }

    public var isEmpty: Bool { parts.isEmpty }

    public func trailing(of task: PhoneTask) -> Trailing {
        let connecting = task.place?.reach == "connecting"
        return Trailing(
            name: projectNames[task.projectId] ?? "",
            place: task.place?.where ?? "",
            outOfReach: task.place?.reach != nil && task.place?.reach != "in-reach",
            connecting: connecting,
            reach: connecting ? PhoneTaskRowWords.reachConnecting
                : task.place?.noNewWork == true ? PhoneTaskRowWords.reachNoNewWork : PhoneTaskRowWords.reachAway)
    }

    /// The one dim word a row may carry after its title (the Mac's `wordOf`).
    public static func word(_ task: PhoneTask) -> String {
        if task.startAttempt?.phase == "preparing" || task.startAttempt?.phase == "checking" || task.activity == "starting" {
            return PhoneTaskRowWords.starting
        }
        if task.startNotice != nil { return PhoneTaskRowWords.couldNotStart }
        if task.status == "active" {
            let reading = PhoneTaskFacts.status(task)
            if reading.wait == "checks" { return PhoneTaskRowWords.checks }
            if reading.waitsOn != nil { return PhoneTaskRowWords.waiting }
        }
        guard task.status == "open" else { return "" }
        if task.flags?.blocked == true { return PhoneTaskRowWords.blocked }
        if task.flags?.held == true { return PhoneTaskRowWords.held }
        if let origin = task.foundOn { return PhoneTaskRowWords.foundOn(origin) }
        return ""
    }

    /// Text as the Mac's task search compares it (`foldForSearch`): lowercase, with each typographic apostrophe and
    /// quote read as the plain one a keyboard types.
    static func fold(_ text: String) -> String {
        var folded = text.lowercased()
        for quote in ["\u{2018}", "\u{2019}", "\u{201A}", "\u{201B}", "\u{02BC}"] { folded = folded.replacingOccurrences(of: quote, with: "'") }
        for quote in ["\u{201C}", "\u{201D}", "\u{201E}", "\u{201F}"] { folded = folded.replacingOccurrences(of: quote, with: "\"") }
        return folded
    }
}
