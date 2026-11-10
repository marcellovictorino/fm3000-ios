import Foundation

/// INF-2935 (INF-2928 piece 2): the Mac's task record, read the way its record reads it - the bar (`recordBarOf`,
/// src/shared/recordBar.ts), the pill's tone and status reason (src/renderer/src/cards/recordFooter.ts, RecordCard.tsx,
/// src/shared/taskWaits.ts), the tabs (src/renderer/src/cards/taskTabs.ts), the attention sentence and closed line
/// (src/shared/recordAttention.ts), the captain's words folded under the goal (RecordHead.tsx), Drop task's question
/// (src/shared/recordDrop.ts), the Crewmate tab's state (crewmateState.ts) and the More row (the record frame's
/// `paintFacts`). PhoneRecordRulesTests replays the Mac's own readings, recorded by scripts/generate-phone-scene.ts.
public enum PhoneRecord {
    // MARK: The bar

    /// The end slot, at the bar's leading edge: Drop task in every state, or Dismiss on the first mate's question.
    public enum End: String, Sendable { case dropTask = "drop-task", stopTask = "stop-task", dismissQuestion = "dismiss-question" }
    /// The next slot, at the bar's trailing edge.
    public enum Next: String, Sendable {
        case start, tryAgain = "try-again", starting, startAgain = "start-again", `continue`, showCard = "show-card"
        case answerDone = "answer-done"
        public var label: String { PhoneRecordWords.next[rawValue] ?? rawValue }
        /// The host's move the button runs; Starting runs none and Show the card is its own.
        public var move: String? {
            switch self {
            case .start, .tryAgain: "start-task"
            case .startAgain: "start-again"
            case .continue: "continue-task"
            case .answerDone: "answer-done"
            case .starting, .showCard: nil
            }
        }
    }
    public struct Bar: Equatable, Sendable {
        public let end: End?
        public let next: Next?
        /// The next slot's Start shows disabled: something it waits on is still open.
        public let blocked: Bool
    }

    /// Open work that never started: the only work Drop task drops before a start.
    static func unstartedWork(_ task: PhoneTask) -> Bool {
        task.kind == "work" && task.status == "open" && task.startedAt == nil && task.activity == nil
    }

    /// The open record's bar, or Start again on eligible dropped work; nil on a record with no buttons.
    public static func bar(_ task: PhoneTask) -> Bar? {
        let parts = task.children?.total ?? 0
        if task.status == "done" { return nil }
        if task.status == "dropped" {
            return task.kind == "work" && task.replacedBy == nil && parts == 0 ? Bar(end: nil, next: .startAgain, blocked: false) : nil
        }
        if task.answerNoteId != nil { return Bar(end: .stopTask, next: .answerDone, blocked: false) }
        let work = task.kind == "work"
        let end: End? = !work ? (task.kind == "decision" && task.waitingCardId != nil ? .dismissQuestion : nil)
            : unstartedWork(task) ? .dropTask : task.status == "active" ? .stopTask : nil
        let mark = PhoneTaskFacts.status(task).mark
        let parent = task.status == "open" && parts > 0
        // Start picks started work up from the backlog whatever it waits on: its crewmate goes on waiting.
        let backlog = task.status == "active" && task.backlogSince != nil
        let blocked = !backlog && (!task.blockedBy.isEmpty || task.flags?.blocked == true)
        let startable = backlog || (task.status == "open" && !parent && (task.startPolicy == "on-request" || blocked))
        let next: Next? = mark == "waiting"
            ? (task.waitingCardId != nil || (task.requiredAction != nil && task.requiredAction?.state != "blocked") ? .showCard : nil)
            : mark == "starting" ? .starting
            : !work ? nil
            : startable ? (task.startNotice != nil ? .tryAgain : .start)
            : mark == "interrupted" ? .continue : nil
        return Bar(end: mark == "starting" ? nil : end, next: next,
                   blocked: next == .starting || ((next == .start || next == .tryAgain) && blocked))
    }

    // MARK: The top row

    /// The pill's tone: accent while the task waits on the captain, danger on an interruption or a failure.
    public static func pillTone(_ task: PhoneTask) -> String {
        let mark = PhoneTaskFacts.status(task).mark
        if mark == "waiting" { return "accent" }
        if mark == "interrupted" || (mark == "dropped" && task.closedReason == "failed") { return "danger" }
        return "neutral"
    }

    static let checkingWords = "Checking whether it started"
    static let slowStartWords = "Still starting. You can keep working."

    /// The pill's word and the reason beside it: the shared status with the task's waits, then a start in flight or
    /// a failed start said plainly. The reason's tone is `reasonTone`'s.
    public static func status(_ task: PhoneTask, now: Double, zone: TimeZone = .current) -> PhoneTaskFacts.Status {
        let read = waitStatus(task, PhoneTaskFacts.status(task, now: now), now: now, zone: zone)
        let since = task.startAttempt?.since ?? (task.activity == "starting" ? task.startedAt : nil)
        let preparing = task.startAttempt?.phase == "preparing" || task.activity == "starting"
        let reason = task.startAttempt?.phase == "checking" ? checkingWords
            : since.map { now - $0 >= 15_000 } == true && preparing ? slowStartWords
            : task.startNotice.map { "Could not start. \($0.reason)" } ?? read.reason
        return read.with(reason: reason)
    }

    /// `warning` for a failed start, `plain` for a start in flight, `quiet` for every other reason.
    public static func reasonTone(_ reason: String) -> String {
        reason.hasPrefix("Could not start") ? "warning" : reason == checkingWords || reason == slowStartWords ? "plain" : "quiet"
    }

    /// `taskWaitStatus`: the waits the attention sentence does not own join the reason, unless a typed warning stands.
    static func waitStatus(_ task: PhoneTask, _ reading: PhoneTaskFacts.Status, now: Double, zone: TimeZone) -> PhoneTaskFacts.Status {
        guard let waits = task.waits, !waits.isEmpty, reading.mark != "done", reading.mark != "dropped" else { return reading }
        let owned = Set(attentionWaits(task).map(\.id))
        let remaining = waits.filter { !checksWait($0) && !owned.contains($0.id) }
        let reason = remaining.map { wait in
            let named = wait.kind == "decision" && reading.mark == "waiting" && !reading.reason.isEmpty
                ? PhoneTask.Wait(id: wait.id, kind: wait.kind, label: reading.reason, since: wait.since, next: wait.next) : wait
            return waitText(named, now: now, zone: zone)
        }.joined(separator: "; ")
        if reading.mark == "waiting" && remaining.contains(where: { $0.kind == "decision" }) { return reading.with(reason: reason) }
        let posture = task.workPosture?.reason
        let represented = reading.reason.isEmpty || posture == "checks" || posture == "job" || posture == "dependency"
            || (posture == "captain" && waits.contains { owned.contains($0.id) && $0.kind == "decision" })
            || posture == "timed-wait" || (posture == "access" && task.workPosture?.hold?.class == "no_headroom")
            || task.status == "open"
        let warning = reading.outOfReach || ["starting", "interrupted", "waiting"].contains(reading.mark) || task.startNotice != nil
        if !warning && represented { return reading.with(reason: reason) }
        return reason.isEmpty ? reading : reading.with(reason: [reading.reason, reason].filter { !$0.isEmpty }.joined(separator: " · "))
    }

    static func checksWait(_ wait: PhoneTask.Wait) -> Bool { wait.kind == "checks" || wait.kind == "run" }

    /// The waits the attention sentence says: all but checks, and a decision whose card is up, once the box shows.
    public static func attentionWaits(_ task: PhoneTask) -> [PhoneTask.Wait] {
        let waits = (task.waits ?? []).filter { !checksWait($0) && ($0.kind != "decision" || task.waitingCardId == nil) }
        let box = task.hold != nil || task.queueWait != nil || !task.blockedBy.isEmpty || task.activity == "interrupted"
            || waits.contains { $0.kind != "job" }
        return box ? waits : []
    }

    /// `taskWaitText`: the wait's name, its next event at the local clock, and when the wait was recorded.
    public static func waitText(_ wait: PhoneTask.Wait, now: Double, zone: TimeZone = .current) -> String {
        let words = ["next-read": "next read", "check-back": "check-back", "reset": "reset", "start": "start time"]
        let event = wait.next.map { "\(words[$0.kind] ?? $0.kind)\($0.at <= now ? " was due" : "") \(clock($0.at, now: now, zone: zone))" }
            ?? "time unknown"
        return "\(wait.label) · \(event)\(wait.since.map { " · wait recorded \(clock($0, now: now, zone: zone))" } ?? "")"
    }

    /// The time of day with its zone, and the date in front when it is not today, as the Mac's clock writes it.
    static func clock(_ at: Double, now: Double, zone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let date = Date(timeIntervalSince1970: at / 1000)
        let formatter = DateFormatter()
        formatter.timeZone = zone
        formatter.setLocalizedDateFormatFromTemplate(
            calendar.isDate(date, inSameDayAs: Date(timeIntervalSince1970: now / 1000)) ? "jmmz" : "MMMdjmmz")
        return formatter.string(from: date)
    }

    // MARK: The tabs

    public enum Tab: Hashable, Sendable {
        case info, cards(Int), activity, crewmate
        public var label: String {
            switch self {
            case .info: PhoneRecordWords.info
            case .cards: PhoneRecordWords.cards
            case .activity: PhoneRecordWords.activity
            case .crewmate: PhoneRecordWords.crewmate
            }
        }
        public var id: String {
            switch self {
            case .info: "info"
            case .cards: "cards"
            case .activity: "activity"
            case .crewmate: "crewmate"
            }
        }
    }

    /// Info, then Cards with its count once the task showed one, Activity once it has a line, Crewmate once a crewmate
    /// ran it; none while there is only Info.
    public static func tabs(_ task: PhoneTask) -> [Tab] {
        var tabs: [Tab] = [.info]
        if let count = task.cards?.count, count > 0 { tabs.append(.cards(count)) }
        if !(task.activityLog ?? []).isEmpty { tabs.append(.activity) }
        if task.startedAt != nil { tabs.append(.crewmate) }
        return tabs.count > 1 ? tabs : []
    }

    // MARK: Info's head

    public struct Attention: Equatable, Sendable {
        public let title: String
        public let guidance: String
        /// Drawn first, above the filing's Why.
        public let urgent: Bool
        /// A failure or an interruption.
        public let danger: Bool
    }

    /// What the attention sentence says, or nil when nothing needs saying.
    public static func attention(_ task: PhoneTask, now: Double, zone: TimeZone = .current) -> Attention? {
        let live = task.status != "done" && task.status != "dropped"
        var title = "", guidance = "", urgent = false, danger = false
        if task.closedReason == "failed" || (live && task.activity == "interrupted") {
            title = task.closedReason == "failed" ? "Task failed" : "Work was interrupted"
            guidance = task.problem ?? "Ask your first mate how to continue."
            urgent = true
            danger = true
        } else if let wait = task.queueWait {
            title = wait.line
            guidance = task.hold?.text ?? ""
            urgent = task.flags?.blocked == true
        } else if live && !task.blockedBy.isEmpty {
            title = "Waiting on \(task.blockedBy.joined(separator: ", "))"
            guidance = "This task is blocked by other work."
            urgent = true
        } else if live && task.waitingCardId != nil {
            // The status says a decision waits, and the bar has Show the card.
        } else if task.status == "open" && task.flags?.blocked == true {
            title = "A task it waits on was dropped"
            guidance = "Ask your first mate about its dependencies before starting."
        } else if live && task.workPosture?.state == "active" {
            // Checks, jobs and replies still move without the captain.
        } else if live, let hold = task.hold {
            title = hold.title
            guidance = hold.text
        } else if live && (task.flags?.needsYou == true || task.flags?.held == true || task.captainWait == true) {
            title = "Work is paused"
            guidance = task.outcomeSummary.flatMap { $0.isEmpty ? nil : $0 } ?? "No reason has been reported yet."
        } else if task.status == "open", let children = task.children, children.total > 0 {
            title = "Its \(children.total) \(children.total == 1 ? "part does" : "parts do") the work"
            guidance = "\(children.closed) closed, \(children.total - children.closed) still open."
        }
        let waits = attentionWaits(task)
        if !waits.isEmpty {
            let words = waits.map { waitText($0, now: now, zone: zone) }.joined(separator: "; ")
            if danger { guidance = "\(guidance) \(words)" } else {
                title = words
                if waits.contains(where: { $0.kind == "start" }) { guidance = "The recorded start time does not promise that work has resumed." }
            }
        }
        return title.isEmpty ? nil : Attention(title: title, guidance: guidance, urgent: urgent, danger: danger)
    }

    static let closeWords = ["landed": "Merged", "merged": "Merged", "released": "Released", "answered": "Answered",
                             "settled": "Closed", "finished": "Finished", "cancelled": "Dropped", "discarded": "Discarded",
                             "failed": "Failed", "superseded": "Superseded"]

    /// How a closed task closed: `lead`, the age of `at` said as a time past, `as <change>`, then `tail`.
    public struct ClosedLine: Equatable, Sendable {
        public let lead: String
        public let at: Double?
        public let change: PhoneTaskFacts.Change?
        public let tail: String
        public func words(now: Double) -> String {
            lead + (at.map { PhoneTaskFacts.checksFinishedAgo($0, now: now) } ?? "")
                + (change.map { " as \($0.noun) \($0.label ?? "")" } ?? "") + tail
        }
    }

    public static func closedLine(_ task: PhoneTask) -> ClosedLine? {
        guard task.status == "done" || task.status == "dropped" else { return nil }
        let at = task.closing?.at ?? task.closedAt
        if task.closedReason == "landed" || task.closedReason == "merged" {
            let facts = task.delivery
            let number = facts?.prNumber.flatMap { $0 == 0 ? nil : $0 }
            let label = facts?.changeLabel ?? number.map { "#\($0)" }
            let noun = number != nil || label?.hasPrefix("#") == true ? "pull request" : "branch"
            return ClosedLine(lead: "Merged ", at: at, change: label.map { PhoneTaskFacts.Change(noun: noun, label: $0, url: facts?.prUrl) },
                              tail: ".\(facts?.ci == "green" ? " The checks passed." : "")")
        }
        // Work another task carries on closed done: its words say where that work stands.
        if task.status == "done" && task.closedReason == "superseded", let note = task.closing?.note, !note.isEmpty {
            return ClosedLine(lead: "\(note), closed ", at: at, change: nil, tail: ".")
        }
        let word = task.closedReason.map { closeWords[$0] ?? $0 } ?? (task.status == "done" ? "Done" : "Dropped")
        let note = task.closing?.note.flatMap { $0.isEmpty ? nil : $0 }
        return ClosedLine(lead: "\(word) ", at: at, change: nil, tail: note.map { ": \($0)" } ?? ".")
    }

    /// The captain's messages on the task besides the words that started it.
    public static func asks(_ task: PhoneTask) -> [PhoneTask.Ask] {
        let words = task.intent?.userWords ?? ""
        return (task.asks ?? []).filter { $0.text != words }
    }

    /// The fold under the goal, named by what it holds with how many of the captain's messages are in it.
    public static func wordsFoldName(_ task: PhoneTask) -> String? {
        let words = task.intent?.userWords ?? ""
        let count = asks(task).count + (words.isEmpty ? 0 : 1)
        var parts: [String] = []
        if task.filing != nil && task.status != "open" { parts.append("Why it was filed") }
        if let skipped = task.skippedPlanBecause, !skipped.isEmpty { parts.append("why there was no plan") }
        if count > 0 { parts.append("your \(count) \(count == 1 ? "message" : "messages")") }
        guard let last = parts.last else { return nil }
        let name = parts.count > 1 ? "\(parts.dropLast().joined(separator: ", ")) and \(last)" : last
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    // MARK: The facts

    static let deliveryNames = ["direct-pr": "Pull request", "queue-pr": "Batched pull request", "local-only": "Local merge",
                                "in-place": "Built in place"]

    /// The Delivery cell (RecordCard's `deliveryWordsOf`): how the work reaches the project and the care it takes.
    public static func deliveryWords(_ task: PhoneTask) -> String {
        let mode = task.policies?.delivery.value ?? task.delivery?.mode
        let care = task.policies?.rigor.value ?? task.rigor
        return [mode.map { deliveryNames[$0] ?? $0 }, care.map { "\(PhoneRecordWords.care[$0] ?? $0) care" }]
            .compactMap(\.self).joined(separator: " · ")
    }

    public struct Fact: Equatable, Sendable {
        public let id: String
        public let term: String
        public let value: String
        /// Where a policy came from: This task, Parent task or Project setting.
        public let source: String?
    }

    public struct More: Equatable, Sendable {
        public let facts: [Fact]
        public let helper: String
        /// What the closed row holds, named beside it.
        public let preview: String
    }

    static let modeWords = ["direct-pr": "As a pull request", "queue-pr": "As a batched pull request your project's queue tests",
                            "local-only": "Merged locally, no pull request", "in-place": "Built in place"]

    /// The record's one closed More row: the crewmate, the branch and the task's policies with where each came from.
    public static func more(_ task: PhoneTask) -> More? {
        var facts: [Fact] = []
        func fact(_ id: String, _ term: String, _ value: String, _ source: String? = nil) {
            facts.append(Fact(id: id, term: term, value: value, source: source.map { PhoneRecordWords.policySource[$0] ?? $0 }))
        }
        if task.deliverable == "operation" { fact("deliverable", "Result", "Operation") }
        if let assignee = task.assignee { fact("crewmate", "Crewmate", assignee + (task.modelLabel.map { " on \($0)" } ?? "")) }
        if let branch = task.repo?.branch, !branch.isEmpty { fact("branch", "Branch", branch) }
        let lands = (task.delivery?.mode.map { [modeWords[$0] ?? $0] } ?? []) + (task.delivery?.landedMode != nil ? ["merged"] : [])
            + (task.rigor.map { ["care: \(PhoneRecordWords.care[$0] ?? $0)"] } ?? [])
        if let policies = task.policies {
            fact("delivery", "Delivery", PhoneRecordWords.policyDelivery[policies.delivery.value] ?? policies.delivery.value, policies.delivery.source)
            fact("merging", "Merging", policies.autonomy.value ? PhoneRecordWords.policyMergesOn : PhoneRecordWords.policyMergesOff,
                 policies.autonomy.source)
            fact("care", "Care", PhoneRecordWords.care[policies.rigor.value] ?? policies.rigor.value, policies.rigor.source)
        } else if !lands.isEmpty { fact("delivery", "Delivery", lands.joined(separator: " · ")) }
        if let runsOn = task.runsOn {
            fact("runs-on", "Runs on", runsOn.label, runsOn.source)
            if let reason = runsOn.reason { fact("computer-choice", "Computer choice", reason) }
        }
        let closed = task.status == "done" || task.status == "dropped"
        var helper: [String] = []
        if let policies = task.policies, let requested = policies.rigor.requested, requested != policies.rigor.value {
            helper.append(PhoneRecordWords.policyCareBound)
        }
        if closed && task.policies != nil { helper.append("This task is closed. Its policies are kept as history.") }
        if !closed && (task.policies != nil || task.runsOn != nil) { helper.append(PhoneRecordWords.policyHelper) }
        guard !facts.isEmpty else { return nil }
        let preview = [task.repo?.branch.flatMap { $0.isEmpty ? nil : "branch" }, task.runsOn?.reason != nil ? "the computer's choice" : nil,
                       task.policies != nil || !lands.isEmpty ? "delivery" : nil].compactMap(\.self).joined(separator: " · ")
        return More(facts: facts, helper: helper.joined(separator: " "), preview: preview)
    }

    // MARK: Drop task

    /// What pressing Drop task says first instead of asking: the record changed since it was read.
    public static func dropRefusal(_ task: PhoneTask, end: End) -> String? {
        guard end == .dropTask else { return nil }
        return task.dropEffects == nil ? PhoneRecordWords.dropReviewStale : nil
    }

    /// Drop task's one question: whether unfinished work is kept, then its parts, who still waits on it and what keeps
    /// working.
    public static func dropQuestion(_ task: PhoneTask, end: End) -> String {
        let effects = end == .dropTask ? task.dropEffects : nil
        return [dropLead(task.key, started: end == .stopTask), effects.flatMap { dropParts($0.parts) },
                effects.flatMap { dropWaiting($0.waiting.map(\.key)) },
                effects.flatMap { dropUnderway($0.underway.map(\.key)) }].compactMap(\.self).joined(separator: " ")
    }

    static func dropLead(_ key: String, started: Bool) -> String {
        started ? "Drop \(key)? It ends the task and keeps a copy of its unfinished work."
            : "Drop \(key)? It won't start, and there is no unfinished work to keep. Its record stays."
    }

    static func dropWaiting(_ keys: [String]) -> String? {
        if keys.isEmpty { return nil }
        if keys.count == 1 { return "\(keys[0]) is still waiting on this work. Dropping this task will not start it." }
        return "\(keys.count) tasks are still waiting on this work (\(keys.joined(separator: ", "))). Dropping this task will not start them."
    }

    static func dropUnderway(_ keys: [String]) -> String? {
        if keys.isEmpty { return nil }
        return keys.count == 1 ? "\(keys[0]) is already working and will not be stopped."
            : "\(keys.count) tasks are already working (\(keys.joined(separator: ", "))) and will not be stopped."
    }

    /// What the one drop does to open parts: they stay planned, and one that started keeps working (`dropPartsLine`).
    static func dropParts(_ parts: [PhoneTask.DropEffects.Part]) -> String? {
        if parts.isEmpty { return nil }
        let started = parts.filter { $0.started == true }.map(\.key)
        let planned = parts.filter { $0.started != true }.map(\.key)
        var lines: [String] = []
        if planned.count == 1 { lines.append("Its part \(planned[0]) stays planned.") }
        else if planned.count > 1 { lines.append("Its \(planned.count) parts (\(planned.joined(separator: ", "))) stay planned.") }
        if started.count == 1 { lines.append("Its part \(started[0]) has started and keeps working.") }
        else if started.count > 1 {
            lines.append("Its \(started.count) parts that started (\(started.joined(separator: ", "))) keep working.")
        }
        return lines.joined(separator: " ")
    }

    // MARK: The Crewmate tab

    public enum CrewState: String, Sendable { case working, paused, waiting, idle, closed }

    /// Where the crewmate stands: its turn running, the captain holding its browser, a card of its waiting on the
    /// captain, idle, or the task closed.
    public static func crewState(_ task: PhoneTask, live: PhoneCrewLive?) -> CrewState {
        if task.status == "done" || task.status == "dropped" { return .closed }
        if task.browser?.state == "open" && task.browser?.control == "captain" { return .paused }
        // A Stop the computer still holds keeps the line on Working, its button saying Stopping, as the Mac's does.
        if task.activity == "running" || task.activity == "starting" || task.activity == "stopping" || live?.since != nil { return .working }
        if task.waitingCardId != nil || task.flags?.needsYou == true || task.captainWait == true { return .waiting }
        return .idle
    }

    /// The status line's words for each state; none while the task is closed.
    public static func crewWords(_ state: CrewState) -> String? {
        switch state {
        case .working: PhoneRecordWords.crewWorking
        case .paused: PhoneRecordWords.crewPaused
        case .waiting: PhoneRecordWords.crewWaiting
        case .idle: PhoneRecordWords.crewIdle
        case .closed: nil
        }
    }

    /// How long the turn has run: `42s`, `3m 05s`, `1h 07m`.
    public static func elapsed(_ ms: Double) -> String {
        let seconds = max(0, Int((ms / 1000).rounded(.down)))
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m \(String(format: "%02d", seconds % 60))s" }
        return "\(minutes / 60)h \(String(format: "%02d", minutes % 60))m"
    }
}

extension PhoneTaskFacts.Status {
    func with(reason: String) -> Self {
        reason == self.reason ? self
            : Self(mark: mark, word: word, reason: reason, outOfReach: outOfReach, wait: wait, since: since, waitsOn: waitsOn)
    }
}
