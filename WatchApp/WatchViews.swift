import FM3000WatchLink
import SwiftUI

/// The cards waiting on the captain, newest first.
struct WatchRoot: View {
    @ObservedObject var model: WatchModel
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if let problem = model.problem, model.cards.isEmpty || !model.loaded {
                    Text(problem).foregroundStyle(.secondary)
                    Button("Try again") { Task { await model.refresh() } }
                } else if model.loaded && model.cards.isEmpty {
                    Text("Nothing is waiting on you.").foregroundStyle(.secondary)
                }
                ForEach(model.cards) { card in
                    NavigationLink(value: card.id) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.title).font(.headline).lineLimit(3)
                            if !card.meta.isEmpty { Text(card.meta).font(.caption2).foregroundStyle(.secondary).lineLimit(1) }
                        }
                    }
                }
            }
            .overlay { if !model.loaded && model.problem == nil { ProgressView() } }
            .navigationTitle("Waiting")
            .navigationDestination(for: String.self) { id in
                if let card = model.cards.first(where: { $0.id == id }) { WatchCardView(model: model, card: card) }
            }
            .refreshable { await model.refresh() }
            #if DEBUG
            // Simulator runs: `-openCard <n>` opens the nth card once the list arrives, so a script can show the card screen.
            .onChange(of: model.cards) { _, cards in
                let arguments = ProcessInfo.processInfo.arguments
                if path.isEmpty, let flag = arguments.firstIndex(of: "-openCard"), flag + 1 < arguments.count, let n = Int(arguments[flag + 1]), cards.indices.contains(n) { path = [cards[n].id] }
            }
            #endif
        }
    }
}

/// One card: its text to scroll through, then its buttons and Put aside. No words are sent with a choice.
struct WatchCardView: View {
    @ObservedObject var model: WatchModel
    let card: WatchCard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollViewReader { scroll in
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(card.title).font(.headline)
                if !card.text.isEmpty { Text(card.text).font(.footnote) }
                if card.needsPhone {
                    Label("Answer on your phone", systemImage: "iphone").font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(card.choices) { choice in
                    Button { Task { if await model.choose(choice, on: card) { dismiss() } } } label: {
                        Text(choice.label).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(choice.isDefault ? .accentColor : .gray)
                    .disabled(model.sending != nil)
                }
                Button { Task { if await model.putAside(card) { dismiss() } } } label: {
                    Label("Put aside", systemImage: "tray.and.arrow.down").frame(maxWidth: .infinity)
                }
                .disabled(model.sending != nil)
                .id("end")
                if let problem = model.problem { Text(problem).font(.footnote).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Card")
        #if DEBUG
        .task {
            if ProcessInfo.processInfo.arguments.contains("-scrollEnd") { try? await Task.sleep(nanoseconds: 800_000_000); scroll.scrollTo("end", anchor: .bottom) }
        }
        .task {
            // `-pressChoice <n>` presses the nth button, `-pressAside` Put aside: a script cannot tap the simulated watch.
            let arguments = ProcessInfo.processInfo.arguments
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if let flag = arguments.firstIndex(of: "-pressChoice"), flag + 1 < arguments.count, let n = Int(arguments[flag + 1]), card.choices.indices.contains(n) { if await model.choose(card.choices[n], on: card) { dismiss() } }
            else if arguments.contains("-pressAside") { if await model.putAside(card) { dismiss() } }
        }
        #endif
        }
    }
}
