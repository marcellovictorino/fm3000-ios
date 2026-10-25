import FM3000Core
import FM3000Model
import SwiftUI

struct CardsView: View {
    @ObservedObject var model: AppModel
    @State private var path: [String] = []
    @State private var filter: CardsFilter? = DebugLaunch.has("-filterQueued") ? .queued : nil

    private var shown: [Card] { filterCards(model.cards, by: filter, board: model.board) }
    /// Under Working or Queued the list holds tasks (what those chips count), not cards.
    private var shownTasks: [BoardTask] { filter.map { tasksIn($0, board: model.board) } ?? [] }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let filter, filter != .waiting, !shownTasks.isEmpty {
                    List(shownTasks) { task in
                        NavigationLink { TaskDetailView(model: model, task: task) } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                ModelPill(name: model.modelName(for: task))
                                Text(task.title).font(.headline)
                                Text("\(task.key) · \(Self.title(filter))\(task.activity.map { " · " + $0 } ?? "")").font(.caption).foregroundStyle(Theme.fg3)
                            }
                        }
                        .infinitaryRow()
                    }
                    .infinitaryScreen()
                    .refreshable { await model.refreshBoard() }
                } else if shown.isEmpty, let filter {
                    VStack(spacing: 6) {
                        Text(filter == .waiting ? "No decision cards wait on you" : "Nothing is \(Self.title(filter).lowercased())").font(.headline)
                        Text("Tap the chip again to see every card.").font(.footnote).foregroundStyle(Theme.fg2)
                    }.padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if model.cards.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle").font(.largeTitle).foregroundStyle(Theme.fg2)
                        Text("Nothing waits for you").font(.headline)
                        Text("Cards from Infinitary appear here the moment they are raised.").font(.footnote).foregroundStyle(Theme.fg2)
                    }.padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(shown) { card in
                        NavigationLink(value: card.id) {
                            VStack(alignment: .leading, spacing: 4) {
                                ModelPill(name: model.modelName(for: card))
                                Text(card.title).font(.headline)
                                Text(HTMLText.plain(card.body)).font(.subheadline).foregroundStyle(Theme.fg2).lineLimit(2)
                                Text("\(card.meta) · \(relativeTime(card.createdAt))").font(.caption).foregroundStyle(Theme.fg3)
                            }
                        }
                        .infinitaryRow()
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { Task { _ = await model.close(card) } } label: { Label("Close", systemImage: "xmark") }
                                .tint(.red)
                        }
                    }
                    .infinitaryScreen()
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    StatusBanner(model: model)
                    KPIStrip(tally: CardsTally(cards: model.cards, board: model.board), filter: $filter)
                }
            }
            .task { await model.refreshBoard() }
            .onChange(of: model.phase) { phase in if case .connected = phase { Task { await model.refreshBoard() } } }
            .navigationTitle("Cards").iOSInlineTitle()
            .onChange(of: model.cards.count) { _ in
                if DebugLaunch.has("-openCard"), path.isEmpty, let first = model.cards.first { path = [first.id] }
            }
            .navigationDestination(for: String.self) { id in
                if let card = model.cards.first(where: { $0.id == id }) ?? model.answered[id]?.card { CardDetailView(model: model, card: card) }
                else { Text("This card was answered.").foregroundStyle(Theme.fg2) }
            }
        }
    }
}

extension CardsView {
    fileprivate static func title(_ filter: CardsFilter) -> String {
        switch filter { case .working: "Working"; case .waiting: "Waiting on you"; case .queued: "Queued" }
    }
}

/// One thin line of chips above the cards: how many tasks are Working, how many decision cards wait on you, how many are Queued,
/// counted as the desktop counts them. A tap filters the list to that chip; a second tap clears it.
private struct KPIStrip: View {
    let tally: CardsTally
    @Binding var filter: CardsFilter?

    var body: some View {
        HStack(spacing: 6) {
            chip(.working, "Working", tally.working)
            chip(.waiting, "Waiting on you", tally.waiting)
            chip(.queued, "Queued", tally.queued)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 5)
        .background(Theme.bg1)
    }

    private func chip(_ kind: CardsFilter, _ label: String, _ count: Int) -> some View {
        let on = filter == kind
        return Button { filter = on ? nil : kind } label: {
            HStack(spacing: 4) {
                Text(label)
                Text("\(count)").fontWeight(.semibold).monospacedDigit()
            }
            .font(.caption2)
            .foregroundStyle(on ? Theme.bg0 : (kind == .waiting && count > 0 ? Theme.accent : Theme.fg2))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(on ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.bg2), in: Capsule())
            .overlay(Capsule().stroke(Theme.line.opacity(on ? 0 : 0.7), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) \(count)")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// The card on its own: its message and actions, then one row that opens the thread. The thread has its own screen.
struct CardDetailView: View {
    @ObservedObject var model: AppModel
    let card: Card
    @State private var showThread = DebugLaunch.has("-openThread")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ModelPill(name: model.modelName(for: card))
                Text(card.meta).font(.caption).foregroundStyle(Theme.fg2)
                CardBody(html: card.body)
                if card.status == "streaming" { ProgressView("Still being written…") }
                if let done = model.answered[card.id] {
                    Label { Text("You chose \(done.label). This card is closed.") } icon: { Image(systemName: "checkmark.circle.fill") }
                        .font(.subheadline.weight(.medium)).foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                        .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else if !card.actions.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(card.actions) { action in
                            let sending = model.choosing[card.id] == action.id
                            Button { Task { await model.choose(action, on: card) } } label: {
                                HStack(spacing: 8) {
                                    if sending { ProgressView().controlSize(.small) }
                                    Text(sending ? "Sending…" : action.label)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(action.variant == "danger" ? Theme.danger : (action.isDefault ? Theme.accentStrong : Theme.bg3))
                            .disabled(!model.canChange || model.choosing[card.id] != nil)
                            .opacity(model.choosing[card.id] != nil && !sending ? 0.5 : 1)
                        }
                    }
                }
                NavigationLink {
                    CardThreadView(model: model, card: card)
                } label: {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                        Text(repliesLabel((model.threads[card.id] ?? []).count))
                        Spacer()
                        Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Theme.fg3)
                    }
                    .padding(14)
                    .background(Theme.bg2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(Theme.backdrop)
        .navigationTitle(card.title)
        .iOSInlineTitle()
        .navigationDestination(isPresented: $showThread) { CardThreadView(model: model, card: card) }
        .toolbar { ToolbarItem(placement: .primaryAction) { ListenButton(text: card.title + ". " + HTMLText.plain(card.body), id: "card-" + card.id) } }
        .onDisappear { Speaker.shared.stop() }
        .task { await model.loadThread(of: card) }
    }
}

/// A card's thread as a chat: history scrolls up and down, the newest at the bottom, the composer pinned below.
struct CardThreadView: View {
    @ObservedObject var model: AppModel
    let card: Card
    @State private var reply = ""
    @State private var sending = false
    @State private var attachments: [Attachment] = []

    var body: some View {
        ChatList(items: (model.threads[card.id] ?? []).map(\.chatItem), empty: "No replies yet. Write the first one below.", typing: model.awaitingThreads.contains(card.id) || DebugLaunch.has("-typing"))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.isClosed(card) {
                VStack(spacing: 8) {
                    Text(model.answered[card.id].map { "You chose \($0.label), so this card and its thread are closed." } ?? "This card is closed, so its thread takes no more replies.")
                        .font(.footnote).foregroundStyle(Theme.fg2).multilineTextAlignment(.center)
                    Button { model.requestedTab = 1 } label: { Label("Message Firstmate instead", systemImage: "bubble.left") }
                        .buttonStyle(.borderedProminent).tint(Theme.accentStrong)
                }
                .padding(12).frame(maxWidth: .infinity).background(Theme.bg1.ignoresSafeArea(edges: .bottom))
            } else {
                Composer(placeholder: "Reply", text: $reply, attachments: $attachments, enabled: model.canChange, sending: sending) {
                    let words = reply, files = attachments
                    sending = true
                    Task {
                        if await model.reply(words, to: card, attachments: files) { reply = ""; attachments = [] }
                        sending = false
                    }
                }
            }
        }
        .navigationTitle("Thread")
        .iOSInlineTitle()
        .task { await model.loadThread(of: card) }
    }
}
