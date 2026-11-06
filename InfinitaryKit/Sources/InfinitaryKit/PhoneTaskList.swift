import Foundation

/// INF-2764: the phone's Tasks list, read from one board in one pass. Its rows are the live tasks first, then the
/// rest, each newest first, which is the board's own order (oldest first, as the Mac's `sortTaskBoard` sends it and
/// `PhoneBoard.applying` keeps it) walked backwards; re-sorting a copy of every task on each board update was most of
/// the main thread's time while a reopened phone caught up.
public struct PhoneTaskList: Sendable {
    /// The board as the Mac's Tasks presents it, with each card put aside under Waiting on you (INF-1517).
    public let board: PhoneBoard?
    public let rows: [PhoneTask]
    /// Each group's rows in the list's order, filled only while no search narrows the list.
    public let members: [PhoneTaskGroup: [PhoneTask]]
    /// Cards put aside that belong to no task here, each a row of its own under Waiting on you.
    public let aside: [PhoneCard]
    private let projectNames: [String: String]

    public init(board raw: PhoneBoard?, cards: [PhoneCard], query: String = "", earlier: [PhoneTask] = []) {
        let board = raw?.presenting(cards)
        self.board = board
        let tasks = board?.tasks ?? []
        // A board that is not oldest first is put in that order once, so the walk below still lists it right.
        let ordered = zip(tasks, tasks.dropFirst()).allSatisfy { $0.createdAt <= $1.createdAt }
            ? tasks : tasks.sorted { $0.createdAt < $1.createdAt }
        var live: [PhoneTask] = [], rest: [PhoneTask] = []
        for task in ordered.reversed() where query.isEmpty
            || "\(task.key) \(task.title) \(task.goal ?? "")".localizedCaseInsensitiveContains(query) {
            if Self.live(task) { live.append(task) } else { rest.append(task) }
        }
        var rows = live + rest
        // A search's older matches from the computer join the rows the board holds, in the same order.
        if !earlier.isEmpty {
            let ids = Set(rows.map(\.id))
            rows = (rows + earlier.filter { !ids.contains($0.id) }).sorted {
                Self.live($0) != Self.live($1) ? Self.live($0) : $0.createdAt > $1.createdAt
            }
        }
        self.rows = rows
        if query.isEmpty, let groups = board?.groups {
            var members: [PhoneTaskGroup: [PhoneTask]] = [:]
            for task in rows { if let group = groups[task.id] { members[group, default: []].append(task) } }
            self.members = members
        } else {
            members = [:]
        }
        aside = board?.tasklessMinimized(cards) ?? []
        projectNames = Dictionary((board?.projects ?? []).map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
    }

    public func project(of task: PhoneTask) -> String? { projectNames[task.projectId] }

    private static func live(_ task: PhoneTask) -> Bool { task.status == "open" || task.status == "active" }
}
