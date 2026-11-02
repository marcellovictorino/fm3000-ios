import Foundation

/// INF-1926: the desktop crew summary's facts for one task, in its words: `taskFactsOf` (src/shared/taskFacts.ts) with
/// its status from `taskStatusOf` (src/shared/taskPresentation.ts), its checks from src/shared/checkSnapshot.ts and
/// checksSpan.ts, and its plan from src/shared/taskPlan.ts. PhoneTaskFactsTests replays the desktop's own readings,
/// recorded by scripts/generate-phone-scene.ts, against this port.
public struct PhoneTaskFacts: Sendable {
    public struct Status: Equatable, Sendable {
        /// backlog, queued, starting, working, idle, interrupted, waiting, done or dropped.
        public let mark: String
        public let word: String
        public let reason: String
        /// Its computer is out of reach: the mark keeps its shape in warn.
        public let outOfReach: Bool
        /// Working that is a background wait: checks or job.
        public let wait: String?
        /// When the one task it stands idle on was recorded.
        public let since: Double?
        public let waitsOn: [String]?
        public var label: String { reason.isEmpty ? word : "\(word) · \(reason)" }
    }
    public struct Now: Equatable, Sendable { public let text: String; public let at: Double }
    public struct Change: Equatable, Sendable { public let noun: String; public let label: String?; public let url: String? }
    public struct Span: Equatable, Sendable { public let startedAt: Double; public let finishedAt: Double?; public let joint: String }
    /// A fact cell's state dot (src/shared/factDot.ts): ok, warn, failed, running or idle.
    public struct Checks: Equatable, Sendable {
        public let problem: String?
        public let dot: String
        public let words: String
        public let at: Double?
        public let span: Span?
        /// The words with how long the checks have run or took: `running for 15m`, `passed in 14m`.
        public func spanWords(now: Double) -> String {
            guard let span else { return words }
            return "\(words) \(span.joint) \(PhoneTaskFacts.checksDuration((span.finishedAt ?? now) - span.startedAt))"
        }
    }
    public struct Review: Equatable, Sendable { public let dot: String; public let words: String }
    public struct Delivery: Equatable, Sendable { public let change: Change?; public let checks: Checks?; public let review: Review? }

    public let key: String
    public let status: Status
    public let title: String
    /// The record has answered: before it does, the Now row is held open, blank, and no plan is drawn.
    public let read: Bool
    public let now: Now?
    public let plan: PhoneTask.Plan?
    public let model: String?
    public let tier: String?
    public let reasoning: String?
    public let reason: String?
    public let delivery: Delivery?

    /// `unreadable`: the record's read failed, so the summary reads the board row as a record with no rows, as the desktop does.
    public init(_ task: PhoneTask, modelName: (String) -> String, unreadable: Bool = false) {
        let model = task.model.map(modelName)
        key = task.key
        status = Self.status(task)
        title = task.title
        read = unreadable || task.activityLog != nil
        now = unreadable ? nil : task.activityLog.flatMap { Self.now($0, said: task.said) }
        plan = read ? task.plan : nil
        self.model = model
        // The readout belongs to a model: none of it stands without one.
        tier = model == nil ? nil : task.tier
        reasoning = model == nil ? nil : task.reasoning.flatMap { Self.levelWords[$0.level] }
        reason = model == nil ? nil : task.reasoning.flatMap(Self.reasoningNote)
        delivery = Self.delivery(task)
    }

    // MARK: Status

    static let statusWords = ["backlog": "Backlog", "queued": "Queued", "starting": "Starting", "working": "Working",
                              "idle": "Idle", "interrupted": "Interrupted", "waiting": "Waiting on you", "done": "Done",
                              "dropped": "Dropped"]
    static let postureWords = ["turn": "Working", "job": "Background work continues", "checks": "Waiting for checks",
                               "guidance": "A reply is queued", "settlement": "Finishing the task",
                               "timed-wait": "Waiting to continue automatically", "captain": "Work is paused",
                               "inactive": "No continuing work", "access": "Paused for access",
                               "dependency": "Blocked by another task", "unobserved": "Background work is unknown"]

    public static func status(_ task: PhoneTask) -> Status {
        func reading(_ mark: String, _ reason: String, outOfReach: Bool = false, wait: String? = nil,
                     since: Double? = nil, waitsOn: [String]? = nil) -> Status {
            let word = statusWords[mark] ?? mark
            return Status(mark: mark, word: word, reason: reason == word ? "" : reason, outOfReach: outOfReach,
                          wait: wait, since: since, waitsOn: waitsOn)
        }
        let connecting = task.place?.reach == "connecting"
        let away = task.place?.reach != nil && task.place?.reach != "in-reach" ? task.place?.name.flatMap { $0.isEmpty ? nil : $0 } : nil
        let awayWords = connecting ? "\(away ?? "") is connecting"
            : task.place?.noNewWork == true ? "\(away ?? "") takes no new work" : "\(away ?? "") is out of reach"
        // Connecting keeps the mark as it was: only out of reach draws it in warn.
        func awayReading(_ mark: String, _ reason: String?) -> Status { reading(mark, reason ?? awayWords, outOfReach: !connecting) }
        let onRequest = task.startPolicy == "on-request"
        if task.status == "done" { return reading("done", task.requiredAction?.result ?? (task.closedReason == "answered" ? "Answered" : "")) }
        if task.status == "dropped" { return reading("dropped", task.requiredAction?.result ?? (task.closedReason == "failed" ? "Failed" : "")) }
        if let required = task.requiredAction { return reading("waiting", required.state == "blocked" ? "Waiting for prerequisites" : "") }
        if task.waitingCardId != nil {
            return reading("waiting", task.waitingCardMerges == true ? "Waiting for your merge" : "A decision card is ready")
        }
        if task.startAttempt?.phase == "preparing" || task.startAttempt?.phase == "checking"
            || (task.status == "active" && task.activity == "starting") {
            return reading("starting", "")
        }
        if task.startNotice != nil && (task.status == "open" || task.status == "active") {
            return reading(onRequest ? "backlog" : "queued", "Could not start")
        }
        if task.status == "open" {
            let mark = onRequest ? "backlog" : "queued"
            if let wait = task.queueWait { return reading(mark, wait.line) }
            let parts = task.children?.total ?? 0
            let holds = task.flags?.blocked == true ? "Blocked by another task"
                : task.flags?.held == true ? "Held"
                : parts > 0 ? "Its \(parts) \(parts == 1 ? "part does" : "parts do") the work" : nil
            if away != nil { return awayReading(mark, holds) }
            return reading(mark, holds ?? (onRequest ? "Starts when you press Start" : "Starts by itself when ready"))
        }
        let waits = task.blockedBy
        let dependency = task.workPosture?.reason == "dependency" && !waits.isEmpty
        let running = task.activity == "running" || task.activity == "starting"
        let reason = dependency ? dependencyWaitWords(waits)
            : task.workPosture.map { postureWords[$0.reason] ?? "" }
            ?? (running ? "Working" : task.activity == "interrupted" ? "Work was interrupted" : "No continuing work")
        if task.workPosture?.state == "active" || (task.workPosture == nil && running) {
            if away != nil { return awayReading("working", nil) }
            let wait = task.workPosture?.state == "active" ? task.workPosture?.reason : nil
            return wait == "checks" || wait == "job" ? reading("working", reason, wait: wait) : reading("working", reason)
        }
        if task.activity == "interrupted" { return reading("interrupted", reason) }
        if away != nil { return awayReading("idle", nil) }
        if !dependency { return reading("idle", reason) }
        let since = waits.count == 1 ? task.blockedSince?[waits[0]] : nil
        return reading("idle", reason, since: since, waitsOn: waits)
    }

    /// What a started task waits on: the one task by its key, or how many.
    public static func dependencyWaitWords(_ blockedBy: [String]) -> String {
        blockedBy.count == 1 ? "Waiting on \(blockedBy[0])" : "Waiting on \(blockedBy.count) tasks"
    }

    // MARK: Now

    /// The rows a crewmate's own work writes, and the rows the app writes to it, which never stand as its Now.
    static let doingKinds: Set<String> = ["progress", "report", "card_raised", "pr_opened", "ci"]
    static let sentKinds: Set<String> = ["steered", "compacted"]

    /// The crewmate's own newest doing: its newest own row of `doingKinds`, its last sentence or its newest action.
    public static func now(_ log: [PhoneTask.ActivityRow], said: PhoneTask.ActionLine?) -> Now? {
        let own = log.filter { $0.from == nil }
        var newest = own.last { doingKinds.contains($0.kind) }.map { Now(text: $0.text, at: $0.at) }
        let actions = own.flatMap { $0.actions ?? [] }
        for doing in actions + (said.map { [$0] } ?? []) where newest == nil || doing.at > newest!.at {
            newest = Now(text: doing.text, at: doing.at)
        }
        if let newest { return newest }
        return own.last { !sentKinds.contains($0.kind) }.map { Now(text: $0.text, at: $0.at) }
    }

    // MARK: Delivery

    static let checksDot = ["green": "ok", "merged": "ok", "red": "failed", "pending": "running", "no-pr": "idle"]
    static let checkWords = ["green": "passed", "red": "failed", "pending": "running", "no-pr": "no pull request yet",
                             "merged": "merged outside the app"]
    static let runDot = ["running": "running", "passed": "ok", "failed": "failed", "cancelled": "idle"]
    static let runWords = ["running": "running", "passed": "passed", "failed": "failed", "cancelled": "cancelled"]
    static let reviewDot = ["pass": "ok", "findings": "warn", "blocked": "failed"]
    static let reviewWords = ["pass": "passed", "findings": "findings", "blocked": "blocked"]
    static let notReadWords = "not read yet"

    /// The change and its checks while the work is live, and a review's verdict whether or not it is.
    public static func delivery(_ task: PhoneTask) -> Delivery? {
        guard let facts = task.delivery else { return nil }
        let live = task.status != "done" && task.status != "dropped"
        let change = live ? Self.change(facts) : nil
        let ci = facts.ci ?? "no-pr"
        let observed = currentCheckSummary(facts)
        var checks: Checks?
        if live && (observed != nil || change != nil || ci != "no-pr") {
            checks = Checks(problem: observed?.problem, dot: observed?.dot ?? checksDot[ci] ?? "idle",
                            words: observed?.words ?? (ci == "no-pr" ? notReadWords : checkWords[ci] ?? ci),
                            at: facts.ciAt, span: checksSpan(facts))
        } else if live, let run = facts.runChecks {
            checks = Checks(problem: nil, dot: runDot[run.state] ?? "idle", words: runWords[run.state] ?? run.state,
                            at: run.at, span: runChecksSpan(run))
        }
        let review = facts.reviewVerdict.map { verdict in
            Review(dot: reviewDot[verdict] ?? "idle",
                   words: (reviewWords[verdict] ?? verdict) + (facts.reviewRisk.map { " · risk \($0)" } ?? ""))
        }
        return change != nil || checks != nil || review != nil ? Delivery(change: change, checks: checks, review: review) : nil
    }

    /// The task's change where the project lives: its label (`#N`, or the branch), its page and its noun.
    public static func change(_ facts: PhoneTask.Delivery) -> Change? {
        let number = facts.prNumber.flatMap { $0 == 0 ? nil : $0 }
        let label = facts.changeLabel ?? number.map { "#\($0)" }
        if facts.prUrl == nil && label == nil { return nil }
        return Change(noun: number != nil || label?.hasPrefix("#") == true ? "Pull request" : "Branch", label: label, url: facts.prUrl)
    }

    static let checkStateWords = ["success": "passed", "failure": "failed", "error": "error", "cancelled": "cancelled",
                                  "timed_out": "timed out", "action_required": "needs a decision",
                                  "startup_failure": "did not start", "stale": "out of date", "skipped": "skipped",
                                  "neutral": "neutral", "pending": "running"]
    static let redStates: Set<String> = ["failure", "error", "cancelled", "timed_out", "action_required", "startup_failure", "stale"]

    public struct CheckSummary: Equatable, Sendable { public let overall: String; public let words: String; public let dot: String; public let problem: String? }

    /// One reading of a version's checks in the merge card's words: each state's count, in the order first seen.
    public static func checkSummary(_ reading: PhoneTask.Delivery.CheckSnapshot) -> CheckSummary {
        let incomplete = reading.complete == false || reading.problem != nil
        let unknownWords = reading.problem.map { "cannot read all checks: \($0)" } ?? "reading incomplete"
        if reading.items.isEmpty {
            let absent = reading.absenceDeclared == true && !incomplete
            return CheckSummary(overall: absent ? "none" : "pending",
                                words: absent ? "no checks" : incomplete ? unknownWords : "none reported",
                                dot: absent ? "idle" : reading.problem != nil ? "warn" : "running", problem: reading.problem)
        }
        var order: [String] = [], counts: [String: Int] = [:]
        for check in reading.items {
            if counts[check.state] == nil { order.append(check.state) }
            counts[check.state, default: 0] += 1
        }
        let words = order.map { state in
            let word = checkStateWords[state] ?? state
            return reading.items.count == 1 ? word : "\(counts[state]!) \(word)"
        }.joined(separator: " · ") + (incomplete ? " · \(unknownWords)" : "")
        if reading.items.contains(where: { redStates.contains($0.state) }) {
            return CheckSummary(overall: "red", words: words, dot: "failed", problem: reading.problem)
        }
        if incomplete || counts["pending"] != nil {
            return CheckSummary(overall: "pending", words: words, dot: reading.problem != nil ? "warn" : "running", problem: reading.problem)
        }
        if counts["neutral"] != nil { return CheckSummary(overall: "pending", words: words, dot: "warn", problem: nil) }
        return CheckSummary(overall: "green", words: words, dot: "ok", problem: nil)
    }

    /// The reading for the change's current version; one of an earlier version says so.
    public static func currentCheckSummary(_ delivery: PhoneTask.Delivery) -> CheckSummary? {
        guard let reading = delivery.checks else { return nil }
        if let head = delivery.headSha, head != reading.headSha {
            return CheckSummary(overall: "pending", words: "not read for this version", dot: "idle", problem: nil)
        }
        return checkSummary(reading)
    }

    /// How long the checks have run or took, by the host's own times; none for a reading of another version.
    public static func checksSpan(_ delivery: PhoneTask.Delivery) -> Span? {
        if let checks = delivery.checks, let head = delivery.headSha, checks.headSha != head { return nil }
        if delivery.checks?.problem != nil { return nil }
        guard let startedAt = delivery.ciStartedAt else { return nil }
        let ci = delivery.checks.map { checkSummary($0).overall } ?? delivery.ci
        if ci == "pending" { return Span(startedAt: startedAt, finishedAt: nil, joint: "for") }
        guard let finishedAt = delivery.ciFinishedAt else { return nil }
        if ci == "green" { return Span(startedAt: startedAt, finishedAt: finishedAt, joint: "in") }
        if ci == "red" { return Span(startedAt: startedAt, finishedAt: finishedAt, joint: "after") }
        return nil
    }

    public static func runChecksSpan(_ run: PhoneTask.Delivery.RunChecks) -> Span? {
        guard let startedAt = run.startedAt else { return nil }
        if run.state == "running" { return Span(startedAt: startedAt, finishedAt: nil, joint: "for") }
        guard let finishedAt = run.finishedAt else { return nil }
        return Span(startedAt: startedAt, finishedAt: finishedAt, joint: run.state == "passed" ? "in" : "after")
    }

    /// `under 1m`, `15m`, `1h 05m`.
    public static func checksDuration(_ ms: Double) -> String {
        let minutes = Int((max(0, ms) / 60_000).rounded(.down))
        if minutes < 1 { return "under 1m" }
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(String(format: "%02d", minutes % 60))m"
    }

    /// `just now` or `5m ago`, after the checks' duration.
    public static func checksFinishedAgo(_ finishedAt: Double, now: Double) -> String {
        let age = relativeAge(finishedAt, now: max(now, finishedAt))
        return age == "now" ? "just now" : "\(age) ago"
    }

    /// A short age beside a fact, as the feed writes it: `now`, `5m`, `2h`, `3d`.
    public static func relativeAge(_ at: Double, now: Double) -> String {
        let seconds = Int((max(0, now - at) / 1000).rounded(.down))
        if seconds < 60 { return "now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        return hours < 24 ? "\(hours)h" : "\(hours / 24)d"
    }

    // MARK: Model

    static let levelWords = ["off": "None", "minimal": "Minimal", "low": "Low", "medium": "Medium", "high": "High",
                             "xhigh": "Extra high", "default": "Model's own"]

    static func reasoningNote(_ reasoning: PhoneTask.Reasoning) -> String? {
        if reasoning.lower == "quick" { return "Reasoning one step lower for Quick care." }
        if reasoning.lower == "capped" { return "Reasoning at the most this model offers." }
        return nil
    }

    // MARK: Plan

    /// Past this many items the finished ones fold into one counted dot; the line holds at most `planLineMax` dots.
    static let planFoldPast = 8
    static let planLineMax = 12

    public struct PlanCounts: Equatable, Sendable { public let done: Int; public let total: Int; public let skipped: Int; public let current: String? }

    /// "2 of 4" counts finished items against those not skipped; the current item is the first marked current.
    public static func planCounts(_ items: [PhoneTask.Plan.Item]) -> PlanCounts {
        let done = items.filter { $0.state == "done" }.count, skipped = items.filter { $0.state == "skipped" }.count
        return PlanCounts(done: done, total: items.count - skipped, skipped: skipped, current: items.first { $0.state == "current" }?.label)
    }

    /// The finished items before the last finished one, once the plan is long enough to fold them, and the rest.
    public static func foldPlan<T>(_ items: [T], state: (T) -> String) -> (folded: [T], rest: [T])? {
        guard items.count > planFoldPast else { return nil }
        let lastDone = items.lastIndex { state($0) == "done" } ?? -1
        let hides = items.indices.map { state(items[$0]) == "done" && $0 < lastDone }
        let folded = items.indices.filter { hides[$0] }.map { items[$0] }
        guard folded.count >= 2 else { return nil }
        return (folded, items.indices.filter { !hides[$0] }.map { items[$0] })
    }

    /// The dots a line shows and the later ones that fold into its last counted dot.
    public static func clipPlanLine<T>(_ nodes: [T], state: (T) -> String) -> (shown: [T], later: [T])? {
        guard nodes.count > planLineMax else { return nil }
        let current = nodes.firstIndex { state($0) == "current" } ?? -1
        let keep = max(planLineMax - 1, current + 1)
        guard nodes.count - keep >= 2 else { return nil }
        return (Array(nodes[..<keep]), Array(nodes[keep...]))
    }

    /// One dot on the summary's plan line: an item, or a counted fold of finished or later items.
    public struct PlanNode: Equatable, Sendable {
        public let label: String
        public let short: String
        public let state: String
        public let group: Int?
    }

    /// The summary's plan line (TaskFacts.tsx `PlanDots`): finished items fold past eight, and past twelve dots the items
    /// after the current one fold into one last dot.
    public static func planNodes(_ items: [PhoneTask.Plan.Item]) -> [PlanNode] {
        let nodes = items.map { PlanNode(label: $0.label, short: $0.short ?? $0.label, state: $0.state, group: nil) }
        let unclipped = foldPlan(nodes, state: \.state).map { fold in
            [PlanNode(label: fold.folded.map(\.label).joined(separator: ", "), short: "\(fold.folded.count) done",
                      state: "done", group: fold.folded.count)] + fold.rest
        } ?? nodes
        guard let clip = clipPlanLine(unclipped, state: \.state) else { return unclipped }
        return clip.shown + [PlanNode(label: clip.later.map(\.label).joined(separator: ", "), short: "\(clip.later.count) more",
                                      state: clip.later.allSatisfy { $0.state == "done" } ? "done" : "next", group: clip.later.count)]
    }
}
