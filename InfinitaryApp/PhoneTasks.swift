import InfinitaryKit
import SwiftUI

/// The record's corner changes only which local view is shown, never the task.
struct PhoneRecordLeaveButton: View {
    @Binding var record: PhoneTask?
    var body: some View {
        Button { record = nil } label: {
            Label(PhoneCardWords.recordLeave, systemImage: "minus").labelStyle(.iconOnly)
        }.frame(minWidth: 44, minHeight: 44)
            .foregroundStyle(PhoneTheme.secondary)
            .keyboardShortcut("m", modifiers: [.command, .shift])
            .accessibilityHint(PhoneCardWords.recordLeaveRest)
            .accessibilityIdentifier("close-record")
    }
}

struct PhoneTasks: View {
    let session: ReadOnlySession
    @Environment(PhoneMessageContext.self) private var messageContext
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.verticalSizeClass) private var verticalSize
    @State private var query = ""
    @State private var searchOpen = false
    @State private var focusOnOpen = false
    @FocusState private var searchFocused: Bool
    @State private var earlier: [PhoneTask] = []
    @State private var problem: String?
    @State private var selected: PhoneTask?
    /// The folding groups, Backlog and Done, the captain opened; the Mac's other groups always show their rows.
    @State private var expanded: Set<PhoneTaskList.Section> = []
    /// INF-2928 piece 3: a move from a row's long press that asks once before it runs, as the Mac's board asks.
    @State private var asking: RowAsk?
    /// The Backlog row a swipe holds open on its Start, and how far a swipe under way has moved a row.
    @State private var swiped: String?
    @State private var swiping: (id: String, x: CGFloat)?
    /// The list's width, which a long press's summary takes up to the Mac's own width for it.
    @State private var columnWidth: CGFloat = 0
    // Board/List opens on Board, then remembers the last view; the project pill filters both.
    @AppStorage("phone.tasksBoard") private var showBoard = true
    @State private var project: String?
    @State private var boardColumn: PhoneTaskGroup? = .waiting

    /// INF-2764: whether this list is on screen. The tab controller keeps a tab that is away, so a hidden list keeps
    /// its last reading and reads nothing from the session: a board update while another tab shows rebuilds nothing.
    @Environment(\.phoneTasksShown) private var shown
    @State private var kept = PhoneTasksKept()

    /// The list as it reads now, built once per drawing while it shows, and the last one kept while it is hidden.
    private func reading() -> PhoneTasksKept.Reading {
        if !shown, let last = kept.last { return last }
        let reading = PhoneTasksKept.Reading(
            list: PhoneTaskList(board: session.board, cards: session.cards, query: query, earlier: earlier),
            asideLine: asideLine)
        kept.last = reading
        PhoneTasksKept.built(shown: shown, seq: reading.list.board?.seq)
        return reading
    }

    // INF-589 item 9: search waits above the list until it is pulled down, as the Mac's sits behind its icon.
    // VoiceOver cannot pull past the top of a list, so it always finds the field.
    private var searchShown: Bool { searchOpen || !query.isEmpty || voiceOver }
    private var searching: Bool { !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    /// INF-2928, the captain's pick: a title may take two lines on an iPhone, which has no pointer to show the rest, and
    /// one on an iPad, as on the Mac.
    private var titleLines: Int { UIDevice.current.userInterfaceIdiom == .pad ? 1 : 2 }

    /// INF-2553: on an iPhone on its side, a card brought back and put aside again by its refusal says why on this
    /// list's line, as a refused bring-back did before.
    private var asideLine: String? {
        guard phoneOnItsSide(verticalSize) else { return nil }
        return session.cards.first { $0.minimized && session.takenBack[$0.id] != nil }.flatMap { session.takenBack[$0.id] }
    }

    /// INF-2928 piece 3: on an iPhone on its side, which shows no change pill, why a move from a row was refused or
    /// taken back is said on this list's line.
    private var sideNotice: String? {
        guard phoneOnItsSide(verticalSize), let notice = session.changeNotice, notice.place == nil else { return nil }
        return notice.words
    }

    /// The pills: one per project that has tasks, in the board's own order.
    private func projectsWithTasks(_ list: PhoneTaskList) -> [PhoneBoard.Project] {
        let used = Set((list.board?.tasks ?? []).map(\.projectId))
        return (list.board?.projects ?? []).filter { used.contains($0.id) }
    }

    /// The project pill narrows the board and the list to one project's tasks.
    private func inProject(_ task: PhoneTask) -> Bool { project == nil || task.projectId == project }

    var body: some View {
        let reading = reading()
        return GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            let list = reading.list.filtered(keep: inProject, aside: project == nil)
            VStack(spacing: 0) {
                PhoneTaskControls(showBoard: $showBoard, project: $project, projects: projectsWithTasks(reading.list), wide: landscape)
                    .frame(maxWidth: showBoard && landscape ? .infinity : PhoneColumn.width).frame(maxWidth: .infinity)
                if showBoard && !searchShown {
                    // INF-2553's refusal line, which the list shows, also sits above the board.
                    if let problem = problem ?? reading.asideLine ?? sideNotice {
                        Text(problem).foregroundStyle(PhoneTheme.warning).padding(.horizontal, PhoneTheme.space4).accessibilityIdentifier("tasks-problem")
                    }
                    if list.isEmpty { Text("No tasks yet.").foregroundStyle(PhoneTheme.secondary).padding(PhoneTheme.space4) }
                    PhoneTaskBoard(board: list.board, tasks: list.parts.flatMap { $0.rows.map(\.task) },
                                   aside: list.parts.flatMap(\.aside),
                                   landscape: landscape, width: geometry.size.width, column: $boardColumn,
                                   open: open, restore: { restore([$0]) }, canRestore: session.canChange)
                } else { listView(reading, list) }
            }
        }
        .background { Button("Find a task") { openSearch() }.keyboardShortcut("f", modifiers: [.command, .shift]).hidden() }
        .accessibilityIdentifier("tasks-list")
        .onChange(of: searchFocused) { _, focused in if !focused && query.isEmpty { closeSearch() } }
        .onDisappear { if query.isEmpty { searchOpen = false } }
        .task(id: "\(query)|\(session.contact)") {
            earlier = []; problem = nil
            let requested = query
            guard !requested.isEmpty, session.contact == "in-reach" else { return }
            guard requested.utf16.count <= 200 else { problem = "Use a shorter search."; return }
            do {
                let found: [PhoneTask] = try await session.request(.search, args: [requested])
                guard !Task.isCancelled, query == requested else { return }
                earlier = found
            } catch { if !Task.isCancelled { problem = error.localizedDescription } }
        }
        // INF-1524: a task key pressed on a card opens that task's record here.
        .onChange(of: messageContext.openTask, initial: true) { _, key in
            guard let key, let task = session.board?.tasks.first(where: { $0.key == key }) else { return }
            messageContext.openTask = nil
            messageContext.taskID = task.id; selected = task
        }
        // The Mac's ask on the tile: its sentence, Cancel, which writes nothing, and the move's own button.
        .alert(asking?.sentence ?? "", isPresented: Binding(get: { asking != nil }, set: { if !$0 { asking = nil } }),
               presenting: asking) { ask in
            Button(PhoneRecordWords.dropCancel, role: .cancel) {}
            Button(ask.confirm, role: ask.op == "drop-task" || ask.op == "stop-task" ? .destructive : nil) { confirm(ask) }
        }
        .sheet(item: $selected, onDismiss: { messageContext.taskID = nil }) { task in
            NavigationStack {
                PhoneTaskRecord(session: session, initial: task, leave: { selected = nil })
                    .toolbar { ToolbarItem(placement: .cancellationAction) { PhoneRecordLeaveButton(record: $selected) } }
            }.font(PhoneFont.body).tint(PhoneTheme.accent)
        }
    }

    private func listView(_ reading: PhoneTasksKept.Reading, _ list: PhoneTaskList) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PhoneTheme.space3) {
                if searchShown { search }
                if let problem = problem ?? reading.asideLine ?? sideNotice { Text(problem).foregroundStyle(PhoneTheme.warning).accessibilityIdentifier("tasks-problem") }
                LazyVStack(alignment: .leading, spacing: PhoneTheme.space2) {
                    if list.isEmpty { Text(query.isEmpty ? "No tasks yet." : "No matching tasks.").foregroundStyle(PhoneTheme.secondary) }
                    // INF-2928 piece 1: only the groups with rows show, as on the Mac, and a search opens every one.
                    ForEach(list.parts) { part in
                        let open = !part.section.folds || searching || expanded.contains(part.section)
                        VStack(spacing: 0) {
                            groupHeader(part, open: open)
                            if open {
                                ForEach(part.rows) { row in
                                    taskRow(row, in: part, list: list, last: part.aside.isEmpty && row.id == part.rows.last?.id)
                                }
                                // A card put aside with no task is a row of its own under Waiting on you.
                                ForEach(part.aside) { card in asideRow(card, last: card.id == part.aside.last?.id) }
                            }
                        }
                    }
                }.onGeometryChange(for: CGFloat.self) { $0.size.width } action: { columnWidth = $0 }
            }.frame(maxWidth: .infinity, alignment: .leading)
                // The reading column the list sits in, for the journeys to find Tasks by when no group has rows.
                .accessibilityElement(children: .contain).accessibilityIdentifier("tasks-column")
                .padding(PhoneTheme.space4).frame(maxWidth: PhoneColumn.width).frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.always, axes: .vertical)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top < -PhoneTheme.space5 * 2
        } action: { _, pulled in
            if pulled && !searchOpen { withAnimation(.snappy) { searchOpen = true } }
        }
    }

    private var search: some View {
        HStack(spacing: PhoneTheme.space2) {
            TextField("Search tasks", text: $query).textFieldStyle(.phone)
                .focused($searchFocused).submitLabel(.search)
                .onAppear {
                    guard focusOnOpen else { return }
                    focusOnOpen = false
                    Task { @MainActor in searchFocused = true }
                }
                .onKeyPress(.escape) {
                    if query.isEmpty { closeSearch() } else { query = "" }
                    return .handled
                }
                .accessibilityIdentifier("task-search")
            if !voiceOver {
                Button { closeSearch() } label: {
                    Image(systemName: "xmark").font(PhoneFont.callout).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).foregroundStyle(PhoneTheme.muted)
                    .accessibilityLabel("Close search").accessibilityIdentifier("close-task-search")
            }
        }.transition(.move(edge: .top).combined(with: .opacity))
    }

    // Find a task (Shift-Command-F), the Mac's own key, opens the search with the caret in it.
    private func openSearch() {
        if searchShown { searchFocused = true; return }
        focusOnOpen = true
        withAnimation(.snappy) { searchOpen = true }
    }

    // Closing lets go of the words, so a closed search never narrows the list, as on the Mac.
    private func closeSearch() {
        query = ""; searchFocused = false
        withAnimation(.snappy) { searchOpen = false }
    }

    // The Mac's micro label: uppercase, tracked, tertiary. Only a folding group is a button, and only it shows its count,
    // with Backlog's new filings and failed starts after it (the Mac's `Group`).
    @ViewBuilder private func groupHeader(_ part: PhoneTaskList.Part, open: Bool) -> some View {
        let title = Text(part.section.title).font(Self.label).textCase(.uppercase).tracking(Self.labelTracking)
        if part.section.folds {
            Button {
                if !expanded.insert(part.section).inserted { expanded.remove(part.section) }
            } label: {
                HStack(spacing: PhoneTheme.space2) {
                    title
                    Text("\(part.count)\(part.section == .group(.backlog) && part.failed > 0 ? PhoneTaskRowWords.failedCount(part.failed) : "")\(part.new > 0 ? PhoneTaskRowWords.newCount(part.new) : "")")
                        .font(PhoneFont.micro).lineLimit(1)
                    Spacer()
                    Image(systemName: open ? "chevron.down" : "chevron.right")
                        .font(PhoneFont.micro).foregroundStyle(PhoneTheme.secondary).accessibilityHidden(true)
                }.foregroundStyle(PhoneTheme.muted).frame(minHeight: 44)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityIdentifier("group-\(part.id)")
                .accessibilityLabel("\(part.section.title), \(part.count)")
                .accessibilityValue(open ? "Expanded" : "Collapsed")
        } else {
            title.foregroundStyle(PhoneTheme.muted).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .accessibilityAddTraits(.isHeader).accessibilityIdentifier("group-\(part.id)")
        }
    }

    /// The Mac's row: its status mark, the key and title with the one dim word after them, then the project's name where
    /// more than one project could be meant, where the task runs and why that computer cannot take work now. A part sits
    /// indented under its parent, and a Queued row adds the home's dated wait line below.
    private func taskRow(_ row: PhoneTaskList.Row, in part: PhoneTaskList.Part, list: PhoneTaskList, last: Bool) -> some View {
        let task = row.task
        let status = PhoneTaskFacts.status(task)
        let word = PhoneTaskList.word(task)
        let trailing = list.trailing(of: task)
        let wait = part.waitLine(of: task)
        var title = Text("\(task.key) ").font(PhoneFont.mono).foregroundStyle(PhoneTheme.muted)
            + Text(task.title).font(PhoneFont.body)
            .foregroundStyle(part.section == .group(.waiting) ? PhoneTheme.text : PhoneTheme.secondary)
        if !word.isEmpty {
            title = title + Text(" · \(word)").font(PhoneFont.body)
                .foregroundStyle(word == PhoneTaskRowWords.couldNotStart ? PhoneTheme.warning : PhoneTheme.muted)
        }
        let ends = [trailing.name, trailing.place].filter { !$0.isEmpty }.joined(separator: " · ")
        var end = Text(ends)
        if trailing.outOfReach {
            end = end + Text("\(ends.isEmpty ? "" : " · ")\(trailing.reach)")
                .foregroundStyle(trailing.connecting ? PhoneTheme.muted : PhoneTheme.warning)
        }
        // INF-2928 piece 3: a Backlog row's Start, which a swipe shows, says why under the row when it cannot start.
        // A pinned backlog task keeps it, as on the Mac (INF-3127).
        let start = part.home(of: task) == .backlog ? PhoneRowMoves.rowStart(task) : nil
        let held = swiped == task.id ? start?.reason : nil
        let lane: PhoneRowMoves.Lane? = part.section == .earlier ? .earlier : PhoneRowMoves.lane(task)
        let line = Button {
            // A row held open on its Start closes first, as a swiped row does.
            if swiped != nil { withAnimation(.snappy) { swiped = nil }; return }
            open(task)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space3) {
                PhoneTaskMark(status: status).alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
                    .frame(width: Self.markWidth)
                VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                    HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space2) {
                        title.lineLimit(titleLines).layoutPriority(1)
                        Spacer(minLength: PhoneTheme.space2)
                        if !ends.isEmpty || trailing.outOfReach {
                            end.font(PhoneFont.mono).foregroundStyle(PhoneTheme.muted).lineLimit(1)
                        }
                    }
                    if let wait {
                        Text(wait).font(PhoneFont.mono).foregroundStyle(PhoneTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }.padding(.leading, CGFloat(row.depth) * Self.markWidth)
                .padding(.vertical, PhoneTheme.space3).frame(minHeight: 44)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("task-\(task.id)")
            .accessibilityLabel([task.key, task.title, word.isEmpty ? nil : word, ends.isEmpty ? nil : ends,
                                 trailing.outOfReach ? trailing.reach : nil, status.label].compactMap(\.self).joined(separator: ", "))
            // A long press stands in for resting the pointer on the Mac's row: the crew summary, with the row's moves
            // under it.
            .contextMenu { moves(task, lane: lane) } preview: {
                PhoneRowPreview(width: min(max(columnWidth, 280), PhoneCrewSummary.hoverWidth)) {
                    PhoneCrewSummary(session: session, task: task, tasks: list.board?.tasks ?? [], preview: true)
                }.font(PhoneFont.body).tint(PhoneTheme.accent)
            }
        let inset = Self.markWidth + PhoneTheme.space3 + CGFloat(row.depth) * Self.markWidth
        return VStack(alignment: .leading, spacing: 0) {
            swipeable(line, task: task, start: start)
            if let held {
                Text(held).font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true).padding(.leading, inset).padding(.bottom, PhoneTheme.space3)
                    .accessibilityIdentifier("row-start-reason")
            }
        }
        .overlay(alignment: .bottom) {
            // Inset to the words, never under the mark, and none after a group's last row.
            if !last {
                Rectangle().fill(PhoneTheme.line).frame(height: 1).padding(.leading, inset)
            }
        }
    }

    /// INF-2928 piece 1: a tap makes the Mac's four checks in order (`openTask`). A row whose task has cards put aside
    /// brings them back and shows them on Home, on the phone and every Mac (INF-1517); a ready card on the stack shows on
    /// Home, except a first mate question's, whose row opens its record; a required step the captain put off shows its
    /// card again; any other row opens the task's record.
    private func open(_ task: PhoneTask) {
        let aside = PhoneBoard.minimized(of: task, in: session.cards)
        if !aside.isEmpty { restore(aside); return }
        if let card = task.waitingCardId, let shown = session.stack.first(where: { $0.id == card }) {
            // The captain's pick: a first mate question's card shows no task key and the phone's cards have no Info
            // tab, so its row opens the record, where Dismiss is, until the phone matches the Mac.
            if task.kind == "decision" && shown.isFirstmateOwn { openRecord(task); return }
            messageContext.restoring = card; return
        }
        if task.status == "open", let state = task.requiredAction?.state, state == "ready" || state == "deferred",
           session.canChange {
            showCard(task); return
        }
        openRecord(task)
    }

    private func openRecord(_ task: PhoneTask) { messageContext.taskID = task.id; selected = task }

    /// INF-2928 piece 3: the long press's moves, the Mac's task board menu for this row (`boardMenuOf`): each entry names
    /// what it does, or the Mac's reason it cannot run, dim. A row the board has no menu for, Done and Dropped among
    /// them, still opens its record here.
    @ViewBuilder private func moves(_ task: PhoneTask, lane: PhoneRowMoves.Lane?) -> some View {
        let items = lane.map { PhoneRowMoves.menu(task, lane: $0) } ?? []
        if items.isEmpty {
            Button(PhoneRowMoves.openLabel) { openRecord(task) }
        }
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
            switch item {
            case .separator: Divider()
            case .entry(let entry):
                Button(role: entry.danger ? .destructive : nil) { act(entry, task: task, lane: lane) } label: {
                    Text(entry.label)
                    if let detail = entry.detail { Text(detail) }
                }
                .disabled(entry.disabled || (!session.canChange && entry.id != .open && entry.id != .card))
            }
        }
    }

    /// One entry, as the Mac's board runs it: Open record, Show the card by the row's own four checks, Continue at once,
    /// and every other entry as the move to its lane or to Drop task.
    private func act(_ entry: PhoneRowMoves.Entry, task: PhoneTask, lane: PhoneRowMoves.Lane?) {
        switch entry.id {
        case .open: openRecord(task)
        case .card: open(task)
        case .pin: pin(task)
        case .continue: start(task, move: "continue-task")
        default:
            guard let lane, let target = entry.target else { return }
            perform(task, from: lane, to: target)
        }
    }

    /// The Mac's move (`boardMoveOf`): a refusal says why and writes nothing, an at-once move runs, and a move that asks
    /// asks once; a never-started Drop task asks in its record's words, from the effects the record lists now.
    private func perform(_ task: PhoneTask, from lane: PhoneRowMoves.Lane, to target: PhoneRowMoves.Target) {
        switch PhoneRowMoves.move(task, from: lane, to: target) {
        case .none(let why), .refused(let why): say(why)
        case .now(let op, _, _): run(task, args: [task.id, op])
        case .card(let card, _): messageContext.restoring = card
        case .ask(let op, let sentence, let confirm):
            guard op == "drop-task" else {
                asking = RowAsk(task: task, op: op, sentence: sentence, confirm: confirm, review: nil); return
            }
            Task {
                let effects = try? await session.readDetail(task.id).dropEffects
                switch PhoneRowMoves.dropAsk(task.key, effects: effects) {
                case .refused(let why): say(why)
                case .ask(let sentence, let review):
                    asking = RowAsk(task: task, op: op, sentence: sentence, confirm: confirm, review: review)
                }
            }
        }
    }

    /// The ask's own button: Start through the start the record draws at the tap, any other move as the Mac sends it,
    /// with the review Drop task asked about.
    private func confirm(_ ask: RowAsk) {
        if ask.op == "start-task" { start(ask.task, move: ask.op); return }
        var args: [Any] = [ask.task.id, ask.op]
        if let review = ask.review { args.append(review) }
        run(ask.task, args: args)
    }

    /// INF-3127: Pin or Unpin, at once, as the Mac's board menu does; the row moves once the computer's board does, and a
    /// refusal says why.
    private func pin(_ task: PhoneTask) {
        guard session.canChange else { return }
        Task {
            do {
                let answer: PhoneAnswer = try await session.request(.pin, args: [task.id, task.pinnedAt == nil])
                if !answer.ok { say(answer.text ?? "Your computer could not make this change.") }
            } catch { say(error.localizedDescription) }
        }
    }

    /// A move the phone draws no intent for: the list moves the row once the computer's board does, and a refusal says why.
    private func run(_ task: PhoneTask, args: [Any]) {
        guard session.canChange else { return }
        Task {
            do {
                let answer: PhoneAnswer = try await session.request(.run, args: args)
                if !answer.ok { say(answer.text ?? "Your computer could not make this change.") }
            } catch { say(error.localizedDescription) }
        }
    }

    /// Start and Continue show the task starting at the tap; the session takes a refused one back and says why.
    private func start(_ task: PhoneTask, move: String) {
        guard session.canChange else { return }
        Task { try? await session.change(.start(task: task.id, move: move), .run, args: [task.id, move]) }
    }

    private func say(_ why: String) { session.changeNotice = PhoneChangeNotice(words: why) }

    /// A Backlog row's Start sits under its trailing edge: a swipe toward the leading edge shows it, as the Mac shows it on
    /// the row, and holds the row open on it; a tap on the row closes it. One press starts the task with no ask, as on
    /// the Mac.
    @ViewBuilder private func swipeable(_ line: some View, task: PhoneTask, start: PhoneRowMoves.Start?) -> some View {
        if let start {
            let held: CGFloat = swiped == task.id ? -Self.startWidth : 0
            let x = swiping.flatMap { $0.id == task.id ? $0.x : nil } ?? held
            line.offset(x: x)
                .background(alignment: .trailing) {
                    if x < 0 {
                        Button {
                            withAnimation(.snappy) { swiped = nil }
                            self.start(task, move: "start-task")
                        } label: {
                            Text(start.label).font(PhoneFont.body).lineLimit(1).fixedSize()
                                .foregroundStyle(start.reason == nil ? PhoneTheme.onAccent : PhoneTheme.muted)
                                .frame(width: -x).frame(maxHeight: .infinity)
                                .background(start.reason == nil ? PhoneTheme.accent : PhoneTheme.surface)
                                .clipped()
                        }.buttonStyle(.plain).disabled(start.reason != nil || !session.canChange)
                            .accessibilityIdentifier("row-start-\(task.id)")
                    }
                }
                .clipped()
                .gesture(PhoneRowSwipe { dx in
                    if swiped != nil && swiped != task.id { swiped = nil }
                    swiping = (task.id, min(0, max(held + dx, -Self.startWidth - PhoneTheme.space5)))
                } ended: { dx, speed in
                    let x = held + dx
                    let open = speed < -300 || (x < -Self.startWidth / 2 && speed <= 300)
                    withAnimation(.snappy) {
                        swiping = nil
                        swiped = open ? task.id : nil
                    }
                })
        } else {
            line
        }
    }

    /// The record's Show the card, through the one move the Mac runs it by: once the computer shows the card again, Home
    /// shows it as soon as the stack holds it; a refusal or a lost answer opens the record instead, as on the Mac.
    private func showCard(_ task: PhoneTask) {
        problem = nil
        Task {
            do {
                let answer: PhoneAnswer = try await session.request(.run, args: [task.id, "show-card"])
                if answer.ok, let card = try await session.readDetail(task.id).waitingCardId {
                    messageContext.restoring = card; return
                }
            } catch {}
            openRecord(task)
        }
    }

    /// INF-2553: the cards are back on Home at the tap, the first one up; one request per card, sent together, each
    /// settling on its own.
    /// A refusal puts that card aside again and the session says why.
    private func restore(_ cards: [PhoneCard]) {
        guard let first = cards.first, session.canChange else { return }
        problem = nil
        for card in cards {
            Task { try? await session.change(.bringBack(card: card.id), .minimize, [.string(card.id), .bool(false)]) }
        }
        messageContext.restoring = first.id
    }

    // A card put aside with no task: the Mac's presentation-only row, titled by the card, with no key or project.
    private func asideRow(_ card: PhoneCard, last: Bool) -> some View {
        Button { restore([card]) } label: {
            HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space3) {
                Image(systemName: "circle.fill").font(.system(size: PhoneTheme.space2)).foregroundStyle(PhoneTheme.accent)
                    .frame(width: Self.markWidth).accessibilityHidden(true)
                Text(card.title).font(PhoneFont.body).foregroundStyle(PhoneTheme.text).lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.padding(.vertical, PhoneTheme.space3).frame(minHeight: 44)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(!session.canChange).accessibilityIdentifier("minimized-card")
            .accessibilityLabel(card.title).accessibilityHint("Brings the card back")
        .overlay(alignment: .bottom) {
            if !last { Rectangle().fill(PhoneTheme.line).frame(height: 1).padding(.leading, Self.markWidth + PhoneTheme.space3) }
        }
    }

    private static let markWidth: CGFloat = 12
    /// How wide a Backlog row's Start shows once a swipe holds it open: room for Try again.
    private static let startWidth: CGFloat = 104
    private static let label = Font.custom("SpaceGrotesk-Light", size: 11, relativeTo: .caption2).weight(.medium)
    private static let labelTracking: CGFloat = 1

    /// A move from a row's long press that asks once: the Mac's sentence, its button, and Drop task's review.
    struct RowAsk: Identifiable {
        let id = UUID()
        let task: PhoneTask
        let op: String
        let sentence: String
        let confirm: String
        let review: [String: [String]]?
    }
}

/// A long press's summary at its own width. The system asks the preview for that size, but an iPad may give it less
/// room beside the menu; the summary then shrinks whole instead of losing its edges.
private struct PhoneRowPreview<Content: View>: View {
    let width: CGFloat
    @ViewBuilder let content: Content
    @State private var natural: CGSize = .zero
    @State private var given: CGSize = .zero

    var body: some View {
        let scale = natural.width > 0 && natural.height > 0 && given.width > 0
            ? min(1, given.width / natural.width, given.height / natural.height) : 1
        content.frame(width: width).background(PhoneTheme.panel)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { natural = $0 }
            .scaleEffect(scale)
            // Never larger than the summary, and as small as the room the system gives it.
            .frame(minWidth: 0, minHeight: 0)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { given = $0 }
            .background(PhoneTheme.panel)
    }
}

/// A sideways swipe on a row, which leaves an upward or downward one to the list's scrolling: how far it has moved, then
/// where it ended and how fast.
private struct PhoneRowSwipe: UIGestureRecognizerRepresentable {
    let moved: (CGFloat) -> Void
    let ended: (CGFloat, CGFloat) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let dx = recognizer.translation(in: nil).x
        switch recognizer.state {
        case .changed: moved(dx)
        case .ended, .cancelled: ended(dx, recognizer.velocity(in: nil).x)
        default: break
        }
    }

    @MainActor final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return false }
            let speed = pan.velocity(in: nil)
            return abs(speed.x) > abs(speed.y)
        }
    }
}

/// INF-2764: the Tasks list's last reading, in a plain class so keeping it draws nothing.
@MainActor final class PhoneTasksKept {
    struct Reading {
        let list: PhoneTaskList
        let asideLine: String?
    }
    var last: Reading?

    /// For the app-hosted check that a hidden list builds nothing on a board update (`PhoneTasksHiddenTests`): how
    /// many lists were built while hidden, and the board a shown list was last built from.
    private(set) static var hiddenBuilds = 0
    private(set) static var shownSeq: Int?
    static func built(shown: Bool, seq: Int?) { if shown { shownSeq = seq } else { hiddenBuilds += 1 } }
}

extension EnvironmentValues {
    /// Whether the Tasks list is the view on screen; the workspace sets it on the Tasks tab, and the iPad sidebar's
    /// list, drawn only while it shows, keeps the default.
    @Entry var phoneTasksShown = true
}
