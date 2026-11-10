import InfinitaryKit
import SwiftUI

/// INF-2935 (INF-2928 piece 2, the captain's direction A): the task record as the Mac's record card draws it
/// (src/renderer/src/cards/RecordCard.tsx, RecordPaneChrome.tsx, RecordHead.tsx and CrewmateView.tsx). The status pill,
/// its reason and the key share the top row over the title; the tabs follow the Mac's (Info, Cards with its count,
/// Activity, Crewmate), and a task with only Info has none. Info, Cards and Activity end with the Mac's record bar; the
/// Crewmate tab ends with its status line and Stop, then the message box, which a closed task does not have.
/// What the record says and offers is `PhoneRecord`'s, replayed against the Mac's own readings.
struct PhoneTaskRecord: View {
    let session: ReadOnlySession
    let initial: PhoneTask
    /// Leaves the record's sheet: Show the card and a card's row take the captain to Home.
    let leave: () -> Void
    @Environment(PhoneMessageContext.self) private var messageContext
    @State private var detail: PhoneTask?
    @State private var crew: PhoneCrew?
    @State private var crewUnreadable = false
    @State private var live: PhoneCrewLive?
    @State private var tab = "info"
    @State private var draft = ""
    @State private var busy = false
    @State private var pressed: String?
    @State private var problem: String?
    @State private var readProblem: String?
    /// Drop task asks once, in the bar, before it drops.
    @State private var dropping = false
    @State private var sent = 0
    @State private var wordsOpen = false
    @State private var moreOpen = false
    @State private var position = ScrollPosition(edge: .top)
    @State private var atEnd = true
    /// The Mac's Crewmate tab follows its end while the captain reads there and stays where they scrolled otherwise;
    /// its newest line stays in sight as the keyboard shortens it.
    @State private var following = true
    @State private var activityEarlier = false
    @State private var planEarlier = false
    /// INF-2553: the record as the home last read it, with the captain's pending start, finish, interrupt or steer
    /// drawn over it.
    private var task: PhoneTask { session.shown(detail ?? initial) }
    private var transcript: PhoneCrew? { crew.map(session.shown) }

    var body: some View {
        let tabs = PhoneRecord.tabs(task)
        let shown = tabs.contains { $0.id == tab } ? tab : "info"
        VStack(spacing: 0) {
            ScrollView {
                // INF-1351: the lazy stack is the scroll view's own content. Nested in a plain stack, its placement and
                // prefetch never settled after a steer, and the main thread stayed busy until the app was stopped.
                LazyVStack(alignment: .leading, spacing: PhoneTheme.space4) {
                    TimelineView(.periodic(from: .now, by: 60)) { clock in head(now: clock.date.timeIntervalSince1970 * 1000) }
                    if !tabs.isEmpty { tabStrip(tabs, shown: shown) }
                    // INF-589 item 11: the reach line says out of reach; this one says only that changes are off.
                    if let words = session.changesOffLine { Text(words).font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary) }
                    if let readProblem { Text(readProblem).foregroundStyle(PhoneTheme.warning) }
                    switch shown {
                    case "cards": cardsContent
                    case "activity": activityContent
                    case "crewmate": crewContent
                    default: TimelineView(.periodic(from: .now, by: 60)) { clock in infoContent(now: clock.date.timeIntervalSince1970 * 1000) }
                    }
                }.padding().frame(maxWidth: PhoneColumn.width).frame(maxWidth: .infinity)
            }
            .scrollPosition($position)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.visibleRect.maxY >= geometry.contentSize.height + geometry.contentInsets.bottom - PhoneTheme.space2
            } action: { _, end in atEnd = end }
            // Only the captain's own scroll, once it rests, stops or resumes following.
            .onScrollPhaseChange { _, phase in if phase == .idle && shown == "crewmate" { following = atEnd } }
            .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.height } action: { _, _ in followEnd(shown) }
            .onChange(of: crewNewest) { followEnd(shown) }
            // The Crewmate tab opens at its end; the other tabs open at their top.
            .onChange(of: shown) { _, now in following = true; position.scrollTo(edge: now == "crewmate" ? .bottom : .top) }
            foot(crewmate: shown == "crewmate")
        }.background(PhoneTheme.background).navigationBarTitleDisplayMode(.inline)
            // INF-589 item 12: a soft tap once the computer accepts a change from the record.
            .sensoryFeedback(.phone, trigger: sent)
            .onAppear { messageContext.taskID = initial.id }
            .task(id: "\(session.contact)|\(shown)") {
                guard session.contact == "in-reach" else { return }
                // Only the open record polls; the board follows pushes. Transcript writes may follow their event.
                while !Task.isCancelled {
                    await refresh(crewmate: shown == "crewmate")
                    do { try await Task.sleep(for: .seconds(1)) } catch { return }
                }
            }
    }

    // MARK: The top (RecordPaneChrome)

    /// The pill with the Tasks list's own mark and word, the reason beside it in its tone, then the key; the title under them.
    @ViewBuilder private func head(now: Double) -> some View {
        let status = PhoneRecord.status(task, now: now)
        let tone = PhoneRecord.pillTone(task)
        VStack(alignment: .leading, spacing: PhoneTheme.space2) {
            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 6) {
                    PhoneTaskMark(status: status)
                    Text(status.word).accessibilityIdentifier("task-record-status")
                }.font(PhoneFont.caption).fixedSize()
                    .foregroundStyle(tone == "accent" ? PhoneTheme.accent : tone == "danger" ? PhoneTheme.danger : PhoneTheme.secondary)
                    .padding(.horizontal, PhoneTheme.space2).padding(.vertical, 3)
                    .background(tone == "accent" ? PhoneTheme.accentDim : tone == "danger" ? PhoneTheme.danger.opacity(0.14) : PhoneTheme.raised,
                                in: Capsule())
                if !status.reason.isEmpty {
                    let reasonTone = PhoneRecord.reasonTone(status.reason)
                    Text(status.reason).font(PhoneFont.caption)
                        .foregroundStyle(reasonTone == "warning" ? PhoneTheme.warning : reasonTone == "plain" ? PhoneTheme.secondary : PhoneTheme.muted)
                        .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("task-record-reason")
                }
                Text(task.key).font(PhoneFont.mono).foregroundStyle(PhoneTheme.muted).lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("task-record-key")
            }
            Text(task.title).font(PhoneFont.title).fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader).accessibilityIdentifier("task-record-title")
        }
    }

    private func tabStrip(_ tabs: [PhoneRecord.Tab], shown: String) -> some View {
        HStack(spacing: PhoneTheme.space5) {
            ForEach(tabs, id: \.id) { item in
                let current = item.id == shown
                Button { tab = item.id } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(item.label)
                        if case .cards(let count) = item { Text("\(count)").font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted) }
                    }.font(PhoneFont.callout).foregroundStyle(current ? PhoneTheme.text : PhoneTheme.secondary)
                        .frame(minHeight: 44)
                        .overlay(alignment: .bottom) { if current { Rectangle().fill(PhoneTheme.accent).frame(height: 2) } }
                        .contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel(item.label)
                    .accessibilityValue({ if case .cards(let count) = item { "\(count)" } else { "" } }())
                    .accessibilityAddTraits(current ? .isSelected : []).accessibilityIdentifier("record-tab-\(item.id)")
            }
            Spacer(minLength: 0)
        }.overlay(alignment: .bottom) { Rectangle().fill(PhoneTheme.line).frame(height: 1) }
    }

    // MARK: Info (RecordHead and TaskFactRows)

    @ViewBuilder private func infoContent(now: Double) -> some View {
        let attention = PhoneRecord.attention(task, now: now)
        let facts = PhoneTaskFacts(task, modelName: { model in task.modelLabel ?? PhoneCrewSummary.modelTail(model) })
        VStack(alignment: .leading, spacing: PhoneTheme.space4) {
            if let attention, attention.urgent { attentionBox(attention) }
            if let filing = task.filing, task.status == "open" {
                VStack(alignment: .leading, spacing: 4) {
                    PhoneFactLabel(text: "Why")
                    Text(filing.why.isEmpty ? "No reason was recorded." : filing.why).foregroundStyle(PhoneTheme.text)
                    Text(filing.verdict.map { "First mate: \($0)" } ?? "Your first mate has not said yet.").foregroundStyle(PhoneTheme.muted)
                }.accessibilityElement(children: .combine).accessibilityIdentifier("task-record-why")
            }
            if let attention, !attention.urgent { attentionBox(attention) }
            if attention == nil, let closed = PhoneRecord.closedLine(task) {
                Text(closed.words(now: now)).foregroundStyle(PhoneTheme.muted).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("task-record-closed")
            }
            VStack(alignment: .leading, spacing: Self.rowGap) {
                relations
                goal(now: now)
                if let project = task.repo?.name ?? session.board?.projects.first(where: { $0.id == task.projectId })?.name {
                    row("Project") { Text(project).foregroundStyle(PhoneTheme.text) }
                }
                if let current = facts.now {
                    row("Now") {
                        HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space2) {
                            Text(current.text).frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("task-record-now")
                            PhoneFactAge(words: PhoneTaskFacts.relativeAge(current.at, now: max(now, current.at)))
                        }
                    }
                }
                if let plan = facts.plan, !plan.items.isEmpty { progress(plan, now: now) }
            }
            strip(facts, now: now)
            if let more = PhoneRecord.more(task) { moreRow(more) }
        }.font(PhoneFont.summary).foregroundStyle(PhoneTheme.secondary)
    }

    private func attentionBox(_ attention: PhoneRecord.Attention) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(attention.title).foregroundStyle(PhoneTheme.text).accessibilityIdentifier("task-record-attention")
            if !attention.guidance.isEmpty { Text(attention.guidance).foregroundStyle(PhoneTheme.secondary) }
        }.fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
            .padding(PhoneTheme.space3)
            .background((attention.danger ? PhoneTheme.danger : PhoneTheme.warning).opacity(0.14),
                        in: RoundedRectangle(cornerRadius: PhoneTheme.controlRadius, style: .continuous))
            .accessibilityElement(children: .combine)
    }

    /// Part of, Waits on, Holds up and Parts; each key opens that task's record in this sheet.
    @ViewBuilder private var relations: some View {
        if let parent = task.parentId.flatMap({ id in session.board?.tasks.first { $0.id == id } }) {
            row("Part of", id: "task-record-part-of") { keys([parent.key]) }
        }
        if !task.blockedBy.isEmpty { row("Waits on", id: "task-record-waits-on") { keys(task.blockedBy) } }
        if let blocks = task.blocks, !blocks.isEmpty { row("Holds up", id: "task-record-holds-up") { keys(blocks) } }
        if let children = task.children, children.total > 0 {
            row("Parts") { Text("\(children.closed) of \(children.total) closed").foregroundStyle(PhoneTheme.text) }
        }
    }

    private func keys(_ list: [String]) -> some View {
        PhoneFlowRow(spacing: PhoneTheme.space3) { ForEach(list, id: \.self) { key in keyLink(key) } }
    }

    @ViewBuilder private func keyLink(_ key: String) -> some View {
        if let other = session.board?.tasks.first(where: { $0.key == key }) {
            NavigationLink { PhoneTaskRecord(session: session, initial: other, leave: leave) } label: {
                Text(key).font(PhoneFont.mono).foregroundStyle(PhoneTheme.accent)
                    // Each key answers a 44-point touch without spacing the row apart.
                    .padding(.vertical, 12).contentShape(Rectangle()).padding(.vertical, -12)
            }.buttonStyle(.plain).accessibilityIdentifier("task-record-key-\(key)")
        } else {
            Text(key).font(PhoneFont.mono).foregroundStyle(PhoneTheme.secondary)
        }
    }

    /// The goal, with the captain's words folded under it beside why it was filed and why there was no plan.
    @ViewBuilder private func goal(now: Double) -> some View {
        let fold = PhoneRecord.wordsFoldName(task)
        if task.goal != nil || fold != nil {
            row("Goal") {
                VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                    if let goal = task.goal { Text(goal).foregroundStyle(PhoneTheme.text).textSelection(.enabled) }
                    if let fold {
                        DisclosureGroup(isExpanded: $wordsOpen) { foldBody(now: now) } label: {
                            Text(fold).font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
                        }.tint(PhoneTheme.muted).accessibilityIdentifier("task-record-words")
                    }
                }
            }
        }
    }

    private func foldBody(now: Double) -> some View {
        let words = task.intent?.userWords ?? ""
        let asks = PhoneRecord.asks(task)
        let closed = task.status == "done" || task.status == "dropped"
        return VStack(alignment: .leading, spacing: PhoneTheme.space3) {
            if let filing = task.filing, task.status != "open" {
                VStack(alignment: .leading, spacing: 4) {
                    PhoneFactLabel(text: "Why it was filed")
                    Text(filing.why.isEmpty ? "No reason was recorded." : filing.why)
                    if !closed { Text(filing.verdict.map { "First mate: \($0)" } ?? "Your first mate has not said yet.").foregroundStyle(PhoneTheme.muted) }
                }
            }
            if let skipped = task.skippedPlanBecause, !skipped.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    PhoneFactLabel(text: "Why your first mate built without a plan")
                    Text(skipped)
                }
            }
            if !words.isEmpty || !asks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    PhoneFactLabel(text: "You said")
                    if !words.isEmpty {
                        Text(words).foregroundStyle(PhoneTheme.text).textSelection(.enabled)
                            .padding(.leading, PhoneTheme.space3)
                            .overlay(alignment: .leading) { Rectangle().fill(PhoneTheme.line).frame(width: 2) }
                    }
                    ForEach(asks) { ask in
                        HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space2) {
                            PhoneFactAge(words: PhoneTaskFacts.relativeAge(ask.at, now: max(now, ask.at)))
                            Text(ask.text).foregroundStyle(PhoneTheme.text).textSelection(.enabled)
                        }
                    }
                }
            }
        }.fixedSize(horizontal: false, vertical: true).padding(.top, PhoneTheme.space2)
    }

    /// The plan as the record lists it: every item with its mark, a finished one with when it finished; past a few,
    /// the finished ones wait behind Show earlier, as Activity's do.
    private func progress(_ plan: PhoneTask.Plan, now: Double) -> some View {
        let counts = PhoneTaskFacts.planCounts(plan.items)
        let fold = planEarlier ? nil : PhoneTaskFacts.foldPlan(plan.items, state: \.state)
        return row("Progress") {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(counts.done) of \(counts.total)").font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted)
                if let fold {
                    Button("Show earlier · \(fold.folded.count)") { planEarlier = true }.buttonStyle(.plain)
                        .font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary).frame(minHeight: 44)
                }
                ForEach(Array((fold?.rest ?? plan.items).enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space2) {
                        PhonePlanMark(state: item.state).alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
                        (Text(item.label).foregroundStyle(item.state == "current" ? PhoneTheme.text : PhoneTheme.secondary)
                         + Text(item.state == "skipped" ? " skipped" : "").foregroundStyle(PhoneTheme.muted))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if item.state == "done", let since = item.since {
                            PhoneFactAge(words: PhoneTaskFacts.relativeAge(since, now: max(now, since)))
                        }
                    }
                }
            }.accessibilityElement(children: .contain).accessibilityIdentifier("task-record-progress")
        }
    }

    /// The row of facts under a hairline: the model with its intelligence, Reasoning, the change with its checks, a
    /// review's verdict, Delivery and Runs on, then the reasoning's footnote.
    @ViewBuilder private func strip(_ facts: PhoneTaskFacts, now: Double) -> some View {
        let delivery = PhoneRecord.deliveryWords(task)
        let change = facts.delivery?.change, checks = facts.delivery?.checks
        if facts.model != nil || facts.reasoning != nil || change != nil || checks != nil || facts.delivery?.review != nil
            || !delivery.isEmpty || task.runsOn != nil {
            VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                PhoneFlowRow(spacing: PhoneTheme.space3) {
                    if let model = facts.model {
                        cell("Model") {
                            HStack(spacing: PhoneTheme.space2) {
                                Text(model).lineLimit(1).accessibilityIdentifier("task-record-model")
                                if let tier = facts.tier { PhoneSlotBadge(slot: tier).fixedSize() }
                            }
                        }
                    }
                    if let reasoning = facts.reasoning {
                        cell("Reasoning") { Text(reasoning).accessibilityIdentifier("task-record-reasoning") }
                    }
                    if change != nil || checks != nil {
                        cell(change?.noun ?? "Checks") {
                            HStack(spacing: PhoneTheme.space2) {
                                if let change {
                                    let words = change.label ?? change.noun
                                    if let url = change.url.flatMap(URL.init(string:)) {
                                        Link(words, destination: url).foregroundStyle(PhoneTheme.accent)
                                    } else { Text(words) }
                                }
                                if let checks {
                                    HStack(spacing: 4) {
                                        PhoneFactDot(state: checks.dot)
                                        Text(checks.spanWords(now: now)).accessibilityIdentifier("task-record-checks")
                                    }
                                }
                            }
                        }
                    }
                    if let review = facts.delivery?.review {
                        cell("Review") { HStack(spacing: 4) { PhoneFactDot(state: review.dot); Text(review.words) } }
                    }
                    if !delivery.isEmpty { cell("Delivery") { Text(delivery).accessibilityIdentifier("task-record-delivery") } }
                    if let runsOn = task.runsOn { cell("Runs on") { Text(runsOn.label).accessibilityIdentifier("task-record-runs-on") } }
                }
                if let reason = facts.reason { Text(reason).font(PhoneFont.caption).foregroundStyle(PhoneTheme.muted) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, PhoneTheme.space3)
            .overlay(alignment: .top) { Rectangle().fill(PhoneTheme.line).frame(height: 1) }
        }
    }

    /// The record's one closed More row: who works it, the branch and the task's policies with where each came from.
    private func moreRow(_ more: PhoneRecord.More) -> some View {
        DisclosureGroup(isExpanded: $moreOpen) {
            VStack(alignment: .leading, spacing: Self.rowGap) {
                ForEach(more.facts, id: \.id) { fact in
                    row(fact.term) {
                        HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space2) {
                            Text(fact.value).foregroundStyle(PhoneTheme.text)
                            if let source = fact.source { Text(source).font(PhoneFont.caption).foregroundStyle(PhoneTheme.muted) }
                        }
                    }
                }
                if !more.helper.isEmpty { Text(more.helper).font(PhoneFont.caption).foregroundStyle(PhoneTheme.muted) }
            }.fixedSize(horizontal: false, vertical: true).padding(.top, PhoneTheme.space2)
        } label: {
            HStack(spacing: PhoneTheme.space2) {
                Text("More").foregroundStyle(PhoneTheme.secondary)
                if !moreOpen && !more.preview.isEmpty { Text(more.preview).font(PhoneFont.caption).foregroundStyle(PhoneTheme.muted).lineLimit(1) }
            }
        }.tint(PhoneTheme.muted).accessibilityIdentifier("task-record-more")
    }

    private func row(_ label: String, id: String? = nil, @ViewBuilder value: () -> some View) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Self.labelGap) {
            PhoneFactLabel(text: label).frame(width: Self.labelWidth, alignment: .leading)
            value().frame(maxWidth: .infinity, alignment: .leading)
        }.accessibilityElement(children: .contain).accessibilityIdentifier(id ?? "task-record-\(label.lowercased())")
    }

    private func cell(_ label: String, @ViewBuilder value: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            PhoneFactLabel(text: label).fixedSize()
            value().foregroundStyle(PhoneTheme.text)
        }
    }

    private static let labelWidth: CGFloat = 66
    private static let labelGap: CGFloat = 10
    private static let rowGap: CGFloat = 6

    // MARK: Cards and Activity (the record body)

    /// Every card the task showed, newest first: open on the stage or put aside, or closed with how it ended. A row
    /// shows its card on Home.
    @ViewBuilder private var cardsContent: some View {
        TimelineView(.periodic(from: .now, by: 60)) { clock in
            let now = clock.date.timeIntervalSince1970 * 1000
            VStack(alignment: .leading, spacing: 0) {
                ForEach(task.cards ?? []) { card in
                    Button { show(card) } label: {
                        HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space3) {
                            Text(card.kind == "note" ? "Note" : "Decision").font(PhoneFont.mono).foregroundStyle(PhoneTheme.muted)
                            Text(card.title).foregroundStyle(PhoneTheme.text).frame(maxWidth: .infinity, alignment: .leading)
                            Text(card.state == "open" ? (card.minimized == true ? "Put aside" : "On the stage")
                                 : "\(card.ending ?? "Closed") · \(PhoneTaskFacts.relativeAge(card.at, now: max(now, card.at)))")
                                .font(PhoneFont.caption).foregroundStyle(PhoneTheme.muted)
                        }.padding(.vertical, PhoneTheme.space3).frame(minHeight: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain).disabled(!session.canChange && card.state == "open" && card.minimized == true)
                        .accessibilityIdentifier("record-card-\(card.id)")
                        .overlay(alignment: .bottom) { Rectangle().fill(PhoneTheme.line).frame(height: 1) }
                }
            }.font(PhoneFont.summary)
        }
    }

    private func show(_ card: PhoneTask.CardRow) {
        if card.state == "open" {
            if card.minimized == true {
                guard session.canChange else { return }
                Task { try? await session.change(.bringBack(card: card.id), .minimize, [.string(card.id), .bool(false)]) }
            }
            messageContext.restoring = card.id
            leave()
            return
        }
        Task {
            try? await session.readPast(card.id)
            messageContext.pastCard = card.id
            leave()
        }
    }

    /// The task's activity, oldest first, the last eight shown and the rest behind Show earlier, as on the Mac.
    @ViewBuilder private var activityContent: some View {
        let rows = task.activityLog ?? []
        let earlier = max(0, rows.count - Self.activityTail)
        let outcome = task.outcome ?? ""
        let closing = outcome.isEmpty ? nil : rows.lastIndex { $0.kind == "status" && $0.from == nil }
        TimelineView(.periodic(from: .now, by: 60)) { clock in
            let now = clock.date.timeIntervalSince1970 * 1000
            VStack(alignment: .leading, spacing: PhoneTheme.space3) {
                if earlier > 0 && !activityEarlier {
                    Button("Show earlier · \(earlier)") { activityEarlier = true }.buttonStyle(.plain)
                        .font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary).frame(minHeight: 44)
                        .accessibilityIdentifier("record-activity-earlier")
                }
                ForEach(Array(rows.enumerated()).filter { activityEarlier || $0.offset >= earlier }, id: \.offset) { index, row in
                    activityRow(row, whole: index == closing ? outcome : nil, now: now)
                }
            }.font(PhoneFont.summary)
        }
    }

    /// One row: its age, its words and the task it came from; the events folded under it and the whole words of a
    /// closing report open beneath it, with their count beside it.
    @ViewBuilder private func activityRow(_ row: PhoneTask.ActivityRow, whole: String?, now: Double) -> some View {
        let folded = ((row.folded ?? []).map { ($0.at, $0.text) } + (row.actions ?? []).map { ($0.at, $0.text) }).sorted { $0.0 < $1.0 }
        let says = whole.map { words in
            let trimmed = words.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty && trimmed != row.text.trimmingCharacters(in: .whitespacesAndNewlines)
        } ?? false
        if row.from != nil || (!says && folded.isEmpty) {
            activityLine(row, now: now).accessibilityElement(children: .contain).accessibilityIdentifier("record-activity-\(row.kind)")
        } else {
            DisclosureGroup { foldedLines(folded, whole: says ? whole : nil, now: now) } label: {
                HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space2) {
                    activityLine(row, now: now)
                    if !folded.isEmpty { Text("+\(folded.count)").font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted) }
                }
            }.tint(PhoneTheme.muted).accessibilityIdentifier("record-activity-\(row.kind)")
        }
    }

    private func activityLine(_ row: PhoneTask.ActivityRow, now: Double) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space2) {
            Text(PhoneTaskFacts.relativeAge(row.at, now: max(now, row.at))).font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted)
                .frame(width: 30, alignment: .leading)
            Text(row.text).foregroundStyle(PhoneTheme.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
            if let from = row.from {
                HStack(spacing: 4) {
                    Text("from").font(PhoneFont.caption).foregroundStyle(PhoneTheme.muted)
                    keyLink(from.key)
                }
            }
        }
    }

    private func foldedLines(_ lines: [(Double, String)], whole: String?, now: Double) -> some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space2) {
            if let whole { Text(whole).foregroundStyle(PhoneTheme.secondary).textSelection(.enabled) }
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space2) {
                    Text(PhoneTaskFacts.relativeAge(line.0, now: max(now, line.0))).font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted)
                        .frame(width: 30, alignment: .leading)
                    Text(line.1).foregroundStyle(PhoneTheme.secondary).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }.padding(.top, PhoneTheme.space2)
    }

    private static let activityTail = 8

    // MARK: Crewmate (CrewmateView)

    /// What changes when a line arrives, a sent line is answered or the crewmate writes more.
    private var crewNewest: String {
        let last = transcript?.lines.last
        return "\(transcript?.lines.count ?? 0)|\(last?.id ?? "")|\(last?.sending == true)|\(live?.text.count ?? 0)"
    }

    private func followEnd(_ shown: String) {
        if shown == "crewmate" && following { position.scrollTo(edge: .bottom) }
    }

    /// The transcript's rows sit straight in the record's lazy stack, so only the lines on screen are laid out.
    @ViewBuilder private var crewContent: some View {
        if let crew = transcript {
            if crew.earlier > 0 { Text("\(crew.earlier) earlier entries are not shown.").font(PhoneFont.caption) }
            if crew.lines.isEmpty { Text(PhoneRecordWords.crewEmpty).foregroundStyle(PhoneTheme.secondary) }
            ForEach(crew.lines) { line in
                VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                    if line.kind == "sent" && line.from != "captain" {
                        Text(line.from == "firstmate" ? PhoneRecordWords.crewFirstmate : PhoneRecordWords.crewApp).font(PhoneFont.caption)
                    }
                    if line.sending { Text("Sending…").font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted).accessibilityIdentifier("crew-sending") }
                    if let name = line.name { Text("\(name) · \(line.target ?? "")").font(PhoneFont.mono) }
                    if line.kind == "brief" || line.kind == "report" {
                        DisclosureGroup(line.summary ?? (line.kind == "brief" ? PhoneRecordWords.crewBrief : "Report")) { Text(line.words).textSelection(.enabled) }
                    } else {
                        Text(line.words).textSelection(.enabled)
                            .foregroundStyle(line.kind == "sent" && line.from == "captain" ? PhoneTheme.captain : PhoneTheme.text)
                    }
                    if let result = line.result { CrewResult(session: session, taskID: task.id, result: result) }
                // A container keeps its rows' own names; an identifier on a bare stack is handed to every row inside it.
                }.accessibilityElement(children: .contain).accessibilityIdentifier("crew-line-\(line.kind)")
            }
        } else if crewUnreadable {
            Text(PhoneRecordWords.crewUnreadable).foregroundStyle(PhoneTheme.warning)
        }
        if let text = live?.text, !text.isEmpty { Text(text).accessibilityIdentifier("crew-live") }
    }

    /// Working with how long its turn has run and Stop, Paused, Waiting on you or Idle; nothing once the task closed.
    @ViewBuilder private var crewStatus: some View {
        let state = PhoneRecord.crewState(task, live: live)
        if let words = PhoneRecord.crewWords(state) {
            HStack(spacing: PhoneTheme.space2) {
                Circle().fill(state == .working || state == .paused ? PhoneTheme.accent : state == .waiting ? PhoneTheme.warning : PhoneTheme.idle)
                    .frame(width: 7, height: 7).accessibilityHidden(true)
                Text(words).accessibilityIdentifier("crew-status")
                if state == .working {
                    if let since = live?.since {
                        TimelineView(.periodic(from: .now, by: 1)) { clock in
                            Text(PhoneRecord.elapsed(clock.date.timeIntervalSince1970 * 1000 - since)).font(PhoneFont.mono)
                                .foregroundStyle(PhoneTheme.muted).accessibilityIdentifier("crew-elapsed")
                        }
                    }
                    Spacer(minLength: PhoneTheme.space2)
                    let stopping = task.activity == "stopping"
                    Button(stopping ? PhoneRecordWords.crewStopping : PhoneRecordWords.crewStop) {
                        change(.interrupt(task: task.id), .interrupt, args: [task.id], from: "crew-stop")
                    }.buttonStyle(PhoneChoiceStyle(.secondary)).disabled(stopping || busy || !session.canChange)
                        .keyboardShortcut("c", modifiers: .control).accessibilityIdentifier("crew-stop")
                } else { Spacer(minLength: 0) }
            }.font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary).frame(minHeight: 44)
        }
    }

    // MARK: The foot

    /// INF-589 item 10: the record's foot reads as a card's footer, on the panel color under a hairline. Info, Cards and
    /// Activity end with the record bar; the Crewmate tab ends with its status line and the message box.
    @ViewBuilder private func foot(crewmate: Bool) -> some View {
        let bar = PhoneRecord.bar(task)
        let closed = PhoneRecord.crewState(task, live: live) == .closed
        let showsBar = !crewmate && bar.map { $0.end != nil || $0.next != nil } == true
        if crewmate || showsBar || problem != nil || session.changeNotice != nil {
            VStack(alignment: .leading, spacing: PhoneTheme.space3) {
                if let problem { Text(problem).font(PhoneFont.callout).foregroundStyle(PhoneTheme.warning).accessibilityIdentifier("task-problem") }
                // INF-2553: why a change shown at the tap was taken back, said where the captain is.
                if let notice = session.changeNotice {
                    Text(notice.words).font(PhoneFont.callout).foregroundStyle(PhoneTheme.warning).accessibilityIdentifier("task-change-notice")
                }
                if crewmate {
                    crewStatus
                    if closed { Text(PhoneRecordWords.crewClosed).font(PhoneFont.callout).foregroundStyle(PhoneTheme.muted).accessibilityIdentifier("crew-closed") }
                    else { steerBox }
                } else if let bar, showsBar { recordBar(bar) }
            }.padding(PhoneTheme.space4).frame(maxWidth: PhoneColumn.width).frame(maxWidth: .infinity)
                .background(PhoneTheme.panel)
                .overlay(alignment: .top) { Rectangle().fill(PhoneTheme.line).frame(height: 1) }
        }
    }

    /// The Mac's record bar: Drop task or Decline at the leading edge, the next step at the trailing edge; Drop task asks
    /// once between them before it drops.
    @ViewBuilder private func recordBar(_ bar: PhoneRecord.Bar) -> some View {
        if dropping, let end = bar.end, end != .dismissQuestion {
            VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                Text(PhoneRecord.dropQuestion(task, end: end)).font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("drop-question")
                PhoneChoiceRow {
                    Button(PhoneRecordWords.dropCancel) { dropping = false }.buttonStyle(PhoneChoiceStyle(.secondary))
                        .disabled(busy).keyboardShortcut(.cancelAction).accessibilityIdentifier("drop-cancel")
                        .layoutValue(key: PhoneChoiceRow.Leading.self, value: true)
                    choice(PhoneRecordWords.dropTask, id: "drop-confirm", kind: .danger) { drop(end) }
                }
            }
        } else {
            PhoneChoiceRow {
                switch bar.end {
                case .dismissQuestion:
                    choice(PhoneCardWords.decline, id: "dismiss-question", kind: .secondary) {
                        change(.finish(task: task.id, ending: .dismissQuestion), .run, args: [task.id, PhoneTaskEnding.dismissQuestion.rawValue], from: "dismiss-question")
                    }.layoutValue(key: PhoneChoiceRow.Leading.self, value: true)
                case .dropTask, .stopTask:
                    choice(PhoneRecordWords.dropTask, id: "drop-task", kind: .secondary) { beginDrop(bar.end) }
                        .layoutValue(key: PhoneChoiceRow.Leading.self, value: true)
                case nil: EmptyView()
                }
                if let next = bar.next { nextButton(next, blocked: bar.blocked) }
            }
        }
    }

    @ViewBuilder private func nextButton(_ next: PhoneRecord.Next, blocked: Bool) -> some View {
        let label = PhoneRecordWords.next[next.rawValue] ?? next.rawValue
        switch next {
        case .starting:
            choice(label, id: "record-starting", kind: .primary) {}.disabled(true)
        case .showCard:
            choice(label, id: "show-card", kind: .primary) { showCard() }
        case .answerDone:
            choice(label, id: "record-answer-done", kind: .primary) {
                change(.finish(task: task.id, ending: .answerDone), .run, args: [task.id, PhoneTaskEnding.answerDone.rawValue], from: "record-answer-done")
            }.accessibilityHint(PhoneCardWords.doneRest(task.key))
        case .startAgain:
            choice(label, id: "start-again", kind: .primary) { run("start-again") }.disabled(blocked)
        case .start, .tryAgain, .continue:
            let move = next.move ?? "start-task"
            choice(label, id: move, kind: .primary) {
                change(.start(task: task.id, move: move), .run, args: [task.id, move], from: move)
            }.disabled(blocked)
        }
    }

    private func choice(_ title: String, id: String, kind: PhoneChoiceStyle.Kind, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).opacity(busy && pressed == id ? 0 : 1)
                .overlay { if busy && pressed == id { ProgressView() } }
        }.buttonStyle(PhoneChoiceStyle(kind)).disabled(busy || !session.canChange).accessibilityIdentifier(id)
    }

    // The composer's capsule, with Steer as its send arrow, dimmed until there are words to send.
    private var steerBox: some View {
        let working = PhoneRecord.crewState(task, live: live) == .working
        return HStack(alignment: .center, spacing: PhoneTheme.space2) {
            // INF-2553: the steer shows in the transcript at the tap, so the box stays open for the next one.
            TextField(working ? PhoneRecordWords.crewPlaceholderWorking : PhoneRecordWords.crewPlaceholderIdle, text: $draft, axis: .vertical)
                .lineLimit(1...4).accessibilityLabel(PhoneRecordWords.crewField).accessibilityIdentifier("steer-box")
            Button {
                change(.steer(task: task.id, text: draft, before: PhoneIntentLedger.captainSteers(transcript)), .steer,
                       args: [task.id, draft], clearDraft: true, from: "steer-task")
            } label: {
                Label("Steer", systemImage: "arrow.up.circle.fill").labelStyle(.iconOnly)
                    .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
            }.disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || busy || !session.canChange)
                .keyboardShortcut(.return, modifiers: .command).accessibilityIdentifier("steer-task")
        }.font(PhoneFont.callout)
            .padding(.leading, PhoneTheme.space4).padding(.trailing, PhoneTheme.space2)
            .background(PhoneTheme.surface, in: Capsule())
            .overlay { Capsule().strokeBorder(PhoneTheme.line) }
    }

    // MARK: Reading and changing

    private func refresh(crewmate: Bool) async {
        do {
            let next = try await session.readDetail(initial.id)
            guard !Task.isCancelled else { return }
            detail = next; readProblem = nil
            if crewmate && next.startedAt != nil {
                do {
                    let read = try await session.readCrew(initial.id)
                    let running: PhoneCrewLive = try await session.request(.live, args: [initial.id])
                    guard !Task.isCancelled else { return }
                    crew = read; live = running; crewUnreadable = false
                } catch { if !Task.isCancelled && crew == nil { crewUnreadable = true } }
            }
        } catch { if !Task.isCancelled { readProblem = error.localizedDescription } }
    }

    /// Drop task's first press: a record that changed, or parts still open, say why instead of asking.
    private func beginDrop(_ end: PhoneRecord.End?) {
        guard let end else { return }
        problem = PhoneRecord.dropRefusal(task, end: end)
        dropping = problem == nil
    }

    /// The Mac's own drop, with what the captain was told: the parts, the tasks waiting and the ones working.
    private func drop(_ end: PhoneRecord.End) {
        var args: [Any] = [task.id, end.rawValue]
        if end == .dropTask, let effects = task.dropEffects {
            args.append(["parts": effects.parts.map(\.key), "waiting": effects.waiting.map(\.key), "underway": effects.underway.map(\.key)])
        }
        run(end.rawValue, args: args)
    }

    /// A move the phone draws no intent for - Start again and Drop task: the bar waits on the computer's answer, then
    /// reads the record again; a refusal stays in the foot, as on the Mac.
    private func run(_ op: String, args: [Any]? = nil) {
        guard !busy, session.canChange else { return }
        busy = true; pressed = op == "stop-task" || op == "drop-task" ? "drop-confirm" : op; problem = nil
        Task {
            defer { busy = false }
            do {
                let answer: PhoneAnswer = try await session.request(.run, args: args ?? [task.id, op])
                if answer.ok { sent += 1; dropping = false } else { problem = answer.text ?? "Your computer could not make this change." }
            } catch { problem = error.localizedDescription }
            await refresh(crewmate: false)
        }
    }

    /// Show the card, through the one move the Mac runs it by: once the computer shows the card again, Home shows it.
    private func showCard() {
        guard !busy else { return }
        busy = true; pressed = "show-card"; problem = nil
        Task {
            defer { busy = false }
            do {
                let answer: PhoneAnswer = try await session.request(.run, args: [task.id, "show-card"])
                guard answer.ok else { problem = answer.text ?? "Your computer could not show the card."; return }
                if let card = try await session.readDetail(task.id).waitingCardId ?? task.waitingCardId {
                    messageContext.restoring = card
                    leave()
                }
            } catch { problem = error.localizedDescription }
        }
    }

    /// INF-2553: the record shows the change at the tap and a steer's draft clears; the session takes a refused change
    /// back, says why in the foot and puts the draft back.
    private func change(_ kind: PhoneIntent.Kind, _ channel: PhoneRequest, args: [Any], clearDraft: Bool = false, from control: String) {
        guard !busy, session.canChange else { return }
        if clearDraft && draft.utf16.count > PhoneLimits.steer { problem = "This message is too long. Shorten it before sending."; return }
        let words = draft
        busy = true; pressed = control; problem = nil
        if clearDraft { draft = "" }
        let box = $draft
        var restore: (@MainActor () -> Void)?
        if clearDraft { restore = { @MainActor in if box.wrappedValue.isEmpty { box.wrappedValue = words } } }
        Task {
            defer { busy = false }
            do {
                try await session.change(kind, channel, args: args, restore: restore)
                sent += 1
                await refresh(crewmate: kind.isSteer)
            } catch {}
        }
    }
}

private extension PhoneIntent.Kind {
    var isSteer: Bool { if case .steer = self { true } else { false } }
}

private struct CrewResult: View {
    let session: ReadOnlySession
    let taskID: String
    let result: PhoneCrew.Line.Result
    @State private var open = false
    @State private var text: String?
    var body: some View {
        DisclosureGroup("\(result.lines) lines · \(result.preview)", isExpanded: $open) {
            Text(text ?? "Reading…").textSelection(.enabled).font(PhoneFont.mono)
        }.task(id: open) {
            guard open else { return }
            do {
                let read: PhoneResultText? = try await session.request(.result, args: [taskID, result.ref])
                guard !Task.isCancelled else { return }
                text = read.map { $0.text + ($0.cut > 0 ? "\n\($0.cut) more characters are not shown." : "") } ?? "No result to read."
            } catch { text = error.localizedDescription }
        }
    }
}
