import Foundation

public struct PhoneLastTurn: Decodable, Sendable {
    public let you: String
    public let reply: Reply?
    /// INF-1771: the round before the newest, absent from an older Mac and null before a second message.
    public let previous: PhoneLastRound?
    public struct Reply: Decodable, Sendable {
        public let text: String
        public let problem: Bool?
        /// INF-1517: `completed` lets the line fade after its reading time; anything else stays (docs/composer.md).
        public let eligibility: String?
        /// The closing words as written, line breaks kept, when they differ from `text`.
        public let words: String?
    }
}

/// One round of the last turn: a message of the captain's and the reply line kept beside it.
public struct PhoneLastRound: Decodable, Sendable {
    public let you: String
    public let reply: PhoneLastTurn.Reply?
    public init(you: String, reply: PhoneLastTurn.Reply?) { self.you = you; self.reply = reply }
}

public struct PhoneMove: Decodable, Sendable {
    public let ok: Bool
    public let text: String?
}

/// The Mac owns state, allowed moves and timeline wording. Unknown fields stay with the Mac.
public struct PhoneTask: Decodable, Identifiable, Sendable {
    public let id: String
    public let key: String
    public let projectId: String
    public let parentId: String?
    public let kind: String
    public let title: String
    public internal(set) var status: String
    public let createdAt: Double
    public let startPolicy: String?
    /// The home’s dated start-wait line, shared with its first mate and desktop views.
    /// Absent while a start attempt stands, as the host leaves it out then (`taskProtocol.ts`); the start intent's fold
    /// clears it the same way.
    public internal(set) var queueWait: QueueWait?
    public struct QueueWait: Decodable, Sendable { public let line: String; public let since: Double? }
    public internal(set) var startAttempt: StartAttempt?
    public let requiredAction: RequiredAction?
    public internal(set) var activity: String?
    public let tier: String?
    public let executionDeviceId: String?
    public let reviewOf: String?
    public let program: Bool?
    public let workPosture: WorkPosture?
    public struct WorkPosture: Decodable, Sendable {
        public let state: String
        public let reason: String
        /// The account's typed cut-off while `access` stands on it; the record reads only its class.
        public let hold: Hold?
        public struct Hold: Decodable, Sendable { public let `class`: String? }
    }
    public let goal: String?
    public let startedAt: Double?
    public internal(set) var moves: [String: PhoneMove]?
    public let outcomeSummary: String?
    public let waitingCardId: String?
    public let answerNoteId: String?
    public let answerSince: Double?
    public let assignee: String?
    public let modelLabel: String?
    public let brief: String?
    public let outcome: String?
    public let problem: String?
    public let events: [Event]?
    public let intent: Intent?
    public let plan: Plan?
    public let place: Place?
    public let blockedBy: [String]
    /// INF-1926: the rest of what the desktop's crew summary reads (src/shared/taskFacts.ts), each optional so an older
    /// Mac's rows still decode: the board row's lifecycle facts, then the record's own reading (`.detail`).
    public internal(set) var closedReason: String?
    public let flags: Flags?
    public struct Flags: Decodable, Sendable { public let blocked: Bool; public let held: Bool; public let needsYou: Bool? }
    public let children: Children?
    public struct Children: Decodable, Sendable { public let total: Int; public let closed: Int }
    public let startNotice: StartNotice?
    public struct StartNotice: Decodable, Sendable { public let reason: String }
    public let waitingCardMerges: Bool?
    public let blockedSince: [String: Double]?
    public let model: String?
    public let delivery: Delivery?
    public let activityLog: [ActivityRow]?
    public let said: ActionLine?
    public let reasoning: Reasoning?
    /// INF-1517: a card of this task put aside on the Mac, set only by `PhoneBoard.presenting`, as the Mac's own
    /// `presentTask` (src/shared/taskWaiting.ts) sets it for presentation alone.
    public internal(set) var minimizedCardId: String?
    /// INF-2928 piece 1: what the Mac's Tasks rows read beyond the facts above (src/panels/now/rows.ts), each optional so
    /// an older Mac's rows still decode: the order (`priority`, 0 urgent to 3 low, then `createdAt`; Done by `closedAt`),
    /// the crew filing's origin and whether it is new, and started work sent back to the backlog.
    public let priority: Double?
    public let closedAt: Double?
    public let foundOn: String?
    public let filingNew: Bool?
    public let backlogSince: Double?
    /// INF-2935, piece 2: what the Mac's task record reads beyond the facts above (src/shared/tasks.ts
    /// `taskDetailSchema`), each optional so an older Mac's record still decodes. The board row carries the first four.
    public let blocks: [String]?
    public let replacedBy: String?
    public let captainWait: Bool?
    public let waits: [Wait]?
    public let repo: Repo?
    public let cards: [CardRow]?
    public let runsOn: RunsOn?
    public let policies: Policies?
    public let rigor: String?
    public let dropEffects: DropEffects?
    public let closing: Closing?
    public let hold: Hold?
    public let filing: Filing?
    public let asks: [Ask]?
    public let skippedPlanBecause: String?
    public let browser: Browser?
    public let deliverable: String?
    /// A standing wait's owner fact (`taskWaitSchema`, src/shared/taskWaits.ts).
    public struct Wait: Decodable, Sendable {
        public let id: String
        public let kind: String
        public let label: String
        public let since: Double?
        public let next: Next?
        public struct Next: Decodable, Sendable { public let kind: String; public let at: Double }
    }
    public struct Repo: Decodable, Sendable { public let name: String; public let branch: String? }
    /// One card the task showed, newest first: open on the stage or put aside, or closed with how it ended.
    public struct CardRow: Decodable, Identifiable, Sendable {
        public let id: String
        public let kind: String
        public let title: String
        public let state: String
        public let minimized: Bool?
        public let ending: String?
        public let at: Double
    }
    public struct RunsOn: Decodable, Sendable { public let label: String; public let source: String; public let reason: String? }
    public struct Policies: Decodable, Sendable {
        public let delivery: Choice<String>
        public let autonomy: Choice<Bool>
        public let rigor: Care
        public struct Choice<Value: Decodable & Sendable>: Decodable, Sendable { public let value: Value; public let source: String }
        public struct Care: Decodable, Sendable { public let value: String; public let source: String; public let requested: String? }
    }
    /// What Drop task would affect; present only while Drop task applies.
    public struct DropEffects: Decodable, Sendable {
        public let parts: [Part]
        public let waiting: [Named]
        public let underway: [Named]
        public struct Part: Decodable, Sendable { public let key: String; public let title: String; public let started: Bool? }
        public struct Named: Decodable, Sendable { public let key: String; public let title: String }
    }
    public struct Closing: Decodable, Sendable { public let at: Double; public let note: String? }
    public struct Hold: Decodable, Sendable { public let title: String; public let text: String }
    public struct Filing: Decodable, Sendable { public let why: String; public let originKey: String; public let verdict: String? }
    public struct Ask: Decodable, Identifiable, Sendable { public let id: String; public let at: Double; public let text: String }
    /// The task's own browser on its Mac; the record reads only whether the captain holds it.
    public struct Browser: Decodable, Sendable { public let state: String; public let control: String? }
    public var canSteer: Bool { status == "active" && startedAt != nil }
    /// The Mac's `nowGroupOf` (src/shared/nowPanel.ts) through its generated table. A note's answer, like a card put
    /// aside, lists under Waiting on you whatever the task's state, as the table's minimized input does.
    public var group: PhoneTaskGroup? {
        .reading(status: status, work: kind == "work", required: requiredAction != nil,
                 waiting: waitingCardId != nil,
                 starting: startAttempt?.phase == "preparing" || startAttempt?.phase == "checking" || (status == "active" && activity == "starting"),
                 onRequest: startPolicy == "on-request", minimized: minimizedCardId != nil || answerNoteId != nil,
                 backlog: backlogSince != nil)
    }
    public struct StartAttempt: Decodable, Sendable {
        public let phase: String
        /// When the attempt was accepted, for the record's slow-start line; absent from an older Mac.
        public let since: Double?
    }
    public struct RequiredAction: Decodable, Sendable { public let state: String?; public let result: String? }
    public var state: String {
        if status == "done" { return "Done" }
        if status == "dropped" { return "Dropped" }
        if waitingCardId != nil || answerNoteId != nil { return "Waiting on you" }
        if startAttempt?.phase == "preparing" || startAttempt?.phase == "checking" { return "Starting" }
        if !blockedBy.isEmpty { return "Waiting on another task" }
        if status == "open" { return startPolicy == "on-request" ? "Backlog" : "Queued" }
        switch activity {
        case "running": return "Working"
        case "starting": return "Starting"
        case "interrupted": return "Interrupted"
        // INF-2553: an interrupt the phone sent and its computer has not shown yet.
        case "stopping": return "Stopping"
        case "idle": return "Idle"
        default: return "Not started"
        }
    }
    public struct Place: Decodable, Sendable {
        public let `where`: String
        public let name: String?
        public let reach: String?
        public let noNewWork: Bool?
    }
    public struct Intent: Decodable, Sendable { public let userWords: String }
    public struct Plan: Decodable, Sendable {
        public let items: [Item]
        public let at: Double?
        public struct Item: Decodable, Sendable {
            public let label: String
            public let state: String
            public let short: String?
            public let since: Double?
        }
    }
    /// The change where the project lives, its checks and a review's verdict (src/shared/tasks.ts `taskDeliveryViewSchema`).
    public struct Delivery: Decodable, Sendable {
        public let prUrl: String?
        public let prNumber: Int?
        public let changeLabel: String?
        public let headSha: String?
        public let ci: String?
        public let ciAt: Double?
        public let checks: CheckSnapshot?
        public let ciStartedAt: Double?
        public let ciFinishedAt: Double?
        public let runChecks: RunChecks?
        public let reviewVerdict: String?
        public let reviewRisk: String?
        /// How the work reaches its project (`direct-pr`, `queue-pr`, `local-only`, `in-place`).
        public let mode: String?
        public let landedMode: String?
        public struct CheckSnapshot: Decodable, Sendable {
            public let headSha: String
            public let items: [Item]
            public let complete: Bool?
            public let problem: String?
            public let absenceDeclared: Bool?
            public struct Item: Decodable, Sendable { public let name: String; public let state: String }
        }
        public struct RunChecks: Decodable, Sendable {
            public let state: String
            public let startedAt: Double?
            public let finishedAt: Double?
            public let at: Double
        }
    }
    /// One row of the record's Activity; `from` is set on a row another task wrote.
    public struct ActivityRow: Decodable, Sendable {
        public let id: Int?
        public let at: Double
        public let kind: String
        public let text: String
        public let from: From?
        public let actions: [ActionLine]?
        /// The minor events folded under the row, oldest first.
        public let folded: [Folded]?
        public struct Folded: Decodable, Sendable { public let at: Double; public let kind: String; public let text: String }
        public struct From: Decodable, Sendable { public let id: String; public let key: String }
    }
    public struct ActionLine: Decodable, Sendable { public let at: Double; public let text: String }
    public struct Reasoning: Decodable, Sendable { public let level: String; public let lower: String? }
    public struct Event: Decodable, Identifiable, Sendable {
        public let id: Int
        public let at: Double
        public let actor: String
        public let kind: String
        public let text: String
    }
}

public struct PhoneBoard: Decodable, Sendable {
    public let seq: Int
    public internal(set) var tasks: [PhoneTask]
    public let projects: [Project]
    public let links: [Link]?
    public struct Link: Decodable, Sendable { public let fromId: String; public let toId: String; public let type: String }
    public struct Project: Decodable, Sendable {
        public let id: String
        public let name: String
        /// Whether a repository backs the project, and whether it is archived: a row leaves out the project's name where
        /// only one such project could be meant (the Mac's `hasSingleRegisteredRepoProject`).
        public let repo: Repo?
        public let archived: Bool?
        public struct Repo: Decodable, Sendable { public let name: String }
    }

    /// The Mac's `applyTaskBoardDelta` (src/shared/tasks.ts): this board when the delta is older, the next board when
    /// the delta's base is this board's seq, and nil on a gap, which resyncs from a full read (INF-1854: re-reading
    /// a large board on every change stalled the scene).
    public func applying(_ delta: PhoneBoardDelta) -> PhoneBoard? {
        if delta.seq <= seq { return self }
        guard delta.baseSeq == seq else { return nil }
        let removed = Set(delta.removed), upserted = Set(delta.upserts.map(\.id))
        let rows = tasks.filter { !removed.contains($0.id) && !upserted.contains($0.id) } + delta.upserts
        func key(_ link: Link) -> String { "\(link.fromId) \(link.toId) \(link.type)" }
        let unlinked = Set(delta.links.removed.map(key)), linked = Set(delta.links.added.map(key))
        let edges = (links ?? []).filter { !unlinked.contains(key($0)) && !linked.contains(key($0)) } + delta.links.added
        return PhoneBoard(seq: delta.seq,
                          tasks: rows.sorted { $0.createdAt == $1.createdAt ? $0.id < $1.id : $0.createdAt < $1.createdAt },
                          projects: delta.projects, links: edges.sorted { key($0) < key($1) })
    }

    /// INF-2773: a run of deltas read in one catch-up, folded with one sort at the end. It gives the board that
    /// applying them one at a time gives, keyed by id and link as the Mac's `applyTaskBoardDelta` is: an older delta
    /// is passed over, and a gap anywhere is nil, which resyncs from a full read.
    public func applying(run deltas: [PhoneBoardDelta]) -> PhoneBoard? {
        guard deltas.contains(where: { $0.seq > seq }) else { return self }
        func key(_ link: Link) -> String { "\(link.fromId) \(link.toId) \(link.type)" }
        var rows = Dictionary(tasks.map { ($0.id, $0) }, uniquingKeysWith: { _, later in later })
        var edges = Dictionary((links ?? []).map { (key($0), $0) }, uniquingKeysWith: { _, later in later })
        var at = seq, projects = self.projects
        for delta in deltas where delta.seq > at {
            guard delta.baseSeq == at else { return nil }
            for id in delta.removed { rows[id] = nil }
            for task in delta.upserts { rows[task.id] = task }
            for link in delta.links.removed { edges[key(link)] = nil }
            for link in delta.links.added { edges[key(link)] = link }
            at = delta.seq; projects = delta.projects
        }
        return PhoneBoard(seq: at,
                          tasks: rows.values.sorted { $0.createdAt == $1.createdAt ? $0.id < $1.id : $0.createdAt < $1.createdAt },
                          projects: projects, links: edges.values.sorted { key($0) < key($1) })
    }

    /// INF-1517: the Mac's `presentTask` rule (src/shared/taskWaiting.ts, docs/task-record.md "Minimized cards in
    /// Tasks") for a card put aside: its task lists under Waiting on you, unless the task is active and its author still
    /// works or owes the card an answer. Presentation only; the card stays minimized until a row brings it back.
    public func presenting(_ cards: [PhoneCard]) -> PhoneBoard {
        var board = self
        board.tasks = tasks.map { task in
            let associated = { (card: PhoneCard) in card.taskID == task.id || card.id == task.waitingCardId }
            let authorWorking = task.status == "active" && (task.workPosture?.state == "active"
                || (task.workPosture == nil && task.activity == "running")
                || cards.contains { associated($0) && $0.awaiting == "answer" })
            var shown = task
            shown.minimizedCardId = authorWorking ? nil : cards.first { $0.minimized && associated($0) }?.id
            return shown
        }
        return board
    }

    /// The cards put aside that belong to no task here, each listed as its own row titled by the card, as the Mac's
    /// `presentBoard` does; a card whose task the board does not hold gets none.
    public func tasklessMinimized(_ cards: [PhoneCard]) -> [PhoneCard] {
        cards.filter { card in
            card.minimized && card.taskID == nil && !tasks.contains { $0.minimizedCardId == card.id }
        }
    }

    /// The minimized cards a task's row brings back: every card of the task put aside, as the Mac's row does.
    public static func minimized(of task: PhoneTask, in cards: [PhoneCard]) -> [PhoneCard] {
        cards.filter { $0.minimized && ($0.taskID == task.id || $0.id == task.waitingCardId || $0.id == task.minimizedCardId) }
    }

    /// Keep a working parent and its live parts together, as the Mac's Tasks panel does (`nowGroupsOf`): the tree is live
    /// work only, so a closed part keeps its own group and Working never lists finished work.
    public var groups: [String: PhoneTaskGroup] {
        let byID = Dictionary(tasks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        func live(_ task: PhoneTask?) -> PhoneTask? { task.flatMap { $0.status == "done" || $0.status == "dropped" ? nil : $0 } }
        func liveParent(_ task: PhoneTask) -> PhoneTask? { live(task.parentId.flatMap { byID[$0] }) }
        var working = Set<String>()
        for task in tasks where task.group == .working {
            var member = live(task)
            while let next = member, working.insert(next.id).inserted { member = liveParent(next) }
        }
        for task in tasks where live(task) != nil {
            var member = liveParent(task)
            var visited = Set<String>()
            while let next = member, visited.insert(next.id).inserted {
                if working.contains(next.id) { working.insert(task.id); break }
                member = liveParent(next)
            }
        }
        return Dictionary(uniqueKeysWithValues: tasks.compactMap { task in
            guard let group = task.group else { return nil }
            return (task.id, working.contains(task.id) && group != .waiting ? .working : group)
        })
    }
}

/// What changed between two boards, as the Mac pushes it above its delta trigger (`taskBoardDeltaSchema`).
public struct PhoneBoardDelta: Decodable, Sendable {
    public let baseSeq: Int
    public let seq: Int
    public let upserts: [PhoneTask]
    public let removed: [String]
    public let projects: [PhoneBoard.Project]
    public let links: Links
    public struct Links: Decodable, Sendable { public let added: [PhoneBoard.Link]; public let removed: [PhoneBoard.Link] }
}

public struct PhoneCrew: Decodable, Sendable {
    public let taskId: String
    public let earlier: Int
    public let lines: [Line]
    public struct Line: Decodable, Identifiable, Sendable {
        public let id: String
        public let kind: String
        public let text: String?
        public let title: String?
        public let summary: String?
        public let from: String?
        public let name: String?
        public let target: String?
        public let reading: String?
        public let result: Result?
        public var words: String {
            text ?? title ?? reading ?? (kind == "compacted" ? "The conversation was shortened to fit." : kind == "stopped" ? "The turn was interrupted." : kind)
        }
        public struct Result: Decodable, Sendable {
            public let ref: String
            public let preview: String
            public let lines: Int
        }
    }
}

public struct PhoneCrewLive: Decodable, Sendable {
    public let text: String
    public let since: Double?
}
public struct PhoneResultText: Decodable, Sendable {
    public let text: String
    public let cut: Int
}

public struct PhoneAnswer: Decodable, Sendable {
    public let ok: Bool
    public let text: String?
    public func accepted() throws {
        if !ok { throw PhoneError.refused(text ?? "Your computer could not make this change.") }
    }
}
