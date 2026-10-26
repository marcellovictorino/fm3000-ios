import Foundation

public struct CardAction: Codable, Equatable, Identifiable {
    public let id: String
    public let label: String
    public let variant: String?
    public let `default`: Bool?
    public let keepsOpen: Bool?
    public var isDefault: Bool { `default` == true }
}

/// The words the captain wrote in a card's "anything to add?" field travel with a choice as one more answer, the way the Mac's
/// footer sends them (`withAnythingElse` in src/shared/cards.ts): `inf:cards:act`'s fourth argument. Nil when there is nothing to add.
public func choiceValue(words: String) -> JSONValue? {
    let written = String(words.trimmingCharacters(in: .whitespacesAndNewlines).prefix(4_000))
    guard !written.isEmpty else { return nil }
    return .object(["answers": .array([.object(["name": .string("anything_else"), "values": .array([]), "changed": .bool(true), "written": .string(written)])])])
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
    public let model: String?
    /// Put aside on a Mac or a phone: the card stays open, off the stack, until its crewmate changes it or someone brings it back.
    public var minimized: Bool?
    /// What the card waits on while it is off the stage: its author's `answer` to a reply, or its `close-out`.
    public var awaiting: String?
    /// Set while the author answers a reply under the card: the card stays on the stage meanwhile.
    public var sentBackAt: Double?
}

public extension Card {
    var isPutAside: Bool { minimized == true }
    /// The Mac's rule (`onStage` in src/shared/cards.ts): every card but one awaiting its author's first close-out stays on the stage.
    var onStage: Bool { awaiting == nil || sentBackAt != nil }
    /// A decision that is the captain's turn: it has choices, its author owes nothing, and it is not put aside (`isReadyDecision`).
    var waitsOnYou: Bool { !actions.isEmpty && awaiting == nil && !isPutAside }
    /// Its author owes the captain an answer to a reply: the phone's typing dots.
    var authorIsAnswering: Bool { awaiting == "answer" }
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
    // What the desktop's one grouping rule reads (`nowGroupOf` in Infinitary's src/shared/nowPanel.ts).
    public struct RequiredAction: Codable, Equatable, Hashable { public let cardId: String?; public let state: String? }
    public struct StartAttempt: Codable, Equatable, Hashable { public let phase: String }
    public let parentId: String?
    public let startPolicy: String?
    public let minimizedCardId: String?
    public let requiredAction: RequiredAction?
    public let startAttempt: StartAttempt?

    public init(id: String, key: String, projectId: String, title: String, kind: String, status: String, activity: String?,
                assignee: String?, model: String?, waitingCardId: String?, updatedAt: Double,
                parentId: String? = nil, startPolicy: String? = nil, minimizedCardId: String? = nil,
                requiredAction: RequiredAction? = nil, startAttempt: StartAttempt? = nil) {
        self.parentId = parentId; self.startPolicy = startPolicy; self.minimizedCardId = minimizedCardId
        self.requiredAction = requiredAction; self.startAttempt = startAttempt
        self.id = id; self.key = key; self.projectId = projectId; self.title = title; self.kind = kind; self.status = status
        self.activity = activity; self.assignee = assignee; self.model = model; self.waitingCardId = waitingCardId; self.updatedAt = updatedAt
    }
}

public extension BoardTask {
    /// Queued or waiting for the captain's go: no crewmate exists yet, so nobody could read a message.
    var notStarted: Bool { status == "open" && assignee == nil && startAttempt == nil }
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
    public init(projects: [BoardProject], tasks: [BoardTask]) { self.projects = projects; self.tasks = tasks }
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
    public struct Reasoning: Codable, Equatable { public let level: String }
    public let reasoning: Reasoning?
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

public struct OkResult: Codable, Equatable { public let ok: Bool }
public struct SteerResult: Codable, Equatable { public let ok: Bool; public let text: String? }

public extension Board {
    /// The projects worth a pill (not archived), each with how many tasks it has on the board.
    var projectPills: [(project: BoardProject, count: Int)] {
        projects.filter { !$0.archived }.map { project in (project, tasks.filter { $0.projectId == project.id }.count) }
    }

    /// Only one project's tasks, or everything when none is picked. A picked project that is gone shows everything.
    func filtered(by projectId: String?) -> Board {
        guard let projectId, projects.contains(where: { $0.id == projectId }) else { return self }
        return Board(projects: projects.filter { $0.id == projectId }, tasks: tasks.filter { $0.projectId == projectId })
    }
}

/// What `inf:computers:resources` answers: one reading per computer the home can see (this Mac and any others).
public struct ComputerResources: Codable, Equatable {
    public struct Computer: Codable, Equatable, Identifiable {
        public struct Observation: Codable, Equatable {
            public struct CPU: Codable, Equatable { public let logicalCpus: Int; public let idleFraction: Double }
            public struct Memory: Codable, Equatable {
                public let totalBytes: Int
                public let freeBytes: Int
                public let availableBytes: Int?
                public let purgeableBytes: Int?
                public let fileBackedBytes: Int?
                public let inactiveBytes: Int?
                public let speculativeBytes: Int?
                public let memoryPressure: String?
            }
            public let sampleMs: Double
            public let cpu: CPU
            public let memory: Memory
        }
        public struct Reading: Codable, Equatable {
            public let status: String
            public let observation: Observation?
            public let ageMs: Double?
            public let memoryUsedBytes: Int?
            public let reason: String?
        }
        public let computerId: String?
        public let label: String
        public let reading: Reading
        public var id: String { computerId ?? label }

        public var cpuUsed: Double? { reading.observation.map { 1 - $0.cpu.idleFraction } }
        /// Memory in use as a fraction: the Mac's own figure when it gives one, else total minus what is available.
        public var memoryUsed: Double? {
            guard let memory = reading.observation?.memory, memory.totalBytes > 0 else { return nil }
            let used = reading.memoryUsedBytes ?? (memory.totalBytes - (memory.availableBytes ?? memory.freeBytes))
            return min(1, max(0, Double(used) / Double(memory.totalBytes)))
        }
    }
    public let computers: [Computer]
}


/// The desktop's five groups for a task (waiting on you, working, queued, backlog, done), ported from `nowGroupOf` and
/// `nowGroupsOf` in Infinitary's src/shared/nowPanel.ts so the phone's counts are the desktop's.
public enum NowGroup: String, CaseIterable { case waiting, working, queued, backlog, landed }

public func nowGroupOf(_ task: BoardTask) -> NowGroup? {
    if task.minimizedCardId != nil { return .waiting }
    if task.requiredAction != nil, task.status == "open" || task.status == "active" { return .waiting }
    let preparing = task.startAttempt?.phase == "preparing" || task.startAttempt?.phase == "checking"
    if (preparing || (task.status == "active" && task.activity == "starting")), task.status != "done", task.status != "dropped", task.waitingCardId == nil {
        return .queued
    }
    switch task.status {
    case "done": return task.kind == "work" || task.requiredAction != nil ? .landed : nil
    case "active": return task.waitingCardId != nil ? .waiting : .working
    case "open": return task.waitingCardId != nil ? .waiting : (task.startPolicy == "on-request" ? .backlog : .queued)
    default: return nil  // dropped, or a status this app does not know
    }
}

/// Each task's visible group; a working task's live parents and live children stay in Working with it.
public func nowGroups(_ tasks: [BoardTask]) -> [String: NowGroup] {
    let byId = Dictionary(tasks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    func live(_ task: BoardTask?) -> BoardTask? { task.flatMap { $0.status != "done" && $0.status != "dropped" ? $0 : nil } }
    func liveParent(_ task: BoardTask) -> BoardTask? { task.parentId.flatMap { live(byId[$0]) } }
    var trees = Set<String>()
    for task in tasks where nowGroupOf(task) == .working {
        var member = live(task)
        while let current = member { trees.insert(current.id); member = liveParent(current) }
    }
    for task in tasks where live(task) != nil {
        var member = liveParent(task)
        while let current = member {
            if trees.contains(current.id) { trees.insert(task.id); break }
            member = liveParent(current)
        }
    }
    var result: [String: NowGroup] = [:]
    for task in tasks {
        guard let group = nowGroupOf(task) else { continue }
        result[task.id] = trees.contains(task.id) && group != .waiting ? .working : group
    }
    return result
}

public extension BoardTask {
    func withMinimizedCard(_ id: String?) -> BoardTask {
        BoardTask(id: self.id, key: key, projectId: projectId, title: title, kind: kind, status: status, activity: activity, assignee: assignee,
                  model: model, waitingCardId: waitingCardId, updatedAt: updatedAt, parentId: parentId, startPolicy: startPolicy, minimizedCardId: id,
                  requiredAction: requiredAction, startAttempt: startAttempt)
    }
}

/// The board as the Mac's window presents it (`presentTask` in src/shared/taskWaiting.ts). The core never sends `minimizedCardId`; a
/// window derives it from the cards. A task whose card is put aside waits on you, unless its crewmate still works or owes a reply.
public func presentTasks(_ tasks: [BoardTask], cards: [Card]) -> [BoardTask] {
    tasks.map { task in
        let associated = cards.filter { $0.taskId == task.id || $0.id == task.waitingCardId }
        let authorWorking = task.status == "active" && (task.activity == "running" || associated.contains { $0.awaiting == "answer" })
        let aside = authorWorking ? nil : associated.first { $0.isPutAside }?.id
        return aside == task.minimizedCardId ? task : task.withMinimizedCard(aside)
    }
}

/// What the Cards strip counts: tasks Working and Queued as the desktop groups them; Waiting on you is the open decision cards
/// that are the captain's turn, and Put aside is the cards set aside for later (never counted as waiting).
public struct CardsTally: Equatable {
    public var working = 0, waiting = 0, queued = 0, aside = 0
    public init(cards: [Card], board: Board?) {
        waiting = cards.filter(\.waitsOnYou).count
        aside = cards.filter(\.isPutAside).count
        let groups = nowGroups(presentTasks(board?.tasks ?? [], cards: cards))
        working = groups.values.filter { $0 == .working }.count
        queued = groups.values.filter { $0 == .queued }.count
    }
}

public enum CardsFilter: String, CaseIterable { case working, waiting, aside, queued }

/// The tasks a Working or Queued chip lists, newest change first: exactly the ones its count counts. Waiting lists cards, not tasks.
public func tasksIn(_ filter: CardsFilter, board: Board?, cards: [Card] = []) -> [BoardTask] {
    guard filter == .working || filter == .queued, let board else { return [] }
    let tasks = presentTasks(board.tasks, cards: cards)
    let groups = nowGroups(tasks)
    let want: NowGroup = filter == .working ? .working : .queued
    return tasks.filter { groups[$0.id] == want }.sorted { $0.updatedAt > $1.updatedAt }
}

/// The cards the Cards list shows: with no chip, every card on the stage that is not put aside; Waiting on you, the decisions that are
/// the captain's turn; Put aside, the cards set aside, newest first. Working and Queued list tasks instead (`tasksIn`).
public func filterCards(_ cards: [Card], by filter: CardsFilter?, board: Board?) -> [Card] {
    switch filter {
    case nil: return cards.filter { $0.onStage && !$0.isPutAside }
    case .waiting: return cards.filter(\.waitsOnYou)
    case .aside: return cards.filter(\.isPutAside).sorted { $0.createdAt > $1.createdAt }
    case .working?, .queued?: return []
    }
}
