import FM3000Core
import FM3000Model
import SwiftUI

/// Panels on the phone. The Mac keeps its own panel calls to its window (`reach: home` in the contract), so these are
/// native screens over the data the phone may read: machine resources and pull request status.
struct PanelsView: View {
    @ObservedObject var model: AppModel

    enum Page: Hashable { case computer(String) }

    var body: some View {
        List {
            NavigationLink(value: OthersPage.resources) { Label("Resources", systemImage: "gauge.with.dots.needle.50percent") }.infinitaryRow()
            NavigationLink(value: OthersPage.pullRequests) { Label("Pull requests", systemImage: "arrow.triangle.pull") }.infinitaryRow()
        }
        .infinitaryScreen()
        .navigationTitle("Panels").iOSInlineTitle()
    }
}

struct Gauge: View {
    let title: String
    let fraction: Double
    var detail: String?

    private var tint: Color { fraction > 0.9 ? Theme.danger : (fraction > 0.75 ? Theme.warn : Theme.accent) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline).foregroundStyle(Theme.fg2)
                Spacer()
                Text("\(Int((fraction * 100).rounded()))%").font(.subheadline.monospacedDigit()).foregroundStyle(Theme.fg1)
            }
            GeometryReader { box in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.bg3)
                    Capsule().fill(tint).frame(width: max(4, box.size.width * fraction))
                        .shadow(color: tint.opacity(0.4), radius: 4)
                }
            }
            .frame(height: 8)
            if let detail { Text(detail).font(.caption).foregroundStyle(Theme.fg3) }
        }
    }
}

private func bytes(_ value: Int?) -> String {
    guard let value else { return "—" }
    return ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .memory)
}

/// Every computer the home can see, refreshed every two seconds while the screen is open.
struct ResourcesView: View {
    @ObservedObject var model: AppModel
    @State private var resources: ComputerResources?
    @State private var loaded = false

    var body: some View {
        List {
            if let computers = resources?.computers, !computers.isEmpty {
                ForEach(computers) { computer in
                    NavigationLink(value: PanelsView.Page.computer(computer.id)) { row(computer) }.infinitaryRow()
                }
            } else {
                Text(loaded ? "The Mac gave no readings." : "Reading…").foregroundStyle(Theme.fg2).infinitaryRow()
            }
        }
        .infinitaryScreen()
        .navigationTitle("Resources").iOSInlineTitle()
        .navigationDestination(for: PanelsView.Page.self) { page in
            if case .computer(let id) = page { ComputerView(model: model, computerId: id) }
        }
        .task {
            while !Task.isCancelled {
                resources = await model.resources(); loaded = true
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    private func row(_ computer: ComputerResources.Computer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(computer.label).font(.headline)
            if let cpu = computer.cpuUsed, let memory = computer.memoryUsed {
                Gauge(title: "CPU", fraction: cpu)
                Gauge(title: "Memory", fraction: memory)
            } else {
                Text(reasonText(computer.reading.reason)).font(.footnote).foregroundStyle(Theme.warn)
            }
        }
        .padding(.vertical, 4)
    }
}

private func reasonText(_ reason: String?) -> String {
    switch reason {
    case "out-of-reach": return "Out of reach right now."
    case "stale": return "The last reading is too old."
    case "unsupported": return "This computer does not report resources."
    case "timeout": return "The reading timed out."
    default: return "No reading available."
    }
}

/// One computer in detail: the gauges plus the memory breakdown and the sample rate.
struct ComputerView: View {
    @ObservedObject var model: AppModel
    let computerId: String
    @State private var computer: ComputerResources.Computer?

    var body: some View {
        List {
            if let computer, let observation = computer.reading.observation, let cpu = computer.cpuUsed, let memory = computer.memoryUsed {
                Section {
                    Gauge(title: "CPU", fraction: cpu, detail: "\(observation.cpu.logicalCpus) logical cores").infinitaryRow()
                    Gauge(title: "Memory", fraction: memory, detail: "\(bytes(computer.reading.memoryUsedBytes)) of \(bytes(observation.memory.totalBytes)) in use").infinitaryRow()
                }
                Section("Memory") {
                    LabeledContent("Pressure", value: (observation.memory.memoryPressure ?? "normal").capitalized).infinitaryRow()
                    LabeledContent("Available", value: bytes(observation.memory.availableBytes)).infinitaryRow()
                    LabeledContent("Free", value: bytes(observation.memory.freeBytes)).infinitaryRow()
                    LabeledContent("Inactive", value: bytes(observation.memory.inactiveBytes)).infinitaryRow()
                    LabeledContent("File cache", value: bytes(observation.memory.fileBackedBytes)).infinitaryRow()
                    LabeledContent("Purgeable", value: bytes(observation.memory.purgeableBytes)).infinitaryRow()
                }
                Section("Sampling") {
                    LabeledContent("Every", value: "\(Int(observation.sampleMs)) ms").infinitaryRow()
                    if let age = computer.reading.ageMs { LabeledContent("Reading age", value: "\(Int(age)) ms").infinitaryRow() }
                }
            } else {
                Text(reasonText(computer?.reading.reason)).foregroundStyle(Theme.fg2).infinitaryRow()
            }
        }
        .infinitaryScreen()
        .navigationTitle(computer?.label ?? "Computer").iOSInlineTitle()
        .task {
            while !Task.isCancelled {
                computer = await model.resources()?.computers.first { $0.id == computerId }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }
}

/// Open and active tasks that have a pull request, with their check state.
struct PullRequestsView: View {
    @ObservedObject var model: AppModel
    @State private var items: [(task: BoardTask, delivery: TaskDetail.Delivery)] = []
    @State private var loaded = false
    @State private var picked: BoardTask?

    var body: some View {
        List {
            if items.isEmpty {
                Text(loaded ? "No open task has a pull request." : "Reading…").foregroundStyle(Theme.fg2).infinitaryRow()
            }
            ForEach(items, id: \.task.id) { item in
                NavigationLink(value: item.task) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("#\(item.delivery.prNumber ?? 0)").font(.subheadline.monospaced()).foregroundStyle(Theme.accent)
                            Text(item.task.key).font(.caption.monospaced()).foregroundStyle(Theme.fg3)
                            Spacer()
                            CheckPill(state: item.delivery.ci)
                        }
                        Text(item.task.title).font(.subheadline)
                    }
                }
                .infinitaryRow()
            }
        }
        .infinitaryScreen()
        .navigationTitle("Pull requests").iOSInlineTitle()
        .navigationDestination(for: BoardTask.self) { task in
            if let delivery = items.first(where: { $0.task.id == task.id })?.delivery { PullRequestDetail(task: task, delivery: delivery) }
        }
        .refreshable { items = await model.pullRequests() }
        .task { await load() }
        .onChange(of: model.phase) { phase in if case .connected = phase { Task { await load() } } }
    }
}

extension PullRequestsView {
    fileprivate func load() async {
        await model.refreshBoard()
        items = await model.pullRequests()
        loaded = true
    }
}

struct CheckPill: View {
    let state: String?
    private var color: Color {
        switch state { case "green": Theme.accent; case "red", "failed": Theme.danger; case "pending", "running": Theme.warn; default: Theme.fg3 }
    }
    var body: some View {
        Text((state ?? "no checks").replacingOccurrences(of: "-", with: " ").capitalized)
            .font(.caption2.weight(.medium)).foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
    }
}

private struct PullRequestDetail: View {
    let task: BoardTask
    let delivery: TaskDetail.Delivery

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title).font(.headline)
                    HStack { CheckPill(state: delivery.ci); Text(task.key).font(.caption.monospaced()).foregroundStyle(Theme.fg3) }
                }
                .infinitaryRow()
            }
            Section("Pull request") {
                LabeledContent("Number", value: "#\(delivery.prNumber ?? 0)").infinitaryRow()
                if let mode = delivery.mode { LabeledContent("Delivery", value: mode).infinitaryRow() }
                if let checks = delivery.runChecks { LabeledContent(checks.name, value: checks.state).infinitaryRow() }
                if let text = delivery.prUrl, let url = URL(string: text) { Link("Open on the web", destination: url).infinitaryRow() }
            }
        }
        .infinitaryScreen()
        .navigationTitle("#\(delivery.prNumber ?? 0)").iOSInlineTitle()
    }
}
