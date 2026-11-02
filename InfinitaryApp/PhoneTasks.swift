import InfinitaryKit
import SwiftUI

struct PhoneTasks: View {
    let session: ReadOnlySession
    @Environment(PhoneMessageContext.self) private var messageContext
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var query = ""
    @State private var searchOpen = false
    @State private var focusOnOpen = false
    @FocusState private var searchFocused: Bool
    @State private var earlier: [PhoneTask] = []
    @State private var problem: String?
    @State private var selected: PhoneTask?
    @State private var expanded: Set<PhoneTaskGroup> = [.waiting, .working, .queued]
    // Board/List opens on Board, then remembers the last view; the project pill filters both.
    @AppStorage("phone.tasksBoard") private var showBoard = true
    @State private var project: String?
    @State private var boardColumn: PhoneTaskGroup? = .waiting

    /// INF-1517: the board as the Mac's Tasks presents it, with each card put aside under Waiting on you.
    private var board: PhoneBoard? { session.board?.presenting(session.cards) }

    private var rows: [PhoneTask] {
        let current = (board?.tasks ?? []).filter { project == nil || $0.projectId == project }.filter {
            query.isEmpty || "\($0.key) \($0.title) \($0.goal ?? "")".localizedCaseInsensitiveContains(query)
        }
        let ids = Set(current.map(\.id))
        return (current + earlier.filter { !ids.contains($0.id) }).sorted {
            let leftLive = $0.status == "open" || $0.status == "active"
            let rightLive = $1.status == "open" || $1.status == "active"
            if leftLive != rightLive { return leftLive }
            return $0.createdAt > $1.createdAt
        }
    }

    // INF-589 item 9: search waits above the list until it is pulled down, as the Mac's sits behind its icon.
    // VoiceOver cannot pull past the top of a list, so it always finds the field.
    private var searchShown: Bool { searchOpen || !query.isEmpty || voiceOver }

    /// The pills: one per project that has tasks, in the board's own order.
    private var projectsWithTasks: [PhoneBoard.Project] {
        let used = Set((board?.tasks ?? []).map(\.projectId))
        return (board?.projects ?? []).filter { used.contains($0.id) }
    }

    var body: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            VStack(spacing: 0) {
                PhoneTaskControls(showBoard: $showBoard, project: $project, projects: projectsWithTasks, wide: landscape)
                    .frame(maxWidth: showBoard && landscape ? .infinity : PhoneColumn.width).frame(maxWidth: .infinity)
                if showBoard && !searchShown {
                    if rows.isEmpty && (board?.tasklessMinimized(session.cards).isEmpty ?? true) {
                        Text("No tasks yet.").foregroundStyle(PhoneTheme.secondary).padding(PhoneTheme.space4)
                    }
                    PhoneTaskBoard(board: board, tasks: rows, aside: project == nil ? board?.tasklessMinimized(session.cards) ?? [] : [],
                                   landscape: landscape, width: geometry.size.width, column: $boardColumn,
                                   open: open, restore: { restore([$0]) }, canRestore: session.canChange)
                } else { list }
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
        .sheet(item: $selected, onDismiss: { messageContext.taskID = nil }) { task in
            NavigationStack {
                PhoneTaskRecord(session: session, initial: task)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { selected = nil }.accessibilityIdentifier("close-record") } }
            }.font(PhoneFont.body).tint(PhoneTheme.accent)
        }
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PhoneTheme.space3) {
                if searchShown { search }
                if let problem { Text(problem).foregroundStyle(PhoneTheme.warning) }
                LazyVStack(alignment: .leading, spacing: PhoneTheme.space2) {
                    if rows.isEmpty && (board?.tasklessMinimized(session.cards).isEmpty ?? true) { Text(query.isEmpty ? "No tasks yet." : "No matching tasks.").foregroundStyle(PhoneTheme.secondary) }
                    if query.isEmpty {
                        let groups = board?.groups ?? [:]
                        ForEach(PhoneTaskGroup.allCases, id: \.rawValue) { group in
                            let members = rows.filter { groups[$0.id] == group }
                            // A card put aside with no task is a row of its own under Waiting on you.
                            let aside = group == .waiting && project == nil ? board?.tasklessMinimized(session.cards) ?? [] : []
                            VStack(spacing: 0) {
                                groupHeader(group, count: members.count + aside.count)
                                if expanded.contains(group) {
                                    ForEach(members) { task in taskRow(task, last: aside.isEmpty && task.id == members.last?.id) }
                                    ForEach(aside) { card in asideRow(card, last: card.id == aside.last?.id) }
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 0) {
                            ForEach(rows) { task in taskRow(task, last: task.id == rows.last?.id) }
                        }
                    }
                }
            }.padding(PhoneTheme.space4).frame(maxWidth: PhoneColumn.width).frame(maxWidth: .infinity)
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

    // The Mac's micro label: uppercase, tracked, tertiary, with the count in mono.
    private func groupHeader(_ group: PhoneTaskGroup, count: Int) -> some View {
        Button {
            if !expanded.insert(group).inserted { expanded.remove(group) }
        } label: {
            HStack(spacing: PhoneTheme.space2) {
                Text(group.title).font(Self.label).textCase(.uppercase).tracking(Self.labelTracking)
                Text("\(count)").font(PhoneFont.micro)
                Spacer()
                Image(systemName: expanded.contains(group) ? "chevron.down" : "chevron.right")
                    .font(PhoneFont.micro).foregroundStyle(PhoneTheme.secondary).accessibilityHidden(true)
            }.foregroundStyle(PhoneTheme.muted).frame(minHeight: 44)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("group-\(group.rawValue)")
            .accessibilityLabel("\(group.title), \(count)")
            .accessibilityValue(expanded.contains(group) ? "Expanded" : "Collapsed")
    }

    // The title row stays as on the Mac; an unstarted task adds the home’s full dated wait below it.
    private func taskRow(_ task: PhoneTask, last: Bool) -> some View {
        let project = board?.projects.first(where: { $0.id == task.projectId })?.name
        return Button { open(task) } label: {
            HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space3) {
                Image(systemName: task.status == "open" && task.waitingCardId == nil && task.minimizedCardId == nil ? "circle" : "circle.fill")
                    .font(.system(size: PhoneTheme.space2)).foregroundStyle(task.waitingCardId != nil || task.minimizedCardId != nil ? PhoneTheme.accent : task.activity == "running" ? PhoneTheme.warning : PhoneTheme.secondary)
                    .frame(width: Self.markWidth).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                    HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space2) {
                        Text(task.key).font(PhoneFont.mono).foregroundStyle(PhoneTheme.muted).fixedSize()
                        Text(task.title).font(PhoneFont.body).foregroundStyle(PhoneTheme.text).lineLimit(1)
                        Spacer(minLength: PhoneTheme.space2)
                        if let project { Text(project).font(PhoneFont.mono).foregroundStyle(PhoneTheme.muted).lineLimit(1) }
                    }
                    if let wait = task.queueWait {
                        Text(wait.line).font(PhoneFont.mono).foregroundStyle(PhoneTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }.padding(.vertical, PhoneTheme.space3).frame(minHeight: 44)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("task-\(task.id)")
            .accessibilityLabel([task.key, task.title, project, task.state].compactMap(\.self).joined(separator: ", "))
        .overlay(alignment: .bottom) {
            // Inset to the words, never under the mark, and none after a group's last row.
            if !last { Rectangle().fill(PhoneTheme.line).frame(height: 1).padding(.leading, Self.markWidth + PhoneTheme.space3) }
        }
    }

    /// INF-1517, the captain's pick: a row whose task has cards put aside brings them back and shows them on Home,
    /// on the phone and every Mac, as a Mac Tasks row does (`openTask`); any other row opens the task's record.
    private func open(_ task: PhoneTask) {
        let aside = PhoneBoard.minimized(of: task, in: session.cards)
        if aside.isEmpty { messageContext.taskID = task.id; selected = task } else { restore(aside) }
    }

    private func restore(_ cards: [PhoneCard]) {
        guard let first = cards.first, session.canChange else { return }
        problem = nil
        Task {
            do { for card in cards { _ = try await session.ask(.minimize, [.string(card.id), .bool(false)]) } }
            catch { problem = error.localizedDescription; return }
            messageContext.restoring = first.id
        }
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
    private static let label = Font.custom("SpaceGrotesk-Light", size: 11, relativeTo: .caption2).weight(.medium)
    private static let labelTracking: CGFloat = 1
}

struct PhoneTaskRecord: View {
    let session: ReadOnlySession
    let initial: PhoneTask
    @State private var detail: PhoneTask?
    @State private var crew: PhoneCrew?
    @State private var live: PhoneCrewLive?
    @State private var showingCrew = false
    @State private var draft = ""
    @State private var busy = false
    @State private var pressed: String?
    @State private var problem: String?
    @State private var readProblem: String?
    @State private var sent = 0
    @ScaledMetric(relativeTo: .caption) private var markLift: CGFloat = 4
    private var task: PhoneTask { detail ?? initial }
    private var steerable: Bool { showingCrew && task.canSteer }
    private var canStart: Bool { task.moves?["start-task"]?.ok == true }
    private var canContinue: Bool { task.moves?["continue-task"]?.ok == true }
    private var canInterrupt: Bool { steerable && live?.since != nil }
    private var hasActions: Bool {
        (task.status == "open" || task.status == "active") && (steerable || canStart || canContinue)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                // INF-1351: the lazy stack is the scroll view's own content. Nested in a plain stack, its placement and
                // prefetch never settled after a steer, and the main thread stayed busy until the app was stopped.
                LazyVStack(alignment: .leading, spacing: PhoneTheme.space4) {
                    // The record's title is the task's own; its key stays in mono on the line below for whoever looks for it.
                    Text(task.title).font(PhoneFont.title).accessibilityAddTraits(.isHeader).accessibilityIdentifier("task-record-title")
                    Text("\(task.key) · \(task.state) · \(session.mac.name)").font(PhoneFont.mono)
                    if let wait = task.queueWait {
                        Text(wait.line).font(PhoneFont.mono).foregroundStyle(PhoneTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let place = task.place { Text(place.where).foregroundStyle(PhoneTheme.secondary) }
                    // INF-589 item 11: the reach line says out of reach; this one says only that changes are off.
                    if let words = session.changesOffLine { Text(words).font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary) }
                    if let readProblem { Text(readProblem).foregroundStyle(PhoneTheme.warning) }
                    if task.startedAt != nil {
                        Picker("Record", selection: $showingCrew) {
                            Text("Info").tag(false)
                            Text("Crewmate").tag(true)
                        }.pickerStyle(.segmented).accessibilityIdentifier("record-tabs")
                    }
                    if showingCrew { crewContent } else { infoContent }
                }.padding().frame(maxWidth: 750).frame(maxWidth: .infinity)
            }
            if hasActions || problem != nil { foot }
        }.background(PhoneTheme.background).navigationBarTitleDisplayMode(.inline)
            // INF-589 item 12: a soft tap once the computer accepts a start, continue, interrupt or steer.
            .sensoryFeedback(.phone, trigger: sent)
            .task(id: "\(session.contact)|\(showingCrew)") {
                guard session.contact == "in-reach" else { return }
                // Only the open record polls; the board follows pushes. Transcript writes may follow their event.
                while !Task.isCancelled {
                    await refresh()
                    do { try await Task.sleep(for: .seconds(1)) } catch { return }
                }
            }
    }

    private var infoContent: some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space4) {
            if let goal = task.goal { section("Goal", goal) }
            if let words = task.intent?.userWords, !words.isEmpty { section("Your words", words) }
            if let plan = task.plan {
                Text("Progress").font(PhoneFont.headline)
                ForEach(Array(plan.items.enumerated()), id: \.offset) { _, item in
                    Label(item.label, systemImage: item.state == "done" ? "checkmark.circle" : item.state == "current" ? "circle.inset.filled" : "circle")
                }
            }
            if let outcome = task.outcome { section("Latest report", outcome) }
            if let problem = task.problem { section("What happened", problem) }
            if !task.blockedBy.isEmpty { section("Waiting for", task.blockedBy.joined(separator: ", ")) }
            if let model = task.modelLabel { section("Crewmate", "\(task.assignee ?? "Crewmate") · \(model)") }
            Text("Timeline").font(PhoneFont.headline)
            timeline
        }
    }

    // INF-589 item 14: each event on a hairline rail, its words at caption size and its time at the right.
    private var timeline: some View {
        TimelineView(.periodic(from: .now, by: 60)) { clock in
            VStack(alignment: .leading, spacing: PhoneTheme.space3) {
                ForEach(task.events ?? []) { event in
                    let at = Date(timeIntervalSince1970: event.at / 1000)
                    HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space3) {
                        Circle().fill(PhoneTheme.muted).frame(width: Self.mark, height: Self.mark)
                            .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + markLift }
                            .accessibilityHidden(true)
                        Text(event.text).font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
                            .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                        Text(Self.time(at, now: clock.date)).font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted)
                            .fixedSize().accessibilityLabel(at.formatted(date: .abbreviated, time: .shortened))
                    }.accessibilityElement(children: .combine).accessibilityIdentifier("task-event-\(event.kind)")
                }
            }
            .background(alignment: .leading) {
                Rectangle().fill(PhoneTheme.line).frame(width: 1).padding(.leading, (Self.mark - 1) / 2)
                    .padding(.vertical, PhoneTheme.space2).accessibilityHidden(true)
            }
        }
    }

    private static let mark: CGFloat = 5

    /// Today's events show only their time; an earlier day adds its date, never the year of every line.
    static func time(_ at: Date, now: Date) -> String {
        Calendar.current.isDate(at, inSameDayAs: now)
            ? at.formatted(date: .omitted, time: .shortened)
            : at.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }

    /// The transcript's rows sit straight in the record's lazy stack, so only the lines on screen are laid out.
    @ViewBuilder private var crewContent: some View {
        if let crew {
            if crew.earlier > 0 { Text("\(crew.earlier) earlier entries are not shown.").font(PhoneFont.caption) }
            if crew.lines.isEmpty { Text("Nothing from the crewmate yet.").foregroundStyle(PhoneTheme.secondary) }
            ForEach(crew.lines) { line in
                VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                    if line.kind == "sent" { Text(line.from == "captain" ? "You" : line.from == "firstmate" ? "Your first mate" : "Infinitary").font(PhoneFont.caption) }
                    if let name = line.name { Text("\(name) · \(line.target ?? "")").font(PhoneFont.mono) }
                    if line.kind == "brief" || line.kind == "report" {
                        DisclosureGroup(line.summary ?? (line.kind == "brief" ? "The brief" : "Report")) { Text(line.words).textSelection(.enabled) }
                    } else { Text(line.words).textSelection(.enabled) }
                    if let result = line.result { CrewResult(session: session, taskID: task.id, result: result) }
                }.accessibilityIdentifier("crew-line-\(line.kind)")
            }
        }
        if let text = live?.text, !text.isEmpty { Text(text).accessibilityIdentifier("crew-live") }
    }

    // INF-589 item 10: the record's foot reads as a card's footer, on the panel color under a hairline.
    private var foot: some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space3) {
            if let problem { Text(problem).font(PhoneFont.callout).foregroundStyle(PhoneTheme.warning).accessibilityIdentifier("task-problem") }
            if hasActions { actions }
        }.padding(PhoneTheme.space4).frame(maxWidth: 750).frame(maxWidth: .infinity)
            .background(PhoneTheme.panel)
            .overlay(alignment: .top) { Rectangle().fill(PhoneTheme.line).frame(height: 1) }
    }

    @ViewBuilder private var actions: some View {
        VStack(spacing: PhoneTheme.space3) {
            if steerable { steerBox }
            if canInterrupt || canStart || canContinue {
                // The card's row (INF-944 item 5): the default lit and last at the trailing edge, Interrupt outlined beside it.
                PhoneChoiceRow {
                    if canInterrupt { choice("Interrupt", id: "interrupt-task", primary: false) { change(.interrupt, args: [task.id], from: "interrupt-task") } }
                    if canStart { choice("Start", id: "start-task", primary: true) { change(.run, args: [task.id, "start-task"], from: "start-task") } }
                    if canContinue { choice("Continue", id: "continue-task", primary: true) { change(.run, args: [task.id, "continue-task"], from: "continue-task") } }
                }
            }
        }.disabled(busy || !session.canChange)
    }

    // The composer's capsule, with Steer as its send arrow, dimmed until there are words to send.
    private var steerBox: some View {
        HStack(alignment: .center, spacing: PhoneTheme.space2) {
            TextField("Message to the crewmate", text: $draft, axis: .vertical).lineLimit(1...4)
                .disabled(busy).accessibilityIdentifier("steer-box")
            Button { change(.steer, args: [task.id, draft], clearDraft: true, from: "steer-task") } label: {
                Group {
                    if busy && pressed == "steer-task" { ProgressView() }
                    else { Label("Steer", systemImage: "arrow.up.circle.fill").labelStyle(.iconOnly) }
                }.frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
            }.disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: .command).accessibilityIdentifier("steer-task")
        }.font(PhoneFont.callout)
            .padding(.leading, PhoneTheme.space4).padding(.trailing, PhoneTheme.space2)
            .background(PhoneTheme.surface, in: Capsule())
            .overlay { Capsule().strokeBorder(PhoneTheme.line) }
    }

    private func choice(_ title: String, id: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).opacity(busy && pressed == id ? 0 : 1)
                .overlay { if busy && pressed == id { ProgressView() } }
        }.buttonStyle(PhoneChoiceStyle(primary: primary)).accessibilityIdentifier(id)
    }

    private func section(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space2) { Text(title).font(PhoneFont.headline); Text(text).textSelection(.enabled) }
    }

    private func refresh() async {
        do {
            let next: PhoneTask = try await session.request(.detail, args: [initial.id])
            guard !Task.isCancelled else { return }
            detail = next; readProblem = nil
            if showingCrew && next.startedAt != nil {
                let transcript: PhoneCrew = try await session.request(.crew, args: [initial.id])
                let running: PhoneCrewLive = try await session.request(.live, args: [initial.id])
                guard !Task.isCancelled else { return }
                crew = transcript; live = running
            }
        } catch { if !Task.isCancelled { readProblem = error.localizedDescription } }
    }

    private func change(_ channel: PhoneRequest, args: [Any], clearDraft: Bool = false, from control: String) {
        guard !busy, session.canChange else { return }
        if clearDraft && draft.utf16.count > PhoneLimits.steer { problem = "This message is too long. Shorten it before sending."; return }
        busy = true; pressed = control; problem = nil
        Task {
            defer { busy = false }
            do {
                let answer: PhoneAnswer = try await session.request(channel, args: args)
                try answer.accepted()
                sent += 1
                if clearDraft { draft = "" }
                await refresh()
            } catch { problem = error.localizedDescription }
        }
    }
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
