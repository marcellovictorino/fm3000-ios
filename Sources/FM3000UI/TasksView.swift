import FM3000Core
import FM3000Model
import SwiftUI

/// The Tasks tab: a list by project, or a kanban board by status. The toggle in the header picks one;
/// until it is used, the phone's orientation does (landscape shows the board, portrait the list).
struct BoardView: View {
    @ObservedObject var model: AppModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var picked: TasksLayout?
    @State private var path: [BoardTask] = []
    @State private var projectId: String?

    private var layout: TasksLayout { tasksLayout(picked: picked ?? DebugLaunch.layout, landscape: verticalSizeClass == .compact) }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let board = model.board {
                    VStack(spacing: 0) {
                        ProjectPills(board: board, selected: $projectId)
                        let shown = board.filtered(by: projectId)
                        if layout == .board { KanbanView(board: shown, names: model.taskModels) } else { TaskListView(board: shown, names: model.taskModels) }
                    }
                } else {
                    Text("Loading the task board…").foregroundStyle(Theme.fg2).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Theme.backdrop)
            .safeAreaInset(edge: .top, spacing: 0) { StatusBanner(model: model) }
            .navigationTitle("Tasks").iOSInlineTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { picked = layout == .board ? .list : .board } label: {
                        Image(systemName: layout == .board ? "list.bullet" : "rectangle.split.3x1")
                    }
                    .accessibilityLabel(layout == .board ? "Show as list" : "Show as board")
                }
            }
            .navigationDestination(for: BoardTask.self) { TaskDetailView(model: model, task: $0) }
            .refreshable { await model.refreshBoard() }
            .onChange(of: model.phase) { phase in
                if case .connected = phase {
                    Task {
                        await model.refreshBoard()
                        if DebugLaunch.has("-openTask"), path.isEmpty, let first = DebugLaunch.has("-queuedTask") ? model.board?.tasks.first(where: \.notStarted) : model.board?.tasks.first { path = [first] }
                    }
                }
            }
            .task {
                await model.refreshBoard()
                if DebugLaunch.has("-openTask"), path.isEmpty, let first = DebugLaunch.has("-queuedTask") ? model.board?.tasks.first(where: \.notStarted) : model.board?.tasks.first { path = [first] }
            }
        }
    }
}

/// One pill per project with its task count beside it, plus All. Tapping one filters both the list and the board.
private struct ProjectPills: View {
    let board: Board
    @Binding var selected: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pill("All", count: board.tasks.count, isOn: selected == nil) { selected = nil }
                ForEach(board.projectPills, id: \.project.id) { entry in
                    pill(entry.project.name, count: entry.count, isOn: selected == entry.project.id) { selected = entry.project.id }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
        }
    }

    private func pill(_ title: String, count: Int, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title).font(.subheadline.weight(.medium)).lineLimit(1)
                Text("\(count)").font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background((isOn ? Theme.bg0 : Theme.fg3).opacity(isOn ? 0.25 : 0.2), in: Capsule())
            }
            .foregroundStyle(isOn ? Theme.bg0 : Theme.fg1)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isOn ? Theme.accent : Theme.bg2, in: Capsule())
            .overlay(Capsule().stroke(isOn ? Color.clear : Theme.line.opacity(0.6), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(count) tasks")
    }
}

private struct TaskListView: View {
    let board: Board
    let names: [String: String]

    var body: some View {
        List {
            ForEach(board.projects.filter { !$0.archived }) { project in
                Section("\(project.name) · \(project.counts.needsYou) need you") {
                    ForEach(foldPrograms(board.tasks).filter { $0.projectId == project.id && ($0.status == "open" || $0.status == "active") }) { task in
                        NavigationLink(value: task) {
                            VStack(alignment: .leading, spacing: 2) {
                                ModelPill(name: names[task.id] ?? modelPill(label: nil, id: task.model))
                                Text("\(task.key)  \(task.title)").font(.headline)
                                Text([task.status, task.activity, task.assignee, task.partsLine].compactMap { $0 }.joined(separator: " · ")).font(.caption).foregroundStyle(Theme.fg2)
                            }
                        }
                        .infinitaryRow()
                    }
                }
            }
        }
        .infinitaryScreen()
    }
}

/// Columns by status, side by side; the columns scroll sideways and each scrolls down.
private struct KanbanView: View {
    let board: Board
    let names: [String: String]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(boardColumns(board.tasks)) { column in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(column.title) · \(column.tasks.count)").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.fg2)
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(column.tasks) { task in
                                    NavigationLink(value: task) { KanbanCard(task: task, name: names[task.id] ?? modelPill(label: nil, id: task.model)) }.buttonStyle(.plain)
                                }
                                if column.tasks.isEmpty { Text("Nothing here").font(.footnote).foregroundStyle(Theme.fg3).padding(.top, 8) }
                            }
                        }
                    }
                    .frame(width: 250)
                }
            }
            .padding(12)
        }
    }
}

private struct KanbanCard: View {
    let task: BoardTask
    let name: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ModelPill(name: name)
            Text(task.key).font(.caption.monospaced()).foregroundStyle(Theme.accent)
            Text(task.title).font(.subheadline).multilineTextAlignment(.leading)
            if let line = [task.activity, task.assignee, task.partsLine].compactMap({ $0 }).joined(separator: " · ") as String?, !line.isEmpty {
                Text(line).font(.caption).foregroundStyle(Theme.fg2)
            }
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bg2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.line.opacity(0.6), lineWidth: 0.5))
    }
}

/// One task as the desktop shows it: state, the open card with its buttons, delivery, the crewmate's latest words,
/// and a thread to talk to the crewmate. The board row gives the first paint; `inf:tasks:detail` fills in the rest.
struct TaskDetailView: View {
    @ObservedObject var model: AppModel
    let task: BoardTask
    @State private var detail: TaskDetail?
    @State private var log: CrewLog?
    @State private var live: CrewLive?
    @State private var showCrew = DebugLaunch.has("-openCrew")

    private var cardId: String? { detail?.waitingCardId ?? task.waitingCardId }
    private var card: Card? { cardId.flatMap { id in model.cards.first { $0.id == id } } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if let live, !live.text.isEmpty { section("Right now") { Text(live.text).font(.footnote).foregroundStyle(Theme.fg2) } }
                if let goal = detail?.goal, !goal.isEmpty { section("Goal") { Text(goal) } }
                if let card { cardSection(card) }
                if let delivery = detail?.delivery, delivery.prNumber != nil || delivery.ci != nil { deliverySection(delivery) }
                if let text = detail?.outcome ?? detail?.problem, !text.isEmpty { section(detail?.problem != nil ? "Problem" : "Outcome") { Text(text) } }
                activitySection
                Button { showCrew = true } label: {
                    rowLabel("bubble.left.and.bubble.right", "Thread with the crewmate")
                }
                .buttonStyle(.plain)
                .navigationDestination(isPresented: $showCrew) { CrewThreadView(model: model, task: task, log: $log) }
            }
            .padding()
        }
        .background(Theme.backdrop)
        .navigationTitle(task.key).iOSInlineTitle()
        .refreshable { await load() }
        .task { await load() }
    }

    private func load() async {
        async let d = model.taskDetail(task.id)
        async let l = model.crewLog(task.id)
        async let v = model.crewLive(task.id)
        (detail, log, live) = await (d, l, v)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            ModelPill(name: modelPill(label: detail?.modelLabel, id: detail?.model ?? task.model, effort: detail?.reasoning?.level))
            Text(detail?.title ?? task.title).font(.title3.weight(.semibold))
            HStack(spacing: 6) {
                chip((detail?.status ?? task.status).capitalized, Theme.accent)
                if let posture = detail?.workPosture { chip("\(posture.state.capitalized) · \(posture.reason)", posture.state == "active" ? Theme.accent : Theme.fg2) }
                else if let activity = detail?.activity ?? task.activity { chip(activity.capitalized, Theme.fg2) }
            }
            Text("Updated \(relativeTime(detail?.updatedAt ?? task.updatedAt))").font(.caption).foregroundStyle(Theme.fg3)
        }
    }

    private func cardSection(_ card: Card) -> some View {
        section("Waiting on you") {
            VStack(alignment: .leading, spacing: 10) {
                Text(card.title).font(.headline)
                CardBody(html: card.body)
                CardChoices(model: model, card: card)
                NavigationLink { CardThreadView(model: model, card: card) } label: {
                    rowLabel("bubble.left", repliesLabel((model.threads[card.id] ?? []).count))
                }.buttonStyle(.plain)
            }
        }
    }

    private func deliverySection(_ delivery: TaskDetail.Delivery) -> some View {
        section("Change") {
            VStack(alignment: .leading, spacing: 6) {
                if let number = delivery.prNumber {
                    if let url = delivery.prUrl.flatMap(URL.init(string:)) { Link("Pull request #\(number)", destination: url) } else { Text("Pull request #\(number)") }
                } else if let mode = delivery.mode { Text("Delivery: \(mode)") }
                HStack(spacing: 6) {
                    if let ci = delivery.ci { chip("Checks \(ci)", ci == "green" || ci == "merged" ? Theme.accent : (ci == "red" ? Theme.danger : Theme.warn)) }
                    if let run = delivery.runChecks { chip("\(run.name): \(run.state)", run.state == "failed" ? Theme.danger : Theme.fg2) }
                }
            }
        }
    }

    private var activitySection: some View {
        let lines = (log?.lines ?? []).filter { $0.readable != nil && $0.kind != "sent" }.suffix(8).reversed()
        return section("Latest from the crewmate") {
            if lines.isEmpty { Text(log == nil ? "Loading…" : "Nothing yet.").font(.footnote).foregroundStyle(Theme.fg2) }
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(lines)) { line in
                    if let read = line.readable {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(read.who) · \(relativeTime(line.at))").font(.caption2).foregroundStyle(Theme.fg3)
                            Text(read.text).font(.footnote).lineLimit(6)
                        }
                    }
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(Theme.fg3)
            content().frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12).background(Theme.bg2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func chip(_ text: String, _ color: Color) -> some View {
        Text(text).font(.caption2.weight(.medium)).foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
    }

    private func rowLabel(_ symbol: String, _ text: String) -> some View {
        HStack {
            Image(systemName: symbol)
            Text(text)
            Spacer()
            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Theme.fg3)
        }
        .padding(14).background(Theme.bg2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private func problemLine(_ why: String) -> some View {
    Label(why, systemImage: "exclamationmark.circle").font(.footnote).foregroundStyle(Theme.warn)
        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16).padding(.vertical, 8)
        .background(Theme.bg1)
}

/// The crewmate's thread: what it said and reported, and what you told it, as a chat with the composer pinned below.
struct CrewThreadView: View {
    @ObservedObject var model: AppModel
    let task: BoardTask
    @Binding var log: CrewLog?
    @State private var text = ""
    @State private var sending = false

    /// The board's newest word on this task, since the one handed in was read before Start was pressed.
    private var notStartedNotice: some View {
        HStack(spacing: 10) {
            Text("This task has not started yet, so nobody can read messages. Start it first.").font(.footnote).foregroundStyle(Theme.fg2)
            Spacer(minLength: 8)
            Button { Task { _ = await model.startTask(task.id) } } label: { Text("Start") }
                .buttonStyle(.borderedProminent).tint(Theme.accentStrong).disabled(!model.canChange)
        }
        .padding(.horizontal, 16).padding(.vertical, 10).background(Theme.bg1)
    }

    private var current: BoardTask { model.board?.tasks.first { $0.id == task.id } ?? task }

    var body: some View {
        ChatList(items: (log?.lines ?? []).compactMap(\.chatItem), empty: current.notStarted ? "Nothing yet: this task has not started." : "Nothing said yet. Write below to tell the crewmate something.", typing: model.awaitingThreads.contains("crew-" + task.id) || DebugLaunch.has("-typing"))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if current.notStarted { notStartedNotice } else if let why = model.steerProblem { problemLine(why) }
            Composer(placeholder: current.notStarted ? "Not started yet" : "Tell \(task.key)’s crewmate…", text: $text, attachments: nil, enabled: model.canChange && !current.notStarted, sending: sending) {
                let words = text
                sending = true
                Task {
                    if await model.steer(task.id, words) { text = ""; model.expectCrewReply(task.id); log = await model.crewLog(task.id) }
                    sending = false
                }
            }
            }
        }
        .navigationTitle("Thread").iOSInlineTitle()
        .task { model.clearSteerProblem(); log = await model.crewLog(task.id) }
        .task(id: model.awaitingThreads.contains("crew-" + task.id)) {
            // While the crewmate may answer, read its log again every few seconds; a line from it ends the dots.
            while model.awaitingThreads.contains("crew-" + task.id), !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                log = await model.crewLog(task.id)
                if let last = (log?.lines ?? []).compactMap(\.chatItem).last, !last.isMine { model.crewAnswered(task.id) }
            }
        }
    }
}
