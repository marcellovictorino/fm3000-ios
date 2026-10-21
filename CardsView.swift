import FM3000Core
import SwiftUI

struct CardsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationStack {
            Group {
                if model.cards.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle").font(.largeTitle).foregroundStyle(.secondary)
                        Text("Nothing waits for you").font(.headline)
                        Text("Cards from Firstmate 3000 appear here the moment they are raised.").font(.footnote).foregroundStyle(.secondary)
                    }.padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(model.cards) { card in
                        NavigationLink(value: card.id) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.title).font(.headline)
                                Text(HTMLText.plain(card.body)).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                                Text("\(card.meta) · \(relativeTime(card.createdAt))").font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) { StatusBanner(model: model) }
            .navigationTitle("Cards")
            .navigationDestination(for: String.self) { id in
                if let card = model.cards.first(where: { $0.id == id }) { CardDetailView(model: model, card: card) }
                else { Text("This card was answered.").foregroundStyle(.secondary) }
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
                Text(card.meta).font(.caption).foregroundStyle(.secondary)
                Text(HTMLText.plain(card.body)).textSelection(.enabled)
                if card.status == "streaming" { ProgressView("Still being written…") }
                if !card.actions.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(card.actions) { action in
                            Button { Task { await model.choose(action, on: card) } } label: {
                                Text(action.label).frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(action.variant == "danger" ? .red : (action.isDefault ? .accentColor : .gray))
                            .disabled(!model.canChange)
                        }
                    }
                }
                Divider()
                ForEach(model.threads[card.id] ?? []) { message in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(message.who == "captain" ? "You" : message.who.capitalized).font(.caption).foregroundStyle(.secondary)
                        Text(message.text)
                    }
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(message.who == "captain" ? Color.accentColor.opacity(0.12) : Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
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
        .navigationTitle(card.title)
        .iOSInlineTitle()
        .task { await model.loadThread(of: card) }
    }
}
