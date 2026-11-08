import Foundation

/// INF-2928 piece 3: the Mac's moves on one task, as its task board offers them on a tile's menu and its Tasks panel on a
/// backlog row's Start - `boardMenuOf`, `boardMoveOf`, `dropAskOf` (src/panels/now/boardMoves.ts) and `rowStartOf`
/// (src/panels/now/rows.ts). Every move is one the record's own rule allows (the row's `moves`), the host checks it again
/// when it runs, and an entry that cannot run keeps the Mac's reason. PhoneRowMovesTests replays the Mac's own readings,
/// recorded by scripts/generate-phone-scene.ts.
public enum PhoneRowMoves {
    /// The board's lane a task's tile sits in: its Tasks group, Dropped for dropped work, or an earlier search match.
    public enum Lane: String, Sendable { case waiting, working, queued, backlog, landed, dropped, earlier }
    /// Where a move sends the task: a lane, or the Drop task tray.
    public enum Target: String, Sendable { case waiting, working, queued, backlog, landed, drop }

    /// What a move does: nothing, a refusal with its reason, a move written at once, a move that asks once, or the
    /// completion card brought forward.
    public enum Move: Equatable, Sendable {
        case none(String)
        case refused(String)
        case now(op: String, text: String, done: String)
        case ask(op: String, sentence: String, confirm: String)
        case card(cardID: String, text: String)
    }

    /// One entry of the menu: its name, what it does or why it cannot, and the move it makes.
    public struct Entry: Equatable, Sendable {
        public enum ID: String, Sendable { case open, card, `continue`, queue, unqueue, start, drop }
        public let id: ID
        public let label: String
        public let detail: String?
        public let disabled: Bool
        public let danger: Bool
        public let target: Target?
    }
    public enum Item: Equatable, Sendable { case entry(Entry), separator }

    /// The lane a task's own state puts it in (`boardLaneOf`); nil for a closed task that is not work.
    public static func lane(_ task: PhoneTask) -> Lane? {
        if task.status == "dropped" { return task.kind == "work" ? .dropped : nil }
        return task.group.flatMap { Lane(rawValue: $0.rawValue) }
    }

    /// Done and Dropped tiles never move.
    public static func movable(_ lane: Lane) -> Bool { lane != .landed && lane != .dropped }

    public static let openLabel = "Open record"
    static let cardLabel = "Show the card"

    /// "INF-3", "INF-3 and INF-4", "INF-3, INF-4 and INF-5".
    static func keyList(_ keys: [String]) -> String {
        guard keys.count > 1, let last = keys.last else { return keys.first ?? "another task" }
        return "\(keys.dropLast().joined(separator: ", ")) and \(last)"
    }

    private static func blocked(_ task: PhoneTask) -> Bool { task.flags?.blocked == true || !task.blockedBy.isEmpty }
    private static func hasParts(_ task: PhoneTask) -> Bool { (task.children?.total ?? 0) > 0 }
    private static func openParts(_ task: PhoneTask) -> Bool { (task.children?.total ?? 0) > (task.children?.closed ?? 0) }
    /// The task's completion card while it is up: its waiting card settles with a merge (`moveContextOf`).
    private static func completionCard(_ task: PhoneTask) -> String? {
        task.waitingCardMerges == true ? task.waitingCardId : nil
    }

    /// What moving `task`, in `from`, to `target` does (`boardMoveOf`).
    public static func move(_ task: PhoneTask, from: Lane, to target: Target) -> Move {
        let key = task.key
        if !movable(from) { return .refused("Closed work stays where it is. Open its record instead.") }
        if target.rawValue == from.rawValue {
            return .none("Already here. The order follows priority and age, so this drop changes nothing.")
        }
        if target == .waiting { return .refused("Only a ready decision puts a task in Waiting on you.") }
        if target == .drop { return dropMove(task) }
        if target == .landed {
            if let card = completionCard(task) {
                return .card(cardID: card, text: "Brings its merge card forward. The card merges; the drop never does.")
            }
            return .refused("No merge card is up for it, so nothing can finish it from here.")
        }
        if from == .waiting {
            return .refused(task.waitingCardId != nil ? "Answer its card first. Moving it cannot dismiss that decision."
                : "It waits for you. Open its record; moving it cannot answer that wait.")
        }
        if from == .queued && PhoneTaskFacts.status(task).mark == "starting" { return .refused("It is starting.") }
        if task.status == "active" { return startedMove(task, from: from, to: target) }
        if from == .working || !PhoneRecord.unstartedWork(task) { return .refused("It has already started.") }
        let waitsOn = keyList(task.blockedBy)
        if target == .backlog {
            return hasParts(task) ? .refused("Its parts are the work. Move a part, not the container.")
                : .now(op: "unqueue-task", text: "It now waits for your word. Its blockers and holds stay.",
                       done: "\(key) moved to Backlog. It waits for your word; its blockers and holds stay.")
        }
        if target == .queued {
            if hasParts(task) { return .refused("Its parts are the work. Queue a part, not the container.") }
            if blocked(task) {
                return .now(op: "queue-task", text: "Queued at once. It starts on its own once \(waitsOn) is done.",
                            done: "\(key) moved to Queued. It starts on its own once \(waitsOn) is done.")
            }
            if task.flags?.held == true {
                return .now(op: "queue-task", text: "Queued at once. It starts on its own once its hold ends.",
                            done: "\(key) moved to Queued. It starts on its own once its hold ends.")
            }
            return .ask(op: "queue-task", sentence: "Start automatically? \(key) can begin at once and spends your plan's allowance.",
                        confirm: PhoneRowMoveWords.queue)
        }
        // Working: the record's Start.
        if blocked(task) {
            return .refused("\(waitsOn) must finish first. \(task.blockedBy.count > 1 ? "The dependencies stay." : "The dependency stays.")")
        }
        if task.flags?.held == true { return .refused("It is held, so a drag cannot start it. Its record's Start can.") }
        if hasParts(task) { return .refused("Its parts are already planned. Start a part, not the container.") }
        if task.startPolicy == "when-ready" { return .refused("It is already queued to start by itself. A drag cannot force a start.") }
        return .ask(op: "start-task", sentence: "Start \(key) now? It spends your plan's allowance; what it waits on is checked again first.",
                    confirm: PhoneRowMoveWords.start)
    }

    /// Started work: Backlog stops its turn and keeps its work, at once; from the backlog, Working is Start, which asks
    /// once. Queued never takes started work.
    private static func startedMove(_ task: PhoneTask, from: Lane, to target: Target) -> Move {
        let key = task.key
        if target == .backlog {
            if let unqueue = task.moves?["unqueue-task"], !unqueue.ok { return .refused(unqueue.text ?? "") }
            return .now(op: "unqueue-task", text: PhoneRowMoveWords.startedBacklog,
                        done: "\(key) moved to Backlog. Its work is kept; Start picks it up.")
        }
        if target == .working && from == .backlog {
            return .ask(op: "start-task",
                        sentence: "Start \(key) again? Its crewmate carries on in the same conversation and spends your plan's allowance.",
                        confirm: PhoneRowMoveWords.start)
        }
        return .refused(from == .backlog ? "It has already started. Start picks it up from the backlog." : "It has already started.")
    }

    /// The Drop task tray: the record's own end, as the row says it - Drop task before the work starts, its stop once it
    /// has.
    private static func dropMove(_ task: PhoneTask) -> Move {
        if openParts(task) { return .refused("Its parts are still open. Drop those first; nothing changes.") }
        if task.moves?["drop-task"]?.ok == true {
            return .ask(op: "drop-task", sentence: PhoneRecord.dropLead(task.key, started: false), confirm: PhoneRecordWords.dropTask)
        }
        if task.moves?["stop-task"]?.ok == true {
            return .ask(op: "stop-task", sentence: PhoneRecord.dropLead(task.key, started: true), confirm: PhoneRecordWords.dropTask)
        }
        return .refused("This task cannot be dropped here. Open its record instead.")
    }

    /// The record's own question for never-started work, from the effects its record lists (`dropAskOf`): the sentence
    /// and the review the host checks again, or why it cannot be dropped.
    public enum DropAsk: Equatable, Sendable {
        case ask(sentence: String, review: [String: [String]])
        case refused(String)
    }

    public static func dropAsk(_ key: String, effects: PhoneTask.DropEffects?) -> DropAsk {
        guard let effects else { return .refused("\(key) changed. Look at it again before dropping it.") }
        if !effects.parts.isEmpty { return .refused(PhoneRecord.dropPartsRefusal(key, parts: effects.parts)) }
        let sentence = [PhoneRecord.dropLead(key, started: false), PhoneRecord.dropWaiting(effects.waiting.map(\.key)),
                        PhoneRecord.dropUnderway(effects.underway.map(\.key))].compactMap(\.self).joined(separator: " ")
        return .ask(sentence: sentence, review: ["parts": effects.parts.map(\.key).sorted(),
                                                 "waiting": effects.waiting.map(\.key).sorted(),
                                                 "underway": effects.underway.map(\.key).sorted()])
    }

    /// The menu (`boardMenuOf`): Open record; Show the card while a decision waits; Continue on interrupted work; Queue it
    /// or Back to backlog and Start now on open work; Back to backlog on started work, and Start now on started work in the
    /// backlog; then Drop task, last, in danger. An entry that cannot run stays, dim, with its reason. Done and Dropped
    /// rows have none.
    public static func menu(_ task: PhoneTask, lane: Lane) -> [Item] {
        if task.key.isEmpty && task.minimizedCardId != nil {
            return [.entry(Entry(id: .card, label: cardLabel, detail: nil, disabled: false, danger: false, target: nil))]
        }
        guard movable(lane) else { return [] }
        var items: [Item] = [.entry(Entry(id: .open, label: openLabel, detail: nil, disabled: false, danger: false, target: nil))]
        if lane == .waiting && (task.waitingCardId != nil || task.minimizedCardId != nil) {
            items.append(.entry(Entry(id: .card, label: cardLabel, detail: nil, disabled: false, danger: false, target: nil)))
        }
        if lane == .working && PhoneTaskFacts.status(task).mark == "interrupted" {
            items.append(.entry(Entry(id: .continue, label: "Continue", detail: "Picks the work up where it stopped",
                                      disabled: false, danger: false, target: nil)))
        }
        if lane == .working && task.status == "active" {
            let back = self.move(task, from: lane, to: .backlog)
            items.append(.entry(Entry(id: .unqueue, label: PhoneRowMoveWords.unqueue,
                                      detail: refusal(back) ?? "Stops its turn, keeps its work · at once",
                                      disabled: refusal(back) != nil, danger: false, target: .backlog)))
        }
        if lane == .backlog || lane == .queued {
            let target: Target = lane == .backlog ? .queued : .backlog
            let shift = self.move(task, from: lane, to: target)
            let detail: String = if let why = refusal(shift) { why }
                else if lane == .queued { "Waits for your word again · at once" }
                else if case .ask = shift { "May start at once · asks once" }
                else if blocked(task) { "Starts by itself once \(keyList(task.blockedBy)) is done · at once" }
                else { "Starts by itself once its hold ends · at once" }
            items.append(.entry(Entry(id: lane == .backlog ? .queue : .unqueue,
                                      label: lane == .backlog ? PhoneRowMoveWords.queue : PhoneRowMoveWords.unqueue,
                                      detail: detail, disabled: refusal(shift) != nil, danger: false, target: target)))
            let start = self.move(task, from: lane, to: .working)
            items.append(.entry(Entry(id: .start, label: PhoneRowMoveWords.startNow, detail: refusal(start) ?? "Asks once · the record's Start",
                                      disabled: refusal(start) != nil, danger: false, target: .working)))
        }
        let drop = self.move(task, from: lane, to: .drop)
        items.append(.separator)
        items.append(.entry(Entry(id: .drop, label: PhoneRecordWords.dropTask, detail: refusal(drop) ?? "Asks once",
                                  disabled: refusal(drop) != nil, danger: true, target: .drop)))
        return items
    }

    private static func refusal(_ move: Move) -> String? { if case .refused(let why) = move { why } else { nil } }

    /// A backlog row's Start (`rowStartOf`): the record's own Start, Try again after a start that failed, and why it
    /// cannot start now; nil on a row with no moves.
    public struct Start: Equatable, Sendable {
        public let label: String
        public let reason: String?
    }

    public static func rowStart(_ task: PhoneTask) -> Start? {
        guard let allowance = task.moves?["start-task"] else { return nil }
        return Start(label: task.startNotice != nil ? PhoneTaskRowWords.tryAgain : PhoneTaskRowWords.start,
                     reason: allowance.ok ? nil : allowance.text)
    }
}
