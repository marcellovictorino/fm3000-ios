import FM3000Core
import FM3000Model
import SwiftUI

/// Talks to Firstmate 3000: `inf:converse`, the same message box as the Mac's window.
struct MessageView: View {
    @ObservedObject var model: AppModel
    @State private var text = ""
    @State private var sent: [String] = []
    @State private var sending = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StatusBanner(model: model)
                List {
                    if sent.isEmpty {
                        Text("Say something to Firstmate. Its answer arrives as a card.").foregroundStyle(Theme.fg2).listRowBackground(Color.clear)
                    }
                    ForEach(Array(sent.enumerated()), id: \.offset) { _, line in Label(line, systemImage: "paperplane").listRowBackground(Theme.bg2) }
                }
                .infinitaryScreen()
                HStack(alignment: .bottom) {
                    TextField("Message Firstmate", text: $text, axis: .vertical).lineLimit(1...6).textFieldStyle(.roundedBorder)
                    Button("Send") {
                        let words = text
                        sending = true
                        Task {
                            if await model.send(words) { sent.insert(words, at: 0); text = "" }
                            sending = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sending || !model.canChange)
                }
                .padding()
            }
            .navigationTitle("Message")
            .iOSInlineTitle()
        }
    }
}

struct BoardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationStack {
            List {
                if let board = model.board {
                    ForEach(board.projects.filter { !$0.archived }) { project in
                        Section("\(project.name) · \(project.counts.needsYou) need you") {
                            ForEach(board.tasks.filter { $0.projectId == project.id && ($0.status == "open" || $0.status == "active") }) { task in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(task.key)  \(task.title)").font(.headline)
                                    Text([task.status, task.activity, task.assignee].compactMap { $0 }.joined(separator: " · ")).font(.caption).foregroundStyle(Theme.fg2)
                                }
                                .infinitaryRow()
                            }
                        }
                    }
                } else {
                    Text("Loading the task board…").foregroundStyle(Theme.fg2).listRowBackground(Color.clear)
                }
            }
            .infinitaryScreen()
            .safeAreaInset(edge: .top, spacing: 0) { StatusBanner(model: model) }
            .navigationTitle("Tasks").iOSInlineTitle()
            .refreshable { await model.refreshBoard() }
            .task { await model.refreshBoard() }
        }
    }
}

struct FeedView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationStack {
            List(model.feed.reversed()) { line in
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.text)
                    Text("\(line.taskKey.map { $0 + " · " } ?? "")\(relativeTime(line.at))").font(.caption).foregroundStyle(Theme.fg2)
                }
                .infinitaryRow()
            }
            .infinitaryScreen()
            .safeAreaInset(edge: .top, spacing: 0) { StatusBanner(model: model) }
            .navigationTitle("Feed").iOSInlineTitle()
            .refreshable { await model.refreshFeed() }
            .task { await model.refreshFeed() }
        }
    }
}

struct MacView: View {
    @ObservedObject var model: AppModel
    @State private var confirming = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    switch model.phase {
                    case .connected(let mac, let access): LabeledContent("Mac", value: mac); LabeledContent("Access", value: access == .full ? "Full" : "Read only")
                    case .connecting: Text("Connecting…")
                    case .offline(let reason): Text(reason).foregroundStyle(Theme.danger)
                    case .unpaired: Text("Not paired")
                    }
                    Button("Reconnect") { model.start() }
                }
                .infinitaryRow()
                Section {
                    Button("Forget this Mac", role: .destructive) { confirming = true }
                        .listRowBackground(Theme.bg2)
                } footer: {
                    Text("If this phone is lost, open Infinitary on your Mac > Settings > Devices and remove it there. Removing it on the Mac cuts it off at once.")
                }
            }
            .infinitaryScreen()
            .navigationTitle("Mac").iOSInlineTitle()
            .alert("Forget this Mac?", isPresented: $confirming) {
                Button("Cancel", role: .cancel) {}
                Button("Forget", role: .destructive) { Task { await model.unpair() } }
            } message: { Text("The Mac removes this phone from its list. You will need a new link to pair again.") }
        }
    }
}

public struct RootView: View {
    @ObservedObject var model: AppModel
    public init(model: AppModel) { self.model = model; Theme.applyBars() }

    public var body: some View {
        if model.phase == .unpaired {
            PairView(model: model).infinitaryRoot()
        } else {
            TabView {
                CardsView(model: model).tabItem { Label("Cards", systemImage: "rectangle.stack") }.badge(model.cards.count)
                MessageView(model: model).tabItem { Label("Message", systemImage: "bubble.left") }
                BoardView(model: model).tabItem { Label("Tasks", systemImage: "checklist") }
                FeedView(model: model).tabItem { Label("Feed", systemImage: "list.bullet") }
                MacView(model: model).tabItem { Label("Mac", systemImage: "desktopcomputer") }
            }
            .infinitaryRoot()
        }
    }
}
