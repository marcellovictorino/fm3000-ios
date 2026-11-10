import InfinitaryKit
import SwiftUI

/// INF-1926, the captain's pick: a crewmate's summary in the system's standard sheet. It is the desktop's crew summary
/// (src/renderer/src/character/crew/CrewSummary.tsx and design/core/TaskFacts.tsx) in its words, order, marks and
/// measures, at the chosen 14 points: the board row at once, then the task record's own read, live.
/// INF-2928 piece 3: a long press on a Tasks row shows the same summary over the row's moves, as the Mac's Tasks panel
/// shows it when the pointer rests on a row; there the menu under it holds Open record, so it draws no Open task.
struct PhoneCrewSummary: View {
    let session: ReadOnlySession
    /// The board row; the record's read replaces it once it answers, as on the desktop.
    let task: PhoneTask
    /// The board's tasks, which name its blockers, the task it reviews, its program and a program's parts.
    let tasks: [PhoneTask]
    /// Shows another task's summary in this sheet: a running part, a blocker, the task it reviews or its program.
    var show: (PhoneTask) -> Void = { _ in }
    var open: (PhoneTask) -> Void = { _ in }
    var close: () -> Void = {}
    /// Drawn as a long press's preview: its whole height, with no Open task.
    var preview = false
    @State private var read: (id: String, detail: PhoneTask?)?

    /// The widest the Mac draws the summary when the pointer rests on a row (`CREW_HOVER.maxWidthPx` in
    /// src/renderer/src/character/crew/hoverMeasures.ts), which a long press's preview keeps.
    static let hoverWidth: CGFloat = 360
    private static let labelWidth: CGFloat = 66
    private static let labelGap: CGFloat = 10
    private static let rowGap: CGFloat = 6

    var body: some View {
        Group {
            if preview { summary.fixedSize(horizontal: false, vertical: true) } else { ScrollView { summary } }
        }
        .task(id: "\(session.contact)|\(task.id)") {
            guard session.contact == "in-reach" else { return }
            // Only the open summary polls the record, as the open task record does; the board follows pushes.
            while !Task.isCancelled {
                do {
                    let next: PhoneTask = try await session.request(.detail, args: [task.id])
                    guard !Task.isCancelled else { return }
                    read = (task.id, next)
                } catch {
                    if Task.isCancelled { return }
                    read = (task.id, nil)
                }
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
        }
    }

    private var summary: some View {
        let answered = read?.id == task.id ? read : nil
        let shown = answered?.detail ?? task
        let facts = PhoneTaskFacts(shown, modelName: { model in shown.modelLabel ?? Self.modelTail(model) },
                                   unreadable: answered != nil && answered?.detail == nil)
        return TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let now = timeline.date.timeIntervalSince1970 * 1000
            VStack(alignment: .leading, spacing: 0) {
                head(facts)
                if let review = task.reviewOf { reviewing(review) }
                if let parent = task.parentId { partOf(parent) }
                if !task.blockedBy.isEmpty { blockedBy() }
                if task.program == true { parts() }
                rows(facts, now: now)
                if facts.model != nil || facts.delivery != nil { strip(facts, now: now) }
                if !preview {
                    PhoneChoiceRow {
                        Button("Open task") { open(shown) }.buttonStyle(PhoneChoiceStyle(.secondary))
                            .accessibilityIdentifier("open-crew-task")
                    }.padding(.top, PhoneTheme.space4)
                    // The standard sheet has no close mark; Escape closes it from a keyboard.
                    Button("Close", action: close).keyboardShortcut(.cancelAction).hidden().frame(width: 0, height: 0)
                }
            }
            .font(PhoneFont.summary).foregroundStyle(PhoneTheme.secondary)
            .accessibilityElement(children: .contain).accessibilityIdentifier("crew-preview")
            .frame(maxWidth: PhoneColumn.width, alignment: .leading).frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20).padding(.top, PhoneTheme.space5).padding(.bottom, PhoneTheme.space4)
    }

    /// The host's own fallback when the catalog names no model: the id after its provider.
    static func modelTail(_ model: String) -> String {
        model.firstIndex(of: "/").map { String(model[model.index(after: $0)...]) } ?? model
    }

    // MARK: The head and the rows above the facts

    private func head(_ facts: PhoneTaskFacts) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space2) {
            Text(facts.key).font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted).fixedSize()
            PhoneTaskMark(status: facts.status).alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
            Text(facts.status.label).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("crew-summary-status")
            Spacer(minLength: 0)
        }.padding(.bottom, 10)
    }

    /// Reviewing, Part of and Blocked by: a small label, then each key, which shows that task here.
    private func keyRow(_ label: String, id: String, @ViewBuilder keys: () -> some View) -> some View {
        PhoneFlowRow(spacing: 6) {
            Text(label).font(PhoneFont.label).foregroundStyle(PhoneTheme.muted)
            keys()
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, -4).padding(.bottom, 10)
        .accessibilityElement(children: .contain).accessibilityIdentifier(id)
    }

    private func keyButton(_ key: String, task: PhoneTask?) -> some View {
        Group {
            if let task {
                Button(key) { show(task) }.buttonStyle(.plain).foregroundStyle(PhoneTheme.secondary)
                    // Each key answers a 44-point touch without spacing the row apart.
                    .padding(.vertical, 12).contentShape(Rectangle()).padding(.vertical, -12)
            } else {
                Text(key).foregroundStyle(PhoneTheme.secondary)
            }
        }.font(PhoneFont.micro)
    }

    private func reviewing(_ builderID: String) -> some View {
        let builder = tasks.first { $0.id == builderID }
        return keyRow("Reviewing", id: "crew-summary-reviewing") {
            if let builder { keyButton(builder.key, task: builder) } else { Text("another task").font(PhoneFont.micro) }
        }
    }

    @ViewBuilder private func partOf(_ parentID: String) -> some View {
        if let program = tasks.first(where: { $0.id == parentID && $0.program == true }) {
            keyRow("Part of", id: "crew-summary-part-of") { keyButton(program.key, task: program) }
        }
    }

    /// Each blocker by its key only (INF-2528); when each wait was recorded is the task record's.
    private func blockedBy() -> some View {
        keyRow("Blocked by", id: "crew-summary-blocked") {
            ForEach(task.blockedBy, id: \.self) { key in keyButton(key, task: tasks.first { $0.key == key }) }
        }
    }

    /// A program's parts (INF-1037): the counts, one bar with each state's share, and each running part's key.
    @ViewBuilder private func parts() -> some View {
        let parts = tasks.filter { $0.parentId == task.id && $0.kind == "work" && $0.reviewOf == nil && $0.status != "dropped" }
            .sorted { $0.createdAt == $1.createdAt ? $0.key < $1.key : $0.createdAt < $1.createdAt }
        let finished = parts.filter { $0.status == "done" }.count
        let running = parts.filter { $0.status == "active" }
        let waiting = parts.filter { $0.status == "open" }.count
        if finished + running.count + waiting > 0 {
            VStack(alignment: .leading, spacing: 0) {
                factRow("Parts") {
                    Text("\(finished) finished, \(running.count) running, \(waiting) waiting")
                        .accessibilityIdentifier("crew-program-counts")
                }
                GeometryReader { geometry in
                    let shares = [("finished", finished), ("running", running.count), ("waiting", waiting)].filter { $0.1 > 0 }
                    let room = geometry.size.width - 2 * CGFloat(shares.count - 1)
                    HStack(spacing: 2) {
                        ForEach(shares, id: \.0) { part, count in
                            let shape = RoundedRectangle(cornerRadius: 2)
                            ZStack {
                                if part == "waiting" { shape.strokeBorder(PhoneTheme.lineStrong, lineWidth: 1) }
                                else { shape.fill(part == "finished" ? PhoneTheme.muted : PhoneTheme.accent) }
                            }.frame(width: max(3, room * CGFloat(count) / CGFloat(finished + running.count + waiting)))
                        }
                    }
                }
                .frame(height: 3).padding(.leading, Self.labelWidth + Self.labelGap).padding(.top, 5)
                .accessibilityHidden(true)
                if !running.isEmpty {
                    factRow("Running") {
                        PhoneFlowRow(spacing: 10) {
                            ForEach(running) { part in
                                HStack(alignment: .firstTextBaseline, spacing: 0) {
                                    keyButton(part.key, task: part)
                                    if let place = part.place?.where, !place.isEmpty {
                                        Text(" " + place).font(PhoneFont.label).foregroundStyle(PhoneTheme.muted)
                                    }
                                }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(.top, Self.rowGap)
                }
            }.padding(.top, -4).padding(.bottom, 10)
        }
    }

    // MARK: The facts (TaskFactRows)

    private func factRow(_ label: String, @ViewBuilder value: () -> some View) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Self.labelGap) {
            PhoneFactLabel(text: label).frame(width: Self.labelWidth, alignment: .leading)
            value().frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder private func rows(_ facts: PhoneTaskFacts, now: Double) -> some View {
        let project = [session.board?.projects.first { $0.id == task.projectId }?.name, task.place?.where].compactMap { $0 }.filter { !$0.isEmpty }
            .joined(separator: " · ")
        // The plan is drawn until the task is done or dropped.
        let plan = facts.status.mark == "done" || facts.status.mark == "dropped" ? nil : facts.plan.flatMap { $0.items.isEmpty ? nil : $0 }
        VStack(alignment: .leading, spacing: Self.rowGap) {
            factRow("Task") {
                Text(facts.title).foregroundStyle(PhoneTheme.text).fontWeight(.medium).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("crew-summary-task")
            }
            if !project.isEmpty {
                factRow("Project") {
                    Text(project).foregroundStyle(PhoneTheme.text).fontWeight(.medium).fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("crew-summary-project")
                }
            }
            // Held open while the record is read, so the sheet does not jump.
            if !facts.read || facts.now != nil {
                factRow("Now") {
                    HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space2) {
                        Text(facts.now?.text ?? " ").lineLimit(1).truncationMode(.tail)
                            .accessibilityIdentifier("crew-summary-now")
                        Spacer(minLength: 0)
                        if let at = facts.now?.at { PhoneFactAge(words: PhoneTaskFacts.relativeAge(at, now: max(now, at))) }
                    }
                }
            }
            if let plan {
                let counts = PhoneTaskFacts.planCounts(plan.items)
                factRow("Progress") {
                    HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space2) {
                        Text("\(counts.done) of \(counts.total)").font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted).fixedSize()
                        if counts.skipped > 0 { Text("· \(counts.skipped) skipped").font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted).fixedSize() }
                        Text("·").foregroundStyle(PhoneTheme.muted)
                        Text(counts.current ?? (counts.done == counts.total ? "All done" : "Between items")).lineLimit(1)
                            .accessibilityIdentifier("crew-summary-plan")
                        Spacer(minLength: 0)
                        if let at = plan.at { PhoneFactAge(words: PhoneTaskFacts.relativeAge(at, now: max(now, at))) }
                    }
                }
            }
        }
        if let plan { PhonePlanDots(nodes: PhoneTaskFacts.planNodes(plan.items)).padding(.top, 8).padding(.horizontal, 2) }
    }

    // MARK: The footer (TaskFactRows' summary strip)

    /// INF-2528, the captain's direction B: one row that never wraps - the model with its intelligence badge, then the
    /// change with its checks as one state and its time (`#813 running for 11m`); a long model name gives way first,
    /// ending in an ellipsis. A review's verdict takes a second row. Reasoning, its footnote, the check counts, a
    /// refusal's reason and when the checks finished are the task record's.
    private func strip(_ facts: PhoneTaskFacts, now: Double) -> some View {
        let change = facts.delivery?.change, checks = facts.delivery?.checks
        return VStack(alignment: .leading, spacing: PhoneTheme.space2) {
            if facts.model != nil || change != nil || checks != nil {
                HStack(alignment: .top, spacing: PhoneTheme.space4) {
                    if let model = facts.model {
                        cell("Model") {
                            HStack(spacing: PhoneTheme.space2) {
                                Text(model).lineLimit(1).truncationMode(.tail).accessibilityIdentifier("crew-summary-model")
                                if let tier = facts.tier { PhoneSlotBadge(slot: tier).fixedSize() }
                            }
                        }.layoutPriority(0)
                    }
                    if change != nil || checks != nil {
                        cell(change?.noun ?? "Checks") {
                            HStack(spacing: PhoneTheme.space2) {
                                if let change {
                                    Text(change.label ?? change.noun).lineLimit(1).accessibilityIdentifier("crew-summary-change")
                                }
                                if let checks {
                                    HStack(spacing: 4) {
                                        PhoneFactDot(state: checks.dot)
                                        Text(checks.stateWords(now: now)).lineLimit(1).accessibilityIdentifier("crew-summary-checks")
                                    }
                                }
                            }.fixedSize()
                        }.layoutPriority(1)
                    }
                    Spacer(minLength: 0)
                }
            }
            if let review = facts.delivery?.review {
                cell("Review") {
                    HStack(spacing: 4) { PhoneFactDot(state: review.dot); Text(review.words).accessibilityIdentifier("crew-summary-review") }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
        .overlay(alignment: .top) { Rectangle().fill(PhoneTheme.line).frame(height: 1) }
        .padding(.top, 10)
    }

    private func cell(_ label: String, @ViewBuilder value: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            PhoneFactLabel(text: label).fixedSize()
            value()
        }
    }
}

/// An uppercase micro label in the desktop's tracking.
struct PhoneFactLabel: View {
    let text: String
    var body: some View {
        Text(text).textCase(.uppercase).font(PhoneFont.label).tracking(1).foregroundStyle(PhoneTheme.muted)
    }
}

struct PhoneFactAge: View {
    let words: String
    var body: some View { Text(words).font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted).fixedSize() }
}

/// TaskStatusMark: the task's state as a 12-point mark in the desktop's 16-unit box; shape carries it as well as color.
struct PhoneTaskMark: View {
    let status: PhoneTaskFacts.Status

    var body: some View {
        let wait = status.outOfReach ? nil : status.wait
        let mark = status.mark
        let color: Color = status.outOfReach ? PhoneTheme.warning
            : wait == "checks" || wait == "batch" ? PhoneTheme.accent
            : mark == "working" ? PhoneTheme.warning
            : mark == "starting" ? PhoneTheme.accent
            : mark == "idle" ? PhoneTheme.ok
            : mark == "interrupted" ? PhoneTheme.danger
            : mark == "waiting" ? PhoneTheme.accent
            : mark == "dropped" ? PhoneTheme.muted : PhoneTheme.secondary
        Canvas { context, _ in
            context.scaleBy(x: 0.75, y: 0.75)
            func circle(_ r: CGFloat) -> Path { Path(ellipseIn: CGRect(x: 8 - r, y: 8 - r, width: 2 * r, height: 2 * r)) }
            let round = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            switch mark {
            case "done":
                var tick = Path(); tick.addLines([CGPoint(x: 2, y: 8), CGPoint(x: 6, y: 12), CGPoint(x: 14, y: 3)])
                context.stroke(tick, with: .color(color), style: round)
            case "dropped":
                var cross = Path()
                cross.move(to: CGPoint(x: 3, y: 3)); cross.addLine(to: CGPoint(x: 13, y: 13))
                cross.move(to: CGPoint(x: 13, y: 3)); cross.addLine(to: CGPoint(x: 3, y: 13))
                context.stroke(cross, with: .color(color), style: round)
            default:
                if mark == "starting" {
                    context.stroke(circle(5), with: .color(PhoneTheme.lineStrong), lineWidth: 1.5)
                    var arc = Path()
                    arc.addArc(center: CGPoint(x: 8, y: 8), radius: 5, startAngle: .degrees(-90), endAngle: .degrees(180), clockwise: false)
                    context.stroke(arc, with: .color(PhoneTheme.accent), lineWidth: 1.5)
                } else if wait == "batch" {
                    let gate = CharacterCatalog.shared.batch, half = gate["arcDeg"]! * .pi / 360
                    for center in [0.0, Double.pi] {
                        var arc = Path()
                        arc.addArc(center: CGPoint(x: 8, y: 8), radius: 6,
                                   startAngle: .radians(center - half), endAngle: .radians(center + half), clockwise: false)
                        context.stroke(arc, with: .color(PhoneTheme.accent), style: StrokeStyle(lineWidth: gate["line"]!, lineCap: .round))
                    }
                    context.fill(circle(3), with: .color(color))
                } else if wait != nil {
                    context.stroke(circle(6), with: .color(PhoneTheme.accent), style: StrokeStyle(lineWidth: 1.2, dash: [2.6, 2.1]))
                    context.fill(circle(3), with: .color(color))
                } else {
                    if ["working", "idle", "interrupted"].contains(mark) { context.fill(circle(6), with: .color(color)) }
                    context.stroke(circle(6), with: .color(color), lineWidth: 1.2)
                }
                if mark == "queued" || mark == "waiting" { context.fill(circle(mark == "waiting" ? 3 : 2), with: .color(color)) }
            }
        }
        .frame(width: 12, height: 12).accessibilityHidden(true)
    }
}

/// FactDot: a fact cell's state at 10 points - a disc with a tick, cross or bang, or a ring.
struct PhoneFactDot: View {
    let state: String

    var body: some View {
        Canvas { context, _ in
            let disc = Path(ellipseIn: CGRect(x: 0.5, y: 0.5, width: 9, height: 9))
            let ring = Path(ellipseIn: CGRect(x: 1, y: 1, width: 8, height: 8))
            var mark = Path()
            let fill: Color
            switch state {
            case "ok":
                fill = PhoneTheme.ok
                mark.addLines([CGPoint(x: 3, y: 5.2), CGPoint(x: 4.4, y: 6.6), CGPoint(x: 7.2, y: 3.7)])
            case "failed":
                fill = PhoneTheme.danger
                mark.move(to: CGPoint(x: 3.4, y: 3.4)); mark.addLine(to: CGPoint(x: 6.6, y: 6.6))
                mark.move(to: CGPoint(x: 6.6, y: 3.4)); mark.addLine(to: CGPoint(x: 3.4, y: 6.6))
            case "warn":
                fill = PhoneTheme.warning
                mark.move(to: CGPoint(x: 5, y: 2.6)); mark.addLine(to: CGPoint(x: 5, y: 5.6))
                mark.move(to: CGPoint(x: 5, y: 7.2)); mark.addLine(to: CGPoint(x: 5, y: 7.4))
            default:
                context.stroke(ring, with: .color(state == "running" ? PhoneTheme.accent : PhoneTheme.idle), lineWidth: 1.5)
                return
            }
            context.fill(disc, with: .color(fill))
            context.stroke(mark, with: .color(PhoneTheme.surface), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        }
        .frame(width: 10, height: 10).accessibilityHidden(true)
    }
}

/// SlotBadge: the intelligence level as four rising bars and its word, in the level's own color.
struct PhoneSlotBadge: View {
    let slot: String

    var body: some View {
        let (label, color, bars): (String, Color, Int) = switch slot {
        case "premium": ("Premium", PhoneTheme.slotPremium, 4)
        case "high": ("High", PhoneTheme.slotHigh, 3)
        case "low": ("Low", PhoneTheme.slotLow, 1)
        default: ("Med", PhoneTheme.slotMedium, 2)
        }
        HStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1).fill(i < bars ? color : PhoneTheme.raised).frame(width: 3, height: CGFloat(4 + i * 2))
                }
            }
            Text(label).textCase(.uppercase).font(PhoneFont.micro).fontWeight(.medium).tracking(1).foregroundStyle(color)
        }
    }
}

/// The plan on the line (PlanDots): one dot per item with its short label under it, the line filled in behind the
/// finished dots. Past eight dots the labels stagger above and below.
private struct PhonePlanDots: View {
    let nodes: [PhoneTaskFacts.PlanNode]

    var body: some View {
        let stagger = nodes.count > 8
        let markY: CGFloat = stagger ? 15 : 0
        GeometryReader { geometry in
            let column = geometry.size.width / CGFloat(max(1, nodes.count))
            ZStack(alignment: .topLeading) {
                ForEach(Array(nodes.enumerated()), id: \.offset) { index, node in
                    let center = column * (CGFloat(index) + 0.5)
                    if index > 0 {
                        Path { path in
                            path.move(to: CGPoint(x: center - column + 6, y: markY + 6))
                            path.addLine(to: CGPoint(x: center - 6, y: markY + 6))
                        }.stroke(nodes[index - 1].state == "done" ? PhoneTheme.muted : PhoneTheme.lineStrong, lineWidth: 1)
                    }
                    PhonePlanMark(state: node.state).position(x: center, y: markY + 6)
                    let above = stagger && index % 2 == 0
                    let room = stagger ? column * 2 - 6 : column - 4
                    let align: Alignment = stagger && index == 0 ? .leading : stagger && index == nodes.count - 1 ? .trailing : .center
                    Text(node.short).font(PhoneFont.label).lineLimit(1).truncationMode(.tail)
                        .foregroundStyle(node.state == "current" ? PhoneTheme.text : node.state == "done" ? PhoneTheme.secondary : PhoneTheme.muted)
                        .fontWeight(node.state == "current" ? .medium : .regular)
                        .frame(width: room, height: 15, alignment: align)
                        .position(x: align == .leading ? center - column / 2 + room / 2 : align == .trailing ? center + column / 2 - room / 2 : center,
                                  y: above ? 7.5 : markY + 12 + 7.5)
                }
            }
        }
        .frame(height: markY + 12 + 15)
        .accessibilityElement(children: .ignore).accessibilityIdentifier("crew-summary-plan-dots")
    }
}

/// PlanMark as a dot: filled when done, lit when current, hollow when next, a dash when skipped.
struct PhonePlanMark: View {
    let state: String

    var body: some View {
        Canvas { context, _ in
            context.scaleBy(x: 0.75, y: 0.75)
            func circle(_ r: CGFloat) -> Path { Path(ellipseIn: CGRect(x: 8 - r, y: 8 - r, width: 2 * r, height: 2 * r)) }
            switch state {
            case "skipped":
                var dash = Path(); dash.move(to: CGPoint(x: 4, y: 8)); dash.addLine(to: CGPoint(x: 12, y: 8))
                context.stroke(dash, with: .color(PhoneTheme.muted), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            case "done": context.fill(circle(4), with: .color(PhoneTheme.secondary))
            case "current":
                context.fill(circle(5), with: .color(PhoneTheme.accentDim))
                context.stroke(circle(5), with: .color(PhoneTheme.accent), lineWidth: 1.8)
            default: context.stroke(circle(4), with: .color(PhoneTheme.idle), lineWidth: 1.2)
            }
        }
        .frame(width: 12, height: 12).accessibilityHidden(true)
    }
}

/// The corner brackets round the crewmate whose summary is open, as the desktop draws them: five points a side.
struct PhoneCrewBrackets: Shape {
    let reach: CGFloat

    func path(in rect: CGRect) -> Path {
        let arm: CGFloat = 5, box = CGRect(x: rect.midX - reach, y: rect.midY - reach, width: 2 * reach, height: 2 * reach)
        var path = Path()
        for (corner, dx, dy) in [(CGPoint(x: box.minX, y: box.minY), 1.0, 1.0), (CGPoint(x: box.maxX, y: box.minY), -1.0, 1.0),
                                 (CGPoint(x: box.minX, y: box.maxY), 1.0, -1.0), (CGPoint(x: box.maxX, y: box.maxY), -1.0, -1.0)] {
            path.move(to: CGPoint(x: corner.x + dx * arm, y: corner.y))
            path.addLine(to: corner)
            path.addLine(to: CGPoint(x: corner.x, y: corner.y + dy * arm))
        }
        return path
    }
}
