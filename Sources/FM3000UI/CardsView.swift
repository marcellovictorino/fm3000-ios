import FM3000Core
import FM3000Model
import SwiftUI

struct CardsView: View {
    @ObservedObject var model: AppModel
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if model.cards.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle").font(.largeTitle).foregroundStyle(Theme.fg2)
                        Text("Nothing waits for you").font(.headline)
                        Text("Cards from Infinitary appear here the moment they are raised.").font(.footnote).foregroundStyle(Theme.fg2)
                    }.padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(model.cards) { card in
                        NavigationLink(value: card.id) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.title).font(.headline)
                                Text(HTMLText.plain(card.body)).font(.subheadline).foregroundStyle(Theme.fg2).lineLimit(2)
                                Text("\(card.meta) · \(relativeTime(card.createdAt))").font(.caption).foregroundStyle(Theme.fg3)
                            }
                        }
                        .infinitaryRow()
                    }
                    .infinitaryScreen()
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) { StatusBanner(model: model) }
            .navigationTitle("Cards").iOSInlineTitle()
            .onChange(of: model.cards.count) { _ in
                if DebugLaunch.has("-openCard"), path.isEmpty, let first = model.cards.first { path = [first.id] }
            }
            .navigationDestination(for: String.self) { id in
                if let card = model.cards.first(where: { $0.id == id }) { CardDetailView(model: model, card: card) }
                else { Text("This card was answered.").foregroundStyle(Theme.fg2) }
            }
        }
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
                Text(card.meta).font(.caption).foregroundStyle(Theme.fg2)
                CardBody(html: card.body)
                if card.status == "streaming" { ProgressView("Still being written…") }
                if !card.actions.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(card.actions) { action in
                            Button { Task { await model.choose(action, on: card) } } label: {
                                Text(action.label).frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(action.variant == "danger" ? Theme.danger : (action.isDefault ? Theme.accentStrong : Theme.bg3))
                            .disabled(!model.canChange)
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
        ChatList(items: (model.threads[card.id] ?? []).map(\.chatItem), empty: "No replies yet. Write the first one below.")
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Composer(placeholder: "Reply", text: $reply, attachments: $attachments, enabled: model.canChange, sending: sending) {
                let words = reply, files = attachments
                sending = true
                Task {
                    if await model.reply(words, to: card, attachments: files) { reply = ""; attachments = [] }
                    sending = false
                }
            }
        }
        .navigationTitle("Thread")
        .iOSInlineTitle()
        .task { await model.loadThread(of: card) }
    }
}
