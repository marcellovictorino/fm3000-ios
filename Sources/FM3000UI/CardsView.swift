import FM3000Core
import FM3000Model
import SwiftUI

struct CardsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationStack {
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
            .navigationDestination(for: String.self) { id in
                if let card = model.cards.first(where: { $0.id == id }) { CardDetailView(model: model, card: card) }
                else { Text("This card was answered.").foregroundStyle(Theme.fg2) }
            }
        }
    }
}

struct CardDetailView: View {
    @ObservedObject var model: AppModel
    let card: Card
    @State private var reply = ""
    @State private var sending = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(card.meta).font(.caption).foregroundStyle(Theme.fg2)
                Text(HTMLText.plain(card.body)).textSelection(.enabled)
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
                Divider()
                ForEach(model.threads[card.id] ?? []) { message in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(message.who == "captain" ? "You" : message.who.capitalized).font(.caption).foregroundStyle(Theme.fg2)
                        Text(message.text)
                    }
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(message.who == "captain" ? Theme.accent.opacity(0.14) : Theme.bg2, in: RoundedRectangle(cornerRadius: 10))
                }
                HStack(alignment: .bottom) {
                    TextField("Reply", text: $reply, axis: .vertical).lineLimit(1...5).textFieldStyle(.roundedBorder)
                    Button("Send") {
                        sending = true
                        Task {
                            if await model.reply(reply, to: card) { reply = "" }
                            sending = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sending || !model.canChange)
                }
            }
            .padding()
        }
        .background(Theme.bg0.ignoresSafeArea())
        .navigationTitle(card.title)
        .iOSInlineTitle()
        .task { await model.loadThread(of: card) }
    }
}
