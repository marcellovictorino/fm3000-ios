import InfinitaryKit
import PhotosUI
import SwiftUI

struct PhoneCards: View {
    let session: ReadOnlySession
    @Environment(PhoneMessageContext.self) private var messageContext
    @State private var selected: String?
    @State private var past: PhoneCard?
    @State private var drafts: [String: PhoneJSON] = [:]
    @State private var replies: [String: String] = [:]
    @State private var previousIDs: [String] = []
    @State private var sent = 0
    /// INF-1524, the captain's yes on iPad only: the card takes the stage's whole width, as the Mac's maximize does.
    @State private var maximized = false
    private var card: PhoneCard? { past ?? session.stack.first(where: { $0.id == selected }) ?? session.stack.first }

    var body: some View {
        VStack(spacing: PhoneTheme.space3) {
            if let card {
                PhoneCardPane(card: card, session: session,
                    fill: card.isPast ? card.value["answers"] : drafts[card.id] ?? .array([]),
                    reply: Binding(get: { replies[card.id] ?? "" }, set: { replies[card.id] = $0 }),
                    onReading: { drafts[card.id] = $0["answers"] },
                    onSeen: { session.markSeen(card) },
                    onHide: { past = nil },
                    onPage: { page($0) },
                    onSent: { sent += 1 },
                    showsNext: past == nil && index < session.stack.count - 1, visible: messageContext.cardsVisible,
                    replyLeaves: !card.value["holdsPlace"].flag && session.stack.count > 1,
                    maximized: $maximized,
                    onTask: { messageContext.openTask = $0 }, onDraft: { messageContext.draft = $0 })
                    .id("\(card.id):\(card.offerID ?? card.body):\(card.isPast)")
            } else {
                // INF-1060 keeps the empty stage free of placeholder words; INF-1066 adds its native crew.
                PhoneCrewScene(session: session)
                    .frame(maxWidth: .infinity, maxHeight: .infinity).padding(.vertical, PhoneTheme.space5)
            }
            // INF-589 item 11: with no card to page, the pager hides. INF-1517: cards put aside wait in Tasks, as on the Mac.
            if !session.stack.isEmpty { pager }
        }
        .padding(.horizontal, PhoneTheme.space4).frame(maxWidth: card == nil || maximized ? .infinity : PhoneColumn.width).frame(maxWidth: .infinity)
        .background(PhoneTheme.background)
        .phoneSwipePaging(previous: canPagePrevious ? { page(-1) } : nil, next: canPageNext ? { page(1) } : nil)
        // INF-589 item 12: a soft tap once the computer accepts an answer or a reply; never on a page turn.
        .sensoryFeedback(.phone, trigger: sent)
        .onChange(of: card.map { $0.isPast ? PhoneMessageContext.Card.past($0.id) : .current($0.id) }, initial: true) { _, shown in
            messageContext.card = shown
        }
        .onChange(of: session.stack.map(\.id), initial: true) { _, ids in
            if let marked = session.stack.first(where: { !previousIDs.contains($0.id) && $0.value["holdsPlace"].flag }) {
                selected = marked.id; past = nil
            } else if selected == nil || !ids.contains(selected!) {
                selected = session.stack.first(where: { !session.seenCards.contains($0.offerID ?? $0.id) })?.id ?? ids.first
            }
            showRestored(ids)
            previousIDs = ids
            if let past, ids.contains(past.id) { self.past = nil }
        }
        .onChange(of: messageContext.restoring) { _, _ in showRestored(session.stack.map(\.id)) }
        .onChange(of: session.showCardID, initial: true) { _, id in
            guard let id else { return }
            if session.stack.contains(where: { $0.id == id }) { selected = id; past = nil }
            else { past = session.pastCards.first { $0.id == id } }
            session.showCardID = nil
        }
    }
    private var pager: some View {
        HStack(spacing: PhoneTheme.space2) {
            Button { page(-1) } label: { Label("Previous card", systemImage: "chevron.left").labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44) }
                .disabled(!canPagePrevious).accessibilityIdentifier("previous-card")
            Menu {
                ForEach(session.stack) { item in
                    Button(item.title) { selected = item.id; past = nil }
                }
            } label: {
                Text(past != nil ? "Past card" : "\(index + 1) of \(session.stack.count)")
                    .font(.custom("JetBrainsMono-Regular", size: 12, relativeTo: .caption))
                    .frame(minWidth: 44, minHeight: 44)
            }.accessibilityIdentifier("card-pager")
            Button { page(1) } label: {
                Label("Next card", systemImage: "chevron.right").labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                    .overlay(alignment: .topTrailing) {
                        if session.stack.dropFirst(index + 1).contains(where: { !session.seenCards.contains($0.offerID ?? $0.id) }) {
                            Circle().fill(PhoneTheme.accent).frame(width: 6, height: 6).accessibilityHidden(true)
                        }
                    }
            }
                .disabled(!canPageNext).accessibilityIdentifier("next-card")
            // INF-1524, the captain's pick: on Home a new card is counted here rather than in a pill over the stage.
            if !fresh.isEmpty {
                Button { selected = fresh[0].id; past = nil } label: {
                    Text("\(fresh.count) new").font(PhoneFont.mono).foregroundStyle(PhoneTheme.accent).frame(minHeight: 44)
                }.accessibilityIdentifier("card-new")
            }
        }
        .background {
            PhonePagerKeys(previous: canPagePrevious ? { page(-1) } : nil, next: canPageNext ? { page(1) } : nil)
                .frame(width: 0, height: 0)
        }
    }
    /// The cards on the stack not yet read, besides the one shown.
    private var fresh: [PhoneCard] {
        session.stack.filter { $0.id != card?.id && !session.seenCards.contains($0.offerID ?? $0.id) }
    }
    private var index: Int { session.stack.firstIndex { $0.id == (selected ?? session.stack.first?.id) } ?? 0 }
    private var canPagePrevious: Bool { past == nil && index > 0 }
    private var canPageNext: Bool { past == nil && index < session.stack.count - 1 }
    /// A card a Tasks row brought back shows once its return reaches the stack, whichever arrives first.
    private func showRestored(_ ids: [String]) {
        guard let id = messageContext.restoring, ids.contains(id) else { return }
        selected = id; past = nil; messageContext.restoring = nil
    }
    private func page(_ delta: Int) {
        let next = index + delta
        if session.stack.indices.contains(next) { selected = session.stack[next].id; past = nil }
    }
}

/// INF-1753: Shift-Command-[ and Shift-Command-] page the stage, as `cards.previous` and `cards.next` do on the Mac,
/// and like them never repeat while held. A page turn builds the next card's web view, which on a busy iPad held the
/// main thread past UIKit's key repeat delay, so a SwiftUI shortcut turned a second page before the key-up arrived.
/// The chords are UIKit key commands that never repeat (iOS 26 and later), kept on the window's root view controller
/// beside SwiftUI's own shortcuts while the pager is in the window.
struct PhonePagerKeys: UIViewRepresentable {
    let previous: (() -> Void)?
    let next: (() -> Void)?

    func makeUIView(context: Context) -> Anchor { Anchor() }
    func updateUIView(_ anchor: Anchor, context: Context) {
        anchor.previousPage = previous
        anchor.nextPage = next
    }

    final class Anchor: UIView {
        fileprivate static weak var shown: Anchor?
        var previousPage: (() -> Void)?
        var nextPage: (() -> Void)?
        private weak var owner: UIViewController?
        private let commands = [("[", "Previous card", -1), ("]", "Next card", 1)].map { input, title, delta in
            let command = UIKeyCommand(title: title, action: #selector(UIApplication.infinitaryPageCard(_:)), input: input,
                                       modifierFlags: [.command, .shift], propertyList: delta)
            if #available(iOS 26, *) { command.repeatBehavior = .nonRepeatable }
            return command
        }
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let owner { commands.forEach(owner.removeKeyCommand) }
            owner = window?.rootViewController
            if let owner { commands.forEach(owner.addKeyCommand) }
            if window != nil { Self.shown = self } else if Self.shown === self { Self.shown = nil }
        }
        fileprivate func press(_ command: UIKeyCommand) {
            // A sheet keeps the pager's chords from the stage behind it.
            guard owner?.presentedViewController == nil, let delta = command.propertyList as? Int else { return }
            (delta < 0 ? previousPage : nextPage)?()
        }
    }
}

extension UIApplication {
    /// The pager's chords sit on the root view controller, so their action travels up the responder chain from wherever
    /// focus is; the application ends every such chain.
    @objc fileprivate func infinitaryPageCard(_ command: UIKeyCommand) { PhonePagerKeys.Anchor.shown?.press(command) }
}

private struct PhoneCardPane: View {
    let card: PhoneCard
    let session: ReadOnlySession
    @Binding var reply: String
    let onReading: (PhoneJSON) -> Void
    let onSeen: () -> Void
    let onHide: () -> Void
    let onPage: (Int) -> Void
    let onSent: () -> Void
    let showsNext: Bool
    /// The stage is on screen: a card drawn behind another tab is not yet read.
    let visible: Bool
    let replyLeaves: Bool
    @Binding var maximized: Bool
    let onTask: (String) -> Void
    let onDraft: (String) -> Void
    @State private var surfaceHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    /// The body runs on below the choices, so a hairline separates them, as on the Mac.
    @State private var runsOn = false
    /// The height the stage offers the card, and its head's and choices' own heights.
    @State private var paneHeight: CGFloat = 0
    @State private var headHeight: CGFloat = 0
    @State private var footHeight: CGFloat = 0
    @State private var host: CardWebHost
    /// INF-1524: a settle card's fact strip, drawn read-only beside its choices once the body has split it off.
    @State private var factsHost: CardWebHost?
    @State private var problem: String?
    @State private var threadOpen = false
    /// The "You asked" line is open; held here because a taller head moves into or out of the scroller.
    @State private var askedOpen = false
    @State private var retry = 0
    /// INF-1524: the choice pressed and still on its way, which shows its pending mark.
    @State private var pending: String?
    @State private var closeAsk: CloseAsk?
    @State private var photos: [PhonePhoto] = []
    @State private var photoSelection: [PhotosPickerItem] = []
    @State private var libraryOpen = false
    @State private var cameraOpen = false
    @Environment(\.scenePhase) private var phase
    @Environment(\.openURL) private var openURL
    @FocusState private var replyFocused: Bool

    /// What the close asks first (the Mac's CloseQuestion): about unsent picks or words, about a reply still unanswered, or both.
    struct CloseAsk { let words: String; let picks: Bool }

    init(card: PhoneCard, session: ReadOnlySession, fill: PhoneJSON, reply: Binding<String>,
         onReading: @escaping (PhoneJSON) -> Void, onSeen: @escaping () -> Void, onHide: @escaping () -> Void, onPage: @escaping (Int) -> Void, onSent: @escaping () -> Void, showsNext: Bool, visible: Bool, replyLeaves: Bool,
         maximized: Binding<Bool>, onTask: @escaping (String) -> Void, onDraft: @escaping (String) -> Void) {
        self.card = card; self.session = session; _reply = reply
        self.onReading = onReading; self.onSeen = onSeen; self.onHide = onHide; self.onPage = onPage; self.onSent = onSent
        self.showsNext = showsNext; self.visible = visible; self.replyLeaves = replyLeaves
        _maximized = maximized; self.onTask = onTask; self.onDraft = onDraft
        _host = State(initialValue: Self.bodyHost(card, session, fill))
    }
    private static func bodyHost(_ card: PhoneCard, _ session: ReadOnlySession, _ fill: PhoneJSON,
                                 heightLag: TimeInterval = 0) -> CardWebHost {
        // The body links the keys of the tasks the phone holds, besides the card's own, as the Mac's does.
        let own = card.value["taskId"].text
        let keys = (session.board?.tasks ?? []).filter { $0.id != own }.map(\.key)
        return CardWebHost(card: card, session: session, fill: fill, keys: keys, heightLag: heightLag)
    }
    private var messages: [PhoneJSON] { card.isPast ? card.value["messages"].list : session.threads[card.id]?["messages"].list ?? [] }
    private var reachable: Bool { session.contact == "in-reach" }
    private var replyWords: String { reply.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSendReply: Bool { !host.changing && session.canChange && host.drawn && replyFits }
    /// The words or photos alone, which the send checks again once its change has begun and the card counts as changing.
    private var replyFits: Bool { reply.utf16.count <= PhoneLimits.reply && (!replyWords.isEmpty || !photos.isEmpty) }
    private var takesReply: Bool { card.takesReplies && !card.isPast }
    /// The task the card is about, which leads its head as its door to the task's record.
    private var task: PhoneTask? {
        guard let id = card.value["taskId"].text ?? card.reviewTaskId else { return nil }
        return session.board?.tasks.first { $0.id == id }
    }
    /// Its author is at work on it: the first mate's turn, or its crewmate's task running.
    private var working: Bool {
        card.isPast ? false : card.author == "firstmate" ? session.firstmateBusy
            : ["running", "starting"].contains(task?.activity ?? "")
    }
    private var asking: Bool { !card.isPast && (host.reading["of"].numeric ?? 0) > 0 }
    /// A closing choice waits until every required question has an answer (the captain's Q2 A on the Mac).
    private var unanswered: Bool { asking && (host.reading["answered"].numeric ?? 0) < (host.reading["of"].numeric ?? 0) }

    private var hasFoot: Bool {
        !card.actions.isEmpty || problem != nil || takesReply || factsHost != nil || !card.value["requiredActions"].list.isEmpty
    }
    /// A short stage, such as an iPhone on its side with a long draft, would leave the body a sliver between its pinned
    /// head and choices; unless the body keeps at least the room they take, the whole card scrolls as it did before.
    @State private var pinsFrame = true
    /// The stage height at which the frame last changed its shape.
    @State private var shapedAt: CGFloat?

    /// Moving the head and choices changes what they measure, and while a rotation animates both places are drawn at once,
    /// so the frame changes its shape at most once for each stage height and never animates the move; otherwise the two
    /// could trade places on every frame and the app would never come to rest.
    /// INF-1524: the reply field sits in the pinned foot, and moving the foot in or out of the scroller makes a new field,
    /// so the keyboard its focus raises, which shortens the stage, never reshapes the frame; the shape settles once it closes.
    private func shapeFrame() {
        guard paneHeight > 0, !replyFocused else { return }
        let pins = paneHeight - headHeight - footHeight >= headHeight + footHeight
        guard pins != pinsFrame, shapedAt != paneHeight else { return }
        shapedAt = paneHeight
        var moved = Transaction()
        moved.disablesAnimations = true
        withTransaction(moved) { pinsFrame = pins }
    }

    private var measuredHead: some View {
        head.padding([.horizontal, .top], PhoneTheme.space4).padding(.bottom, PhoneTheme.space3)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headHeight = $0 }
    }

    private var measuredFoot: some View {
        foot.fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footHeight = $0 }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: PhoneTheme.cardRadius, style: .continuous)
        // INF-944 items 1 and 2, the Mac's shape: the head and the choices stay in the frame, and the body and
        // thread scroll between them in this one native scroller. The body's web view never scrolls on its own.
        VStack(alignment: .leading, spacing: 0) {
            if pinsFrame { measuredHead }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !pinsFrame { measuredHead }
                    content.padding([.horizontal], PhoneTheme.space4).padding(.bottom, PhoneTheme.space4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if hasFoot && !pinsFrame { measuredFoot }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .frame(maxHeight: contentHeight > 0 ? contentHeight : nil)
            .scrollBounceBehavior(.basedOnSize)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.containerSize.height < geometry.contentSize.height - 1
            } action: { _, below in runsOn = below }
            .accessibilityIdentifier("card-scroll")
            .scrollDismissesKeyboard(.interactively)
            if hasFoot && pinsFrame { measuredFoot }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(shape)
        // INF-1524 piece 1: the Mac's raised surface, its edge and shadow outside the clipped content.
        .phoneCardSurface()
        // A frame holding only its scroller is that scroller to accessibility, which then keeps the scroller's name.
        .accessibilityElement(children: .contain).accessibilityIdentifier(pinsFrame ? "card-frame" : "card-scroll")
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { surfaceHeight = $0 }
        .frame(maxHeight: .infinity, alignment: .top)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { paneHeight = $0 }
        .onChange(of: [paneHeight, headHeight, footHeight]) { shapeFrame() }
        .onChange(of: replyFocused) { _, focused in if !focused { shapeFrame() } }
        .background(alignment: .topTrailing) {
            if showsNext {
                // The stack follows the card's frame, which never reaches the pager; the sliver is raised as the card is.
                RoundedRectangle(cornerRadius: PhoneTheme.cardRadius, style: .continuous).fill(.clear)
                    .phoneCardSurface()
                    .frame(width: PhoneTheme.space5)
                    .frame(maxHeight: max(0, surfaceHeight - 2 * PhoneTheme.space3))
                    .padding(.vertical, PhoneTheme.space3)
                    .offset(x: PhoneTheme.space2).accessibilityHidden(true).allowsHitTesting(false)
            }
        }
        .onAppear { connectHost(); readThread(); if let facts = host.facts { showFacts(facts) } }
        .onChange(of: host.facts) { _, facts in if let facts { showFacts(facts) } }
        .onChange(of: session.contact) { _, contact in if contact == "in-reach" { readThread(); markSeen() } }
        .onChange(of: phase) { _, phase in if phase == .active { markSeen() } }
        .onChange(of: visible) { _, visible in if visible { markSeen() } }
        // INF-1524: the thread opens on a new message.
        .onChange(of: messages.count) { before, after in if after > before { threadOpen = true } }
        .sheet(isPresented: Binding(get: { host.presentation != nil }, set: { if !$0 { host.presentation = nil } })) {
            if let presentation = host.presentation { CardMediaView(presentation: presentation, session: session) }
        }
        .alert(PhoneCardWords.closeQuestionTitle, isPresented: Binding(get: { closeAsk != nil }, set: { if !$0 { closeAsk = nil } }),
               presenting: closeAsk) { ask in
            if ask.picks {
                Button(PhoneCardWords.keepAnswering, role: .cancel) {}
                Button(PhoneCardWords.discardAndClose, role: .destructive) { close() }
            } else {
                Button(PhoneCardWords.putAsideInstead) { putAside() }
                Button(PhoneCardWords.closeAnyway, role: .destructive) { close() }
            }
        } message: { ask in Text(ask.words) }
        .photosPicker(isPresented: $libraryOpen, selection: $photoSelection,
                      maxSelectionCount: max(1, PhoneLimits.images - photos.count), matching: .images)
        .task(id: photoSelection) { await loadPhotos() }
        .fullScreenCover(isPresented: $cameraOpen) {
            PhoneCamera { image in
                do { photos.append(try PhonePhoto(bytes: image.jpegData(compressionQuality: 0.95) ?? Data())) }
                catch { problem = error.localizedDescription }
            }.ignoresSafeArea()
        }
    }

    private var head: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                PhoneFlowRow(spacing: PhoneTheme.space2) {
                    kind
                    if card.reviewTaskId != nil {
                        Text(PhoneCardWords.reviewFinding).font(PhoneFont.caption).foregroundStyle(PhoneTheme.warning)
                    }
                    if let task {
                        Button(task.key) { onTask(task.key) }
                            .font(PhoneFont.mono).foregroundStyle(PhoneTheme.secondary).buttonStyle(.plain)
                            .frame(minHeight: 28).contentShape(Rectangle())
                            .accessibilityHint("Opens its record").accessibilityIdentifier("card-task-key")
                    }
                    if let place = card.value["place"].text {
                        Text(place).font(PhoneFont.mono).foregroundStyle(PhoneTheme.secondary).accessibilityIdentifier("card-place")
                    }
                    if let model = card.value["model"].text {
                        Text(model).font(PhoneFont.micro).foregroundStyle(PhoneTheme.secondary)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .overlay { Capsule().strokeBorder(PhoneTheme.line) }
                            .accessibilityIdentifier("card-model")
                    }
                    if card.value["risk"]["declared"] != .null { PhoneRiskDots(declared: card.value["risk"]["declared"]) }
                }
                // The first mate's card names the task it speaks about; a crewmate's own name stays off the head.
                if card.author == "firstmate", let meta = card.meta, meta != "firstmate" {
                    Text(meta).font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
                }
                Text(card.title).font(.custom("SpaceGrotesk-Light", size: 20, relativeTo: .title3).weight(.semibold))
                    .accessibilityIdentifier("card-title")
                if let revised { Text(revised).font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary).accessibilityIdentifier("card-revised") }
                if let asked = card.asked { PhoneAskedLine(asked: asked, open: $askedOpen) }
            }
            Spacer(minLength: PhoneTheme.space2)
            if !card.isPast {
                Button(action: putAside) {
                    Label(PhoneCardWords.putAside, systemImage: "minus")
                        .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
                .accessibilityHint(rest(PhoneCardWords.putAsideRest))
                .accessibilityIdentifier("put-aside-card").disabled(host.changing || !session.canChange)
            }
            if UIDevice.current.userInterfaceIdiom == .pad {
                Button { maximized.toggle() } label: {
                    Label(maximized ? PhoneCardWords.restore : PhoneCardWords.maximize,
                          systemImage: maximized ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }.accessibilityIdentifier("maximize-card")
            }
            Button(action: closeTapped) {
                Label(card.isPast ? "Hide" : "Close", systemImage: "xmark")
                    .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
            }
                .accessibilityHint(card.isPast ? "" : rest(PhoneCardWords.closeRest(task?.key)))
                .accessibilityIdentifier("close-card").disabled(host.changing || (!card.isPast && !session.canChange))
        }
        .contentShape(Rectangle())
        .simultaneousGesture(DragGesture(minimumDistance: 44).onEnded { value in
            // Paging belongs to native chrome, never a body's slider, canvas or pinch gesture.
            if !card.isPast && abs(value.translation.width) > abs(value.translation.height) * 1.5 {
                onPage(value.translation.width < 0 ? 1 : -1)
            }
        })
    }

    /// The words after a control's name in the Mac's rest line ("Close · stays on INF-1's record"), as its VoiceOver hint.
    private func rest(_ line: String) -> String {
        let words = line.components(separatedBy: " · ").dropFirst().joined(separator: " · ")
        return words.prefix(1).uppercased() + words.dropFirst()
    }

    /// The Mac's revised line under the title: when the card last changed, and how much of it.
    private var revised: String? {
        let changes = card.value["changes"]
        guard !card.isPast, changes != .null, let at = changes["at"].numeric else { return nil }
        let date = Date(timeIntervalSince1970: at / 1000)
        let time = date.formatted(date: Calendar.current.isDateInToday(date) ? .omitted : .abbreviated, time: .shortened)
        return PhoneCardWords.revisedLine(time: time, added: Int(changes["added"].numeric ?? 0),
                                          removed: Int(changes["removed"].numeric ?? 0), rewritten: changes["rewritten"].flag)
    }

    @ViewBuilder private var content: some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space4) {
            if card.isPast {
                Text(ending).font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary).accessibilityIdentifier("past-ending")
            }
            if let failure = host.failure {
                Text(failure).foregroundStyle(PhoneTheme.secondary)
                if host.reading["of"].numeric != nil {
                    Text("Choices use the last saved answers. Retry to read the card again.").font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
                }
                Button("Retry") {
                    let fill = host.reading["answers"]; host.close(); problem = nil
                    host = Self.bodyHost(card, session, fill, heightLag: CardWebHost.retriedHeightLag)
                    connectHost(); retry += 1
                }.buttonStyle(PhoneChoiceStyle(.secondary)).disabled(host.changing).accessibilityIdentifier("retry-card")
            } else {
                CardWebView(host: host).frame(height: host.height).id(retry)
            }
            if let notice = host.notice { Text(notice).foregroundStyle(PhoneTheme.warning).accessibilityIdentifier("card-notice") }
            if card.value["attachment"] != .null {
                PhoneBrowserStrip(attachment: card.value["attachment"], session: session) { host.notice = "Do this on \(session.mac.name)." }
            }
            if !messages.isEmpty {
                DisclosureGroup("Thread", isExpanded: $threadOpen) {
                    PhoneCardThread(messages: messages, working: working).padding(.top, PhoneTheme.space3)
                }.accessibilityIdentifier("card-thread")
            }
        }
    }

    /// INF-944 item 5 with the captain's INF-945 pick: the Mac's row, pinned under a hairline while the body runs on beneath.
    /// The Mac's footer order (footerGroups.ts): the default is drawn last, at the trailing edge.
    private var footerOrder: [PhoneJSON] {
        card.actions.filter { !$0["default"].flag } + card.actions.filter { $0["default"].flag }
    }

    /// The Mac's footerVariant: the action's own variant, else primary for the default. The default waits muted while a
    /// required question has no answer.
    private func footerKind(_ action: PhoneJSON) -> PhoneChoiceStyle.Kind {
        if unanswered && action["default"].flag { return .muted }
        switch action["variant"].text {
        case "primary": return .primary
        case "danger": return .danger
        case "secondary", "ghost": return action["danger"].flag ? .danger : .secondary
        default: return action["danger"].flag ? .danger : action["default"].flag ? .primary : .secondary
        }
    }

    private var chosenID: PhoneJSON? { card.isPast && card.value["ending"]["how"].text != "closed" ? card.value["ending"]["actionId"] : nil }

    private var foot: some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space2) {
            // INF-1524 piece 3: a merge card's facts and what to do after merging stay with its choices.
            if let factsHost, factsHost.failure == nil {
                CardWebView(host: factsHost).frame(height: factsHost.height)
            }
            let required = card.value["requiredActions"].list
            if !required.isEmpty { PhoneRequiredActions(actions: required) }
            if let problem { Text(problem).foregroundStyle(PhoneTheme.warning).accessibilityIdentifier("card-error") }
            if takesReply { replyField }
            if card.isPast, let words = sentWords {
                Text("\(PhoneCardWords.sentWithChoice) \(words)").font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
                    .accessibilityIdentifier("past-sent-words")
            }
            if !card.actions.isEmpty {
                PhoneChoiceRow {
                    if asking, let count = host.reading["of"].numeric {
                        Text(PhoneCardWords.answersLine(answered: Int(host.reading["answered"].numeric ?? 0), of: Int(count),
                                                        changed: Int(host.reading["changed"].numeric ?? 0), preview: host.preview))
                            .font(PhoneFont.mono).foregroundStyle(PhoneTheme.secondary)
                            .layoutValue(key: PhoneChoiceRow.Leading.self, value: true)
                    }
                    ForEach(Array(footerOrder.enumerated()), id: \.offset) { _, action in
                        Button { choose(action) } label: {
                            HStack(spacing: 6) {
                                Text(action["label"].text ?? "Choose")
                                if pending != nil && pending == action["id"].text { ProgressView().controlSize(.mini).accessibilityLabel("Sending") }
                            }
                        }
                        .buttonStyle(PhoneChoiceStyle(footerKind(action), chosen: chosenID == action["id"]))
                        .disabled(card.isPast || host.changing || !session.canChange || !host.revealed)
                        .accessibilityValue(chosenID == action["id"] ? "Chosen" : "")
                        .accessibilityIdentifier("card-action-\(action["id"].text ?? "")")
                    }
                }
            }
        }
        .padding(.horizontal, PhoneTheme.space4).padding(.top, PhoneTheme.space2).padding(.bottom, PhoneTheme.space3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { if runsOn && pinsFrame { Rectangle().fill(PhoneTheme.line).frame(height: 1) } }
    }

    /// INF-1524, the captain's picks: the reply field pinned above the choices, its words also going with a choice, and
    /// photos from the library or the camera.
    private var replyField: some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space2) {
            if !photos.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(photos) { photo in
                            Button { photos.removeAll { $0.id == photo.id } } label: {
                                Image(uiImage: photo.image).resizable().scaledToFill()
                                    .frame(width: 44, height: 44).clipped()
                                    .overlay(alignment: .topTrailing) { Image(systemName: "xmark.circle.fill").foregroundStyle(PhoneTheme.text, PhoneTheme.surface) }
                            }.accessibilityLabel("Remove photo").accessibilityIdentifier("reply-photo-chip")
                        }
                    }
                }
            }
            HStack(alignment: .bottom, spacing: 0) {
                Menu {
                    Button { libraryOpen = true } label: { Label("Choose photos", systemImage: "photo.on.rectangle") }
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button { cameraOpen = true } label: { Label("Take photo", systemImage: "camera") }
                    }
                } label: {
                    Label("Add photos", systemImage: "photo").labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }
                .disabled(photos.count >= PhoneLimits.images || host.changing).accessibilityIdentifier("reply-photos")
                TextField(PhoneCardWords.replyHint, text: $reply, axis: .vertical).lineLimit(1...5)
                    .padding(.vertical, PhoneTheme.space2).frame(minHeight: 44)
                    .focused($replyFocused).accessibilityIdentifier("card-reply")
                Button(action: sendReply) {
                    Label("Send reply", systemImage: "arrow.up.circle.fill").labelStyle(.iconOnly).imageScale(.large)
                        .foregroundStyle(canSendReply ? PhoneTheme.accent : PhoneTheme.muted)
                        .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }.accessibilityIdentifier("send-reply")
                    .disabled(!canSendReply)
            }.phoneInput()
                // INF-589 item 11: the line under the composer says why; the reply row only dims.
                .opacity(session.canChange ? 1 : 0.5)
            if reply.utf16.count > PhoneLimits.reply { Text("Keep your reply within \(PhoneLimits.reply.formatted()) characters.").foregroundStyle(PhoneTheme.warning) }
        }
    }

    private var kind: some View {
        let attention = !card.isPast && card.author == "host"
        return Text(card.isPast ? "Past" : attention ? "Attention" : card.actions.isEmpty ? "Note" : "Decision")
            .font(.custom("JetBrainsMono-Regular", size: 11, relativeTo: .caption2))
            .foregroundStyle(attention ? PhoneTheme.danger : card.actions.isEmpty || card.isPast ? PhoneTheme.secondary : PhoneTheme.accent)
            .padding(.horizontal, PhoneTheme.space2).padding(.vertical, 4)
            .background(PhoneTheme.background, in: RoundedRectangle(cornerRadius: PhoneTheme.controlRadius))
    }
    private var ending: String {
        let end = card.endingForWords
        let words = PhonePastEnding.words(end)
        guard let at = end["at"].numeric else { return words }
        return "\(words) · \(Date(timeIntervalSince1970: at / 1000).formatted(date: .abbreviated, time: .shortened))"
    }
    /// The words a past card's choice carried from its field (the Mac's anythingElseOf).
    private var sentWords: String? {
        let words = card.value["answers"].list.first { $0["name"].text == PhoneCardWords.anythingElse }?["written"].text
        return words?.isEmpty == false ? words : nil
    }
    private func onMac(_ action: PhoneJSON) -> Bool {
        let effect = action["effect"]
        return (effect["kind"].text == "open" && !(effect["target"].text == "browser" && effect["savedSignIn"].flag))
            || (effect["kind"].text == "host" && effect["op"].text == "restore-account")
    }

    private func choose(_ action: PhoneJSON) {
        if onMac(action) { host.notice = "Do this on \(session.mac.name)."; return }
        let id = action["id"].text
        perform(closesCard: true) {
            pending = id
            defer { pending = nil }
            let snapshot = try await host.submissionReading()
            let reading = snapshot.value
            guard !action["default"].flag || reading["answered"] == reading["of"] else {
                throw PhoneRequestError("Answer each required question first.")
            }
            // INF-1524: the field's words go with the choice as its anything-else answer, as the Mac's withAnythingElse sends them.
            let words = replyWords
            var answers = reading["answers"].list.filter { $0["name"].text != PhoneCardWords.anythingElse }
            if !words.isEmpty {
                answers.append(.object(["name": .string(PhoneCardWords.anythingElse), "values": .array([]),
                                        "changed": .bool(true), "written": .string(words)]))
            }
            let result = try await session.ask(.act, [.string(card.id), action["id"], .string("chrome"),
                .object(["answers": .array(answers)]), card.submission(reading: reading, fresh: snapshot.fresh)])
            if let refusal = result["refusal"].text { throw PhoneRequestError(refusal) }
            if replyWords == words { reply = "" }
            onSent()
        }
    }

    private func sendReply() {
        perform {
            let text = reply, sent = photos
            guard replyFits else { return }
            let snapshot = try await host.submissionReading()
            let reading = snapshot.value
            var payload: [String: PhoneJSON] = ["text": .string(text), "answers": reading["answers"]]
            if !sent.isEmpty {
                payload["images"] = .array(sent.map { photo in .object(photo.wire.mapValues(PhoneJSON.string)) })
            }
            _ = try await session.ask(.reply, [.string(card.id), .object(payload),
                card.submission(reading: reading, fresh: snapshot.fresh), .bool(replyLeaves)])
            if reply == text { reply = "" }
            photos.removeAll { photo in sent.contains { $0.id == photo.id } }
            threadOpen = true; replyFocused = false; onSent()
        }
    }

    private func closeTapped() {
        if card.isPast { onHide(); return }
        // The Mac's CloseQuestion: unsent picks or words, and a reply its author has not answered yet.
        let count = Int((host.preview ? host.reading["changed"] : host.reading["picked"]).numeric ?? 0)
        let wrote = !replyWords.isEmpty
        let waiting = card.awaiting == "answer" || messages.last?["who"].text == "captain"
        let picks = count > 0 || wrote
        guard picks || waiting else { close(); return }
        let author = card.author == "firstmate" ? "your first mate" : task?.assignee ?? "the crewmate"
        let words = (picks ? [PhoneCardWords.closeQuestion(count: count, preview: host.preview, wrote: wrote)] : [])
            + (waiting ? [PhoneCardWords.unansweredReply(author: author, key: task?.key)] : [])
        closeAsk = CloseAsk(words: words.joined(separator: " "), picks: picks)
    }
    private func close() {
        perform(closesCard: true) { _ = try await session.ask(.close, [.string(card.id), card.submission()]) }
    }
    /// Put aside: the Mac's minimize. The card leaves the stack and comes back when it changes.
    private func putAside() {
        perform(closesCard: true) { _ = try await session.ask(.minimize, [.string(card.id), .bool(true)]) }
    }

    private func perform(closesCard: Bool = false, _ operation: @escaping @MainActor () async throws -> Void) {
        let activeHost = host
        guard activeHost.beginChange() else { return }
        problem = nil
        Task {
            defer { activeHost.busy = false }
            do { try await operation(); if closesCard { activeHost.chosen = true } }
            catch { problem = error.localizedDescription }
        }
    }
    private func connectHost() {
        host.onReading = onReading; host.onDrawn = markSeen
        host.onLink = { url in openURL(url) }
        host.onDraft = onDraft
        host.onTask = onTask
    }
    /// The fact strip the body split off, drawn by a host of its own that holds only it and takes no answers.
    private func showFacts(_ facts: String) {
        guard factsHost == nil, case .object(var value) = card.value else { return }
        value["body"] = .string(facts); value["actions"] = .array([]); value["changes"] = .null
        guard let strip = try? PhoneCard(.object(value)) else { return }
        let factsHost = CardWebHost(card: strip, session: session, fill: .array([]), part: .facts)
        factsHost.onLink = { url in openURL(url) }
        self.factsHost = factsHost
    }
    private func markSeen() {
        guard !card.isPast, host.drawn, reachable, visible, phase == .active else { return }
        onSeen()
        if let offer = card.offerID { Task { _ = try? await session.ask(.seen, [.string(card.id), .string(offer)]) } }
    }
    private func readThread() {
        guard !card.isPast, reachable else { return }
        Task { do { try await session.readThread(card.id) } catch { problem = error.localizedDescription } }
    }
    private func loadPhotos() async {
        guard !photoSelection.isEmpty else { return }
        defer { photoSelection = [] }
        for item in photoSelection {
            do {
                guard photos.count < PhoneLimits.images, let bytes = try await item.loadTransferable(type: Data.self) else {
                    throw PhoneError.refused("Could not add this photo. Choose another.")
                }
                photos.append(try PhonePhoto(bytes: bytes))
            } catch is CancellationError { return }
            catch { problem = error.localizedDescription }
        }
    }
}

/// INF-1610, the Mac's "You asked" line: when the captain sent the message the card is about, and their words.
/// A long message shows its start, cut after two lines; Show all opens the whole of it, and Show less folds it.
/// The card holds whether it is open: opening it can move the head into or out of the scroller, a new line.
private struct PhoneAskedLine: View {
    let asked: PhoneAsked
    @Binding var open: Bool
    @State private var folded: CGFloat = 0
    @State private var whole: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            (Text(asked.label()).font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted)
                + Text("  ") + Text(asked.words(open: open)).font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary))
                .lineLimit(open ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { folded = $0 }
                .background(alignment: .topLeading) {
                    // The whole message, unseen, so the line knows whether two lines cut it.
                    (Text(asked.label()).font(PhoneFont.micro) + Text("  ") + Text(asked.words(open: false)).font(PhoneFont.caption))
                        .fixedSize(horizontal: false, vertical: true).hidden()
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { whole = $0 }
                }
                .accessibilityIdentifier("card-asked")
            if open || whole > folded + 1 {
                Button(open ? "Show less" : "Show all") { open.toggle() }
                    .font(PhoneFont.micro).foregroundStyle(PhoneTheme.accent)
                    .frame(minHeight: 44, alignment: .leading).contentShape(Rectangle())
                    .accessibilityIdentifier("card-asked-toggle")
            }
        }
    }
}
