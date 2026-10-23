import Foundation

public struct CardAction: Codable, Equatable, Identifiable {
    public let id: String
    public let label: String
    public let variant: String?
    public let `default`: Bool?
    public let keepsOpen: Bool?
    public var isDefault: Bool { `default` == true }
}

public struct Card: Codable, Equatable, Identifiable {
    public let id: String
    public let taskId: String?
    public let author: String
    public let priority: Double
    public let title: String
    public let meta: String
    public let body: String
    public let actions: [CardAction]
    public let status: String
    public let createdAt: Double
    public let holdsPlace: Bool?
    public let asking: Bool?
}

public struct ThreadMessage: Codable, Equatable, Identifiable {
    public let id: Double
    public let cardId: String
    public let who: String
    public let text: String
    public let at: Double
}

public struct CardThread: Codable, Equatable {
    public let cardId: String
    public let messages: [ThreadMessage]
}

/// What `inf:cards:act` answers: the effect only a Mac window can show, or the Mac's refusal.
public struct ActResult: Codable, Equatable {
    public struct Effect: Codable, Equatable { public let kind: String; public let target: String? }
    public let effect: Effect?
    public let refusal: String?
}

public struct FeedLine: Codable, Equatable, Identifiable {
    public let kind: String
    public let text: String
    public let at: Double
    public let taskKey: String?
    public let event: String?
    public var id: String { "\(at)-\(text)" }
}

public struct BoardTask: Codable, Equatable, Identifiable, Hashable {
    public let id: String
    public let key: String
    public let projectId: String
    public let title: String
    public let kind: String
    public let status: String
    public let activity: String?
    public let assignee: String?
    public let model: String?
    public let waitingCardId: String?
    public let updatedAt: Double

    public init(id: String, key: String, projectId: String, title: String, kind: String, status: String, activity: String?,
                assignee: String?, model: String?, waitingCardId: String?, updatedAt: Double) {
        self.id = id; self.key = key; self.projectId = projectId; self.title = title; self.kind = kind; self.status = status
        self.activity = activity; self.assignee = assignee; self.model = model; self.waitingCardId = waitingCardId; self.updatedAt = updatedAt
    }
}

public struct BoardProject: Codable, Equatable, Identifiable {
    public struct Counts: Codable, Equatable { public let needsYou: Int; public let open: Int; public let active: Int }
    public let id: String
    public let key: String
    public let name: String
    public let archived: Bool
    public let counts: Counts
}

public struct Board: Codable, Equatable {
    public let projects: [BoardProject]
    public let tasks: [BoardTask]
}

/// The line on a card that opens its thread, Slack-style: "No replies yet", "1 reply", "3 replies".
public func repliesLabel(_ count: Int) -> String {
    count == 0 ? "No replies yet" : (count == 1 ? "1 reply" : "\(count) replies")
}

/// A column of the task board, by task status, as the desktop board groups them.
public struct BoardColumn: Equatable, Identifiable {
    public let status: String
    public let title: String
    public let tasks: [BoardTask]
    public var id: String { status }
}

/// Columns Open, Active and Done always; Dropped only when something was dropped. Newest change first in each.
public func boardColumns(_ tasks: [BoardTask]) -> [BoardColumn] {
    let order: [(String, String, Bool)] = [("open", "Open", true), ("active", "Active", true), ("done", "Done", true), ("dropped", "Dropped", false)]
    return order.compactMap { status, title, always in
        let inColumn = tasks.filter { $0.status == status }.sorted { $0.updatedAt > $1.updatedAt }
        return always || !inColumn.isEmpty ? BoardColumn(status: status, title: title, tasks: inColumn) : nil
    }
}

public enum TasksLayout { case list, board }

/// Which layout Tasks shows: what the captain picked with the toggle, else the board in landscape and the list in portrait.
public func tasksLayout(picked: TasksLayout?, landscape: Bool) -> TasksLayout {
    picked ?? (landscape ? .board : .list)
}

/// What `inf:tasks:detail` says about a task, as far as the phone shows it. Every field the phone does not show is ignored.
public struct TaskDetail: Codable, Equatable {
    public struct Posture: Codable, Equatable { public let state: String; public let reason: String }
    public struct Delivery: Codable, Equatable {
        public struct Checks: Codable, Equatable { public let name: String; public let state: String }
        public let mode: String?
        public let prUrl: String?
        public let prNumber: Int?
        public let ci: String?
        public let runChecks: Checks?
    }
    public let id: String
    public let key: String
    public let title: String
    public let goal: String?
    public let status: String
    public let activity: String?
    public let workPosture: Posture?
    public let assignee: String?
    public let model: String?
    public let modelLabel: String?
    public let waitingCardId: String?
    public let outcome: String?
    public let problem: String?
    public let delivery: Delivery?
    public let updatedAt: Double
}

/// One line of the crewmate's own record (`inf:tasks:crewmate`): what it said, reported, did, or was told.
public struct CrewLine: Codable, Equatable, Identifiable {
    public let kind: String
    public let id: String
    public let at: Double
    public let text: String?
    public let summary: String?
    public let title: String?
    public let name: String?
    public let target: String?
    public let from: String?
}

public struct CrewLog: Codable, Equatable {
    public let taskId: String
    public let earlier: Int
    public let lines: [CrewLine]
}

public struct CrewLive: Codable, Equatable { public let taskId: String; public let text: String; public let since: Double? }

public extension CrewLine {
    /// The words a person reads for this line, or nil when the line is machinery (a tool call, a plan, a stop).
    var readable: (who: String, text: String)? {
        switch kind {
        case "said": return text.map { ("Crewmate", $0) }
        case "report": return ("Report", [summary, text].compactMap { $0 }.joined(separator: "\n\n"))
        case "sent": return text.map { (from == "captain" ? "You" : (from ?? "Firstmate").capitalized, $0) }
        case "brief": return text.map { ("Brief", $0) }
        case "card": return title.map { ("Card", $0) }
        case "change": return title.map { ("Change", $0) }
        default: return nil
        }
    }
}

public struct SteerResult: Codable, Equatable { public let ok: Bool; public let text: String? }
