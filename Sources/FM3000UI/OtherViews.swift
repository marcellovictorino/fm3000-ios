import FM3000Core
import FM3000Model
import SwiftUI

/// Talks to Firstmate 3000: `inf:converse`, the same message box as the Mac's window.
struct MessageView: View {
    @ObservedObject var model: AppModel
    @State private var text = ""
    @State private var sending = false
    @State private var attachments: [Attachment] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StatusBanner(model: model)
                ChatList(items: model.chat, empty: "Say something to Firstmate. Its answer shows here.")
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Composer(placeholder: "Message Firstmate", text: $text, attachments: $attachments, enabled: model.canChange, sending: sending) {
                    let words = text, files = attachments
                    sending = true
                    Task {
                        if await model.send(words, attachments: files) { text = ""; attachments = [] }
                        sending = false
                    }
                }
            }
            .navigationTitle("Message")
            .iOSInlineTitle()
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
            .onChange(of: model.phase) { phase in
                if case .connected = phase { Task { await model.refreshFeed() } }
            }
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
    @State private var tab = DebugLaunch.tab
    public init(model: AppModel) { self.model = model; Theme.applyBars() }

    public var body: some View {
        if model.phase == .unpaired {
            PairView(model: model).infinitaryRoot()
        } else {
            TabView(selection: $tab) {
                CardsView(model: model).tag(0).tabItem { Label("Cards", systemImage: "rectangle.stack") }.badge(model.cards.count)
                MessageView(model: model).tag(1).tabItem { Label("Message", systemImage: "bubble.left") }
                BoardView(model: model).tag(2).tabItem { Label("Tasks", systemImage: "checklist") }
                FeedView(model: model).tag(3).tabItem { Label("Feed", systemImage: "list.bullet") }
                MacView(model: model).tag(4).tabItem { Label("Mac", systemImage: "desktopcomputer") }
            }
            .infinitaryRoot()
            .onChange(of: tab) { _ in dismissKeyboard() }
        }
    }
}
