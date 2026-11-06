import Foundation
import Testing
@testable import InfinitaryKit

/// INF-2764: the phone's Tasks list is built by walking the board once instead of re-sorting every task, and keeps the
/// order the list always had: live tasks first, then the rest, each newest first.
struct PhoneTaskListTests {
    private func task(_ id: String, key: String, title: String, status: String, at createdAt: Double,
                      activity: String? = nil, goal: String? = nil) -> [String: Any] {
        var row: [String: Any] = [
            "id": id, "key": key, "projectId": "proj-harbour", "parentId": NSNull(), "kind": "work", "title": title,
            "status": status, "createdAt": createdAt, "startPolicy": "when-ready", "blockedBy": [],
            "waitingCardId": NSNull(),
        ]
        if let activity { row["activity"] = activity }
        if let goal { row["goal"] = goal }
        return row
    }

    private func decode<T: Decodable>(_ value: Any) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: value))
    }

    private func board(_ tasks: [[String: Any]]) throws -> PhoneBoard {
        try decode(["seq": 41, "tasks": tasks, "projects": [["id": "proj-harbour", "name": "Harbour"]]])
    }

    /// The Mac sends the board oldest first (`sortTaskBoard`), as these rows are.
    private var rows: [[String: Any]] {
        [
            task("t-chart", key: "INF-11", title: "Chart the northern entrance", status: "done", at: 1_793_000_000_000),
            task("t-buoys", key: "INF-12", title: "Count the buoys", status: "open", at: 1_793_000_100_000),
            task("t-light", key: "INF-13", title: "Relight the harbour lamp", status: "active", at: 1_793_000_200_000,
                 activity: "running"),
            task("t-nets", key: "INF-14", title: "Mend the nets", status: "dropped", at: 1_793_000_300_000),
            task("t-tide", key: "INF-15", title: "Read the tide tables", status: "open", at: 1_793_000_400_000,
                 goal: "The harbour lamp's hours follow the tide"),
        ]
    }

    @Test func liveTasksComeFirstAndEachPartNewestFirst() throws {
        let list = PhoneTaskList(board: try board(rows), cards: [])
        #expect(list.rows.map(\.key) == ["INF-15", "INF-13", "INF-12", "INF-14", "INF-11"])
        #expect(list.members[.working]?.map(\.key) == ["INF-13"])
        #expect(list.members[.queued]?.map(\.key) == ["INF-15", "INF-12"])
        // A dropped task belongs to no group, so it lists only under a search.
        #expect(list.members[.landed]?.map(\.key) == ["INF-11"])
        #expect(list.project(of: list.rows[0]) == "Harbour")
    }

    /// A board in any other order lists the same.
    @Test func aBoardOutOfOrderListsTheSame() throws {
        let list = PhoneTaskList(board: try board(rows.reversed()), cards: [])
        #expect(list.rows.map(\.key) == ["INF-15", "INF-13", "INF-12", "INF-14", "INF-11"])
    }

    /// A search narrows the rows by key, title or goal, and the computer's older matches join them in order.
    @Test func aSearchNarrowsAndTakesInOlderMatches() throws {
        let older: PhoneTask = try decode(task("t-wreck", key: "INF-3", title: "Mark the harbour wreck", status: "done",
                                               at: 1_792_000_000_000))
        let list = PhoneTaskList(board: try board(rows), cards: [], query: "harbour", earlier: [older])
        #expect(list.rows.map(\.key) == ["INF-15", "INF-13", "INF-3"])
        #expect(list.members.isEmpty)
    }
}
