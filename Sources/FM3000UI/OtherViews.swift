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
                ChatList(items: model.chat, empty: "Say something to Firstmate. Its answer shows here.", typing: model.awaitingReply || DebugLaunch.has("-typing"))
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
        Group {
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

/// What the person used, counted on this phone: event totals for 7 or 30 days, and the file to share. Counts only, never content.
struct UsageView: View {
    @State private var days = 7
    @State private var totals: [(event: String, count: Int)] = []
    @State private var export: URL?

    var body: some View {
        List {
            Picker("Period", selection: $days) { Text("7 days").tag(7); Text("30 days").tag(30) }
                .pickerStyle(.segmented).listRowBackground(Color.clear)
            Section {
                if totals.isEmpty { Text("Nothing counted yet.").foregroundStyle(Theme.fg2) }
                ForEach(totals, id: \.event) { row in LabeledContent(row.event, value: row.event == "foreground_seconds" ? clock(row.count) : "\(row.count)") }
            } footer: {
                Text("Counts only: no messages, titles or names. They stay on this phone for \(UsageLog.keepDays) days unless you share them.")
            }
            .infinitaryRow()
            if let export { ShareLink("Export as JSON", item: export).listRowBackground(Theme.bg2) }
        }
        .infinitaryScreen()
        .navigationTitle("Usage").iOSInlineTitle()
        .onAppear(perform: reload)
        .onChange(of: days) { _ in reload() }
    }

    private func reload() {
        totals = UsageLog.shared.totals(days: days)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("fm3000-usage.json")
        export = (try? UsageLog.shared.exportJSON().write(to: url, options: .atomic)) != nil ? url : nil
    }

    private func clock(_ seconds: Int) -> String { seconds >= 3600 ? "\(seconds / 3600) h \(seconds % 3600 / 60) min" : "\(seconds / 60) min" }
}

struct MacView: View {
    @ObservedObject var model: AppModel
    @State private var confirming = false

    var body: some View {
        Group {
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

/// Feed and Mac, behind one "Others" tab so the bottom bar keeps room for the screens used most.
enum OthersPage: Hashable { case panels, quota, resources, pullRequests, feed, voice, mac, usage }

struct OthersView: View {
    @ObservedObject var model: AppModel
    @State private var path: [OthersPage] = DebugLaunch.has("-openOthers") ? [.mac]
        : DebugLaunch.has("-openResources") ? [.panels, .resources]
        : DebugLaunch.has("-openQuota") ? [.panels, .quota]
        : DebugLaunch.has("-openPRs") ? [.panels, .pullRequests]
        : DebugLaunch.has("-openPanels") ? [.panels]
        : DebugLaunch.has("-openUsage") ? [.usage]
        : DebugLaunch.has("-openVoice") ? [.voice] : []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink(value: OthersPage.panels) { Label("Panels", systemImage: "square.grid.2x2") }.infinitaryRow()
                NavigationLink(value: OthersPage.feed) { Label("Activity feed", systemImage: "list.bullet") }.infinitaryRow()
                NavigationLink(value: OthersPage.voice) { Label("Reading voice", systemImage: "speaker.wave.2") }.infinitaryRow()
                NavigationLink(value: OthersPage.mac) { Label("Mac connection", systemImage: "desktopcomputer") }.infinitaryRow()
                NavigationLink(value: OthersPage.usage) { Label("Usage", systemImage: "chart.bar.xaxis") }.infinitaryRow()
            }
            .infinitaryScreen()
            .navigationTitle("Others").iOSInlineTitle()
            .navigationDestination(for: OthersPage.self) { page in
                Group {
                    switch page {
                    case .panels: PanelsView(model: model)
                    case .quota: QuotaView(model: model)
                    case .resources: ResourcesView(model: model).onAppear { UsageLog.shared.record("page_view.machine_load") }
                    case .pullRequests: PullRequestsView(model: model).onAppear { UsageLog.shared.record("page_view.prs") }
                    case .feed: FeedView(model: model).onAppear { UsageLog.shared.record("page_view.feed") }
                    case .voice: VoicePickerView().onAppear { UsageLog.shared.record("page_view.voice") }
                    case .mac: MacView(model: model).onAppear { UsageLog.shared.record("page_view.mac") }
                    case .usage: UsageView()
                    }
                }
            }
        }
    }
}

public struct RootView: View {
    @ObservedObject var model: AppModel
    @State private var tab = DebugLaunch.tab
    public init(model: AppModel) { self.model = model; Theme.applyBars() }

    private func recordTab() { UsageLog.shared.record("tab_view.\(["cards", "message", "tasks", "others"][min(max(tab, 0), 3)])") }

    public var body: some View {
        if model.phase == .unpaired {
            PairView(model: model).infinitaryRoot()
        } else {
            TabView(selection: $tab) {
                CardsView(model: model).tag(0).tabItem { Label("Cards", systemImage: "rectangle.stack") }.badge(filterCards(model.cards, by: nil, board: nil).count)
                MessageView(model: model).tag(1).tabItem { Label("Message", systemImage: "bubble.left") }
                BoardView(model: model).tag(2).tabItem { Label("Tasks", systemImage: "checklist") }
                OthersView(model: model).tag(3).tabItem { Label("Others", systemImage: "ellipsis") }
            }
            .infinitaryRoot()
            .onChange(of: tab) { _ in dismissKeyboard(); recordTab() }
            .onAppear { recordTab() }
            .onChange(of: model.requestedTab) { wanted in
                if let wanted { tab = wanted; model.requestedTab = nil }
            }
        }
    }
}
