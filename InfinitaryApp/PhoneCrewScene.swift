import InfinitaryKit
import SwiftUI
import UIKit

/// The empty card stage keeps the desktop's formations, its orbits scaled so eight crewmates fit an upright iPhone. Touch pans the scene instead of paging computers.
struct PhoneCrewScene: View {
    let session: ReadOnlySession
    @Environment(PhoneMessageContext.self) private var messageContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    /// INF-2566: the scene's motion and drawing live on their own render thread; this view only hands it inputs.
    @State private var renderer = PhoneSceneRenderer()
    @State private var rosters = PhoneSceneRoster.Cache()
    @State private var visible = false
    @State private var preview: PhoneTask?
    @State private var computerPreview: String?
    @State private var previewComputer: String?
    @State private var record: PhoneTask?
    @State private var position = ScrollPosition()
    @State private var centered = false
    /// The scroller's offset, read on input; the renderer takes it straight from the scroller, never through a body update.
    @State private var pan = PanReading()
    @State private var browsing = false
    @State private var selectedCrew: String?

    var body: some View {
        let roster = rosters.read(board: session.board, presence: session.computers, homeName: session.mac.name,
                                  inReach: session.contact == "in-reach", generation: session.sceneGeneration, revision: session.workRevision)
        let still = reduceMotion || phase != .active || !messageContext.cardsVisible || !visible || record != nil
        GeometryReader { geometry in
            let viewport = PhoneSceneViewport(scene: CGSize(width: roster.width, height: roster.height),
                                              home: CGPoint(x: roster.homeX, y: roster.height / 2),
                                              size: geometry.size, generation: roster.generation)
            ScrollView(geometry.size.height < roster.height ? [.horizontal, .vertical] : [.horizontal]) {
                PhoneSceneControls(roster: roster, crew: renderer.crew, state: session.firstmateBusy ? .working : .idle, observed: session.firstmateObserved,
                                   offset: viewport.offset, preview: $preview, computerPreview: $computerPreview, previewComputer: $previewComputer, selection: selectedCrew)
                    .frame(width: viewport.content.width, height: viewport.content.height)
            }
            .scrollPosition($position).defaultScrollAnchor(.topLeading)
            // The captain pans the scene by touch; scroll bars at its edges say nothing (INF-1328).
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: CGPoint.self) { $0.contentOffset } action: { _, point in pan.point = point; renderer.pan(to: point) }
            .overlay {
                // The drawing stays over the viewport and draws the scene where the scroller has panned it.
                PhoneSceneSurface(renderer: renderer, roster: roster, state: session.firstmateBusy ? .working : .idle, still: still,
                                  running: !still && preview == nil, offset: viewport.offset, selection: selectedCrew,
                                  bracketed: preview.map { ($0.id, previewComputer ?? PhoneSceneRoster.computerID($0)) })
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
            .overlay {
                RoundedRectangle(cornerRadius: PhoneTheme.controlRadius)
                    .stroke(browsing ? PhoneTheme.accent : .clear, lineWidth: 1.5)
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
            .background { keyboardCommands(roster: roster, viewport: viewport) }
            .accessibilityLabel("Crew scene")
            .accessibilityValue(browsing ? "Browsing crew" : "Not browsing")
            .accessibilityHint("Swipe to browse. Shift-Command-C starts crew browsing; arrow keys pan it. Tab selects a crewmate, Space opens their task, and Escape stops browsing.")
            .accessibilityIdentifier("crew-scene")
            .onAppear {
                if !centered {
                    position.scrollTo(point: viewport.centered)
                    centered = true
                }
            }
            .onChange(of: viewport) { old, new in
                let next = new.preserving(pan.point, from: old)
                if next != pan.point { position.scrollTo(point: next) }
                if old.generation != new.generation { preview = nil; computerPreview = nil; previewComputer = nil; stopBrowsing() }
            }
            .onChange(of: roster.sequence) { _, _ in
                if let selectedCrew, !keyboardTargets(roster: roster).contains(where: { $0.id == selectedCrew }) { self.selectedCrew = nil }
                // An open summary follows its task's newest row while the task is on the board, whatever its state, since
                // a key in the summary can show a task that has no glyph.
                if let selected = preview { preview = roster.allTasks.first { $0.id == selected.id } }
                if let id = computerPreview, !roster.computers.contains(where: { $0.id == id }) { computerPreview = nil }
            }
            .overlay(alignment: .bottom) {
                if let id = computerPreview, let computer = roster.computers.first(where: { $0.id == id }) {
                    ScrollView { computerCard(computer) }.defaultScrollAnchor(.bottom, for: .alignment).frame(maxWidth: 364, maxHeight: max(44, geometry.size.height - 2 * PhoneTheme.space3))
                        .padding(PhoneTheme.space3)
                }
            }
        }
        .onAppear { visible = true; syncClock() }
        .onDisappear { visible = false; stopBrowsing(); syncClock(); CharacterCues.left(renderer.character) }
        .onChange(of: phase) { _, _ in if phase != .active { stopBrowsing() }; syncClock() }
        .onChange(of: reduceMotion) { _, _ in syncClock() }
        .onChange(of: messageContext.cardsVisible) { _, _ in if !messageContext.cardsVisible { stopBrowsing() }; syncClock() }
        .onChange(of: record?.id) { _, _ in if record != nil { stopBrowsing() }; syncClock() }
        .onChange(of: preview?.id) { _, _ in if preview != nil { stopBrowsing() }; syncClock() }
        .onChange(of: computerPreview) { _, _ in if computerPreview != nil { stopBrowsing() } }
        .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { _ in stopBrowsing() }
        .onReceive(NotificationCenter.default.publisher(for: UITextView.textDidBeginEditingNotification)) { _ in stopBrowsing() }
        // INF-1926: a crewmate's summary is the system's standard sheet; Open task swaps it for the task record.
        .sheet(item: sheet, onDismiss: { if record == nil { messageContext.taskID = nil } }) { shown in
            switch shown {
            case .summary(let task):
                PhoneCrewSummary(session: session, task: task, roster: roster,
                                 show: { task in preview = task; previewComputer = PhoneSceneRoster.computerID(task) },
                                 open: { task in record = task; preview = nil; messageContext.taskID = task.id },
                                 close: { preview = nil; previewComputer = nil })
                    .presentationDetents([.medium, .large]).presentationDragIndicator(.visible).phoneSheetSurface()
                    .tint(PhoneTheme.accent)
            case .record(let task):
                NavigationStack {
                    PhoneTaskRecord(session: session, initial: task)
                        .toolbar { ToolbarItem(placement: .cancellationAction) { PhoneRecordLeaveButton(record: $record) } }
                }.font(PhoneFont.body).tint(PhoneTheme.accent)
            }
        }
    }
    private enum Sheet: Identifiable {
        /// One summary sheet whichever task it shows, so a running part or a blocker replaces the words in place. It carries
        /// its task, so the sheet keeps its words while it slides away after the preview has closed.
        case summary(PhoneTask)
        case record(PhoneTask)
        var id: String {
            switch self {
            case .summary: "summary"
            case .record(let task): "record-" + task.id
            }
        }
    }
    private var sheet: Binding<Sheet?> {
        Binding(get: { record.map(Sheet.record) ?? preview.map(Sheet.summary) },
                set: { if $0 == nil { record = nil; preview = nil; previewComputer = nil } })
    }
    @ViewBuilder private func keyboardCommands(roster: PhoneSceneRoster, viewport: PhoneSceneViewport) -> some View {
        if visible && messageContext.cardsVisible && phase == .active && record == nil && preview == nil && computerPreview == nil {
            Button("Browse crew") { dismissPhoneKeyboard(); browsing = true; selectedCrew = nil }
                .keyboardShortcut("c", modifiers: [.command, .shift]).hidden()
            // Unmodified keys reach the app only as priority commands of the current first responder.
            // The scene holds that ownership only while browsing and releases it with every stop.
            PhoneBrowsingKeys(active: browsing) { key in
                switch key {
                case .left: panBy(x: -44, y: 0, viewport: viewport)
                case .right: panBy(x: 44, y: 0, viewport: viewport)
                case .up: panBy(x: 0, y: -44, viewport: viewport)
                case .down: panBy(x: 0, y: 44, viewport: viewport)
                case .next: browseNext(roster: roster, viewport: viewport)
                case .open: openSelected(roster: roster)
                case .stop: stopBrowsing()
                }
            }.frame(width: 0, height: 0).accessibilityHidden(true)
        }
    }
    // INF-1066 / INF-1147: app-owned browsing, never UIKit's unreliable scene focus.
    // Read the drawing owner's current positions only on input; the shell still observes no display tick.
    private struct KeyboardTarget {
        let id: String, task: PhoneTask, computer: String, point: CGPoint
    }
    private func keyboardTargets(roster: PhoneSceneRoster) -> [KeyboardTarget] {
        let glyphs = renderer.crew.current.glyphs.filter { roster.order[$0.task.id] != nil }.map {
            KeyboardTarget(id: $0.task.id, task: $0.task, computer: PhoneSceneRoster.computerID($0.task), point: $0.point)
        }
        let marks = renderer.crew.current.marks.filter { mark in
            roster.computers.contains { $0.id == mark.computerID && $0.programs.contains { $0.id == mark.task.id } }
        }.map { KeyboardTarget(id: $0.id, task: $0.task, computer: $0.computerID, point: $0.point) }
        return (glyphs + marks).sorted {
            let left = roster.order[$0.task.id] ?? roster.tasks.count, right = roster.order[$1.task.id] ?? roster.tasks.count
            return left == right ? $0.id < $1.id : left < right
        }
    }
    private func panBy(x: CGFloat, y: CGFloat, viewport: PhoneSceneViewport) {
        position.scrollTo(point: viewport.clamped(CGPoint(x: pan.point.x + x, y: pan.point.y + y)))
    }
    private func browseNext(roster: PhoneSceneRoster, viewport: PhoneSceneViewport) {
        let targets = keyboardTargets(roster: roster)
        guard !targets.isEmpty else { selectedCrew = nil; return }
        let index = selectedCrew.flatMap { selected in targets.firstIndex { $0.id == selected } }
        let target = targets[((index ?? -1) + 1) % targets.count]
        selectedCrew = target.id
        position.scrollTo(point: viewport.clamped(CGPoint(x: target.point.x + viewport.offset.width - viewport.size.width / 2,
                                                         y: target.point.y + viewport.offset.height - viewport.size.height / 2)))
    }
    private func openSelected(roster: PhoneSceneRoster) {
        guard let target = keyboardTargets(roster: roster).first(where: { $0.id == selectedCrew }) else { return }
        preview = target.task; previewComputer = target.computer; computerPreview = nil
    }
    private func stopBrowsing() { browsing = false; selectedCrew = nil }
    private func syncClock() {
        // The captain's pick: the scene stands still where it is while a summary is open, so its brackets stay put.
        let running = visible && messageContext.cardsVisible && record == nil && preview == nil && !reduceMotion && phase == .active
        if running { CharacterCues.shown.add(renderer.character); CharacterCues.crews.add(renderer.crew) }
        else {
            CharacterCues.shown.remove(renderer.character); CharacterCues.crews.remove(renderer.crew)
            renderer.character.discardReactions(); renderer.crew.discardEffects()
        }
    }
    private func computerCard(_ computer: PhoneSceneRoster.Computer) -> some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space2) {
            HStack {
                Text(computer.name).font(PhoneFont.headline)
                Spacer()
                Button { computerPreview = nil } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                    .accessibilityLabel("Close computer preview")
            }
            if !computer.reachable { Text("Activity unknown").foregroundStyle(PhoneTheme.secondary) }
            ForEach(computer.tasks) { task in
                Button { preview = task; previewComputer = computer.id; computerPreview = nil } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.key).font(PhoneFont.mono).foregroundStyle(PhoneTheme.secondary)
                        Text(task.title).font(PhoneFont.body).foregroundStyle(PhoneTheme.text)
                        Text(PhoneSceneRoster.words(task, computer: computer)).font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
                    }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }.buttonStyle(.plain)
            }
        }.padding(PhoneTheme.space3).background(PhoneTheme.panel, in: RoundedRectangle(cornerRadius: PhoneTheme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: PhoneTheme.cardRadius).stroke(PhoneTheme.line))
            .accessibilityElement(children: .contain).accessibilityIdentifier("crew-computer-preview")
    }
}

/// The scene's controls in the scroller's content: the first mate's accessibility, each crewmate's touch square and the
/// other computers' names. None of it observes a display tick; the drawing is `PhoneSceneSurface`'s, on its own thread.
struct PhoneSceneControls: View {
    let roster: PhoneSceneRoster
    let crew: PhoneSceneMotion
    let state: PhoneCharacter.State
    let observed: Bool
    let offset: CGSize
    @Binding var preview: PhoneTask?
    @Binding var computerPreview: String?
    @Binding var previewComputer: String?
    var selection: String? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            PhoneSceneTouches(crew: crew, roster: roster, offset: offset, selection: selection) { task, computer in
                preview = task; previewComputer = computer; computerPreview = nil
            }
            Color.clear.frame(width: 280, height: 280)
                .accessibilityElement(children: .ignore).accessibilityLabel("Your first mate")
                .accessibilityValue(observed ? state.rawValue : "Activity unknown").accessibilityIdentifier("phone-character")
                .position(x: roster.homeX + offset.width, y: roster.height / 2 + offset.height)
                .allowsHitTesting(false)
            if roster.computers.count > 1 {
                ForEach(roster.computers) { computer in
                    VStack(spacing: 2) {
                        Button(computer.name) { preview = nil; computerPreview = computer.id }
                            .font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary).frame(minWidth: 44, minHeight: 44)
                            .accessibilityIdentifier("crew-computer-" + computer.id)
                        if !computer.reachable { Text("Activity unknown").font(PhoneFont.caption).foregroundStyle(PhoneTheme.muted) }
                    }.position(x: computer.x + offset.width, y: roster.height / 2 + computer.radius + 24 + offset.height)
                }
            }
        }
    }
}

/// INF-1066: each crewmate answers touch across its 44-point square, except where another crewmate's center is nearer,
/// so overlapping squares never let a neighbor take a tap aimed at a crewmate's own center.
struct PhoneTouchCell: Shape {
    let center: CGPoint
    let neighbors: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var polygon = [CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
                       CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY)]
        let mid = CGPoint(x: rect.midX, y: rect.midY)
        for other in neighbors {
            let n = CGVector(dx: other.x - center.x, dy: other.y - center.y)
            let reach = n.dx * n.dx + n.dy * n.dy
            if reach == 0 || reach > 2 * rect.width * rect.width { continue }
            // Keep the half nearer this center: (p - mid) · n <= |n|² / 2.
            let side = { (p: CGPoint) in (p.x - mid.x) * n.dx + (p.y - mid.y) * n.dy - reach / 2 }
            var kept: [CGPoint] = []
            for (i, a) in polygon.enumerated() {
                let b = polygon[(i + 1) % polygon.count], sa = side(a), sb = side(b)
                if sa <= 0 { kept.append(a) }
                if (sa < 0) != (sb < 0) && sa != sb {
                    let t = sa / (sa - sb)
                    kept.append(CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
                }
            }
            polygon = kept
        }
        var path = Path()
        if !polygon.isEmpty { path.addLines(polygon); path.closeSubpath() }
        return path
    }
}

/// INF-1066: SwiftUI shortcuts for unmodified arrows, Tab and Space lose to the system's focus and text handling.
/// While browsing, a scene-owned responder takes first-responder status and offers them as priority key commands;
/// it resigns as soon as browsing stops, so previews, records, editing, leaving and backgrounding get the keys back.
struct PhoneBrowsingKeys: UIViewRepresentable {
    enum Key: CaseIterable { case left, right, up, down, next, open, stop }
    let active: Bool
    let handle: (Key) -> Void

    func makeUIView(context: Context) -> Responder { Responder() }
    func updateUIView(_ view: Responder, context: Context) {
        view.handle = handle
        view.active = active
        view.sync()
    }
    static func dismantleUIView(_ view: Responder, coordinator: ()) {
        view.active = false
        view.sync()
    }

    final class Responder: UIView {
        var handle: (Key) -> Void = { _ in }
        var active = false
        override var canBecomeFirstResponder: Bool { active }
        override func didMoveToWindow() { super.didMoveToWindow(); sync() }
        func sync() {
            if active, window != nil, !isFirstResponder { becomeFirstResponder() }
            else if !active, isFirstResponder { resignFirstResponder() }
        }
        override var keyCommands: [UIKeyCommand]? {
            guard active else { return nil }
            return Key.allCases.map { key in
                let input: String
                switch key {
                case .left: input = UIKeyCommand.inputLeftArrow
                case .right: input = UIKeyCommand.inputRightArrow
                case .up: input = UIKeyCommand.inputUpArrow
                case .down: input = UIKeyCommand.inputDownArrow
                case .next: input = "\t"
                case .open: input = " "
                case .stop: input = UIKeyCommand.inputEscape
                }
                let command = UIKeyCommand(input: input, modifierFlags: [], action: #selector(press(_:)))
                command.wantsPriorityOverSystemBehavior = true
                return command
            }
        }
        @objc private func press(_ command: UIKeyCommand) {
            let key: Key?
            switch command.input {
            case UIKeyCommand.inputLeftArrow: key = .left
            case UIKeyCommand.inputRightArrow: key = .right
            case UIKeyCommand.inputUpArrow: key = .up
            case UIKeyCommand.inputDownArrow: key = .down
            case "\t": key = .next
            case " ": key = .open
            case UIKeyCommand.inputEscape: key = .stop
            default: key = nil
            }
            if let key { handle(key) }
        }
    }
}

/// The scroller's latest offset, kept outside SwiftUI's observation so a pan never re-runs the scene's body.
final class PanReading {
    var point = CGPoint.zero
}
