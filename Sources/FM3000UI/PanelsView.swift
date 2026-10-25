import FM3000Core
import FM3000Model
import SwiftUI

/// Panels on the phone: the same two panels as the desktop (Machine load and Open pull requests), read from the Mac
/// that runs Infinitary through the extensions' own stores and server actions.
struct PanelsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        List {
            NavigationLink(value: OthersPage.resources) { Label("Machine load", systemImage: "gauge.with.dots.needle.50percent") }.infinitaryRow()
            NavigationLink(value: OthersPage.pullRequests) { Label("Open pull requests", systemImage: "arrow.triangle.pull") }.infinitaryRow()
        }
        .infinitaryScreen()
        .navigationTitle("Panels").iOSInlineTitle()
    }
}

// MARK: Machine load

/// The desktop's colours: orange above 60%, red above 85%.
private func loadTint(_ value: Double?) -> Color {
    guard let value else { return Theme.fg3 }
    return value > 85 ? Theme.danger : (value > 60 ? Theme.warn : Theme.accent)
}

private func gigabytes(_ bytes: Double) -> String { String(format: "%.1f", bytes / 1_073_741_824) }

private func bytes(_ value: Int?) -> String {
    guard let value else { return "—" }
    return ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .memory)
}

struct Meter: View {
    let label: String
    let history: [Double?]
    var detail: String?

    private var value: Double? { history.last ?? nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).font(.subheadline).foregroundStyle(Theme.fg2)
                if let detail { Text(detail).font(.caption).foregroundStyle(Theme.fg3) }
                Spacer()
                Text(value.map { "\(Int($0.rounded()))%" } ?? "–").font(.title3.monospacedDigit()).foregroundStyle(loadTint(value))
            }
            Spark(history: history, tint: loadTint(value)).frame(height: 36)
        }
        .padding(.vertical, 4)
    }
}

/// The last minute as a line over a faint area, like the desktop's sparkline: 0 to 100% top to bottom, gaps where there was no reading.
struct Spark: View {
    static let capacity = 60
    let history: [Double?]
    let tint: Color

    var body: some View {
        GeometryReader { box in
            let step = box.size.width / CGFloat(Spark.capacity - 1)
            let offset = Spark.capacity - history.count
            let point = { (i: Int, v: Double) in
                CGPoint(x: CGFloat(offset + i) * step, y: box.size.height - 1 - CGFloat(min(100, max(0, v)) / 100) * (box.size.height - 2))
            }
            ZStack {
                Path { p in p.move(to: CGPoint(x: 0, y: box.size.height - 0.5)); p.addLine(to: CGPoint(x: box.size.width, y: box.size.height - 0.5)) }
                    .stroke(Theme.line, lineWidth: 0.5)
                Path { p in
                    var run: [CGPoint] = []
                    func flush() {
                        if run.count > 1, let first = run.first, let last = run.last {
                            p.move(to: CGPoint(x: first.x, y: box.size.height))
                            for pt in run { p.addLine(to: pt) }
                            p.addLine(to: CGPoint(x: last.x, y: box.size.height)); p.closeSubpath()
                        }
                        run = []
                    }
                    for (i, v) in history.enumerated() { if let v { run.append(point(i, v)) } else { flush() } }
                    flush()
                }
                .fill(tint.opacity(0.14))
                Path { p in
                    var started = false
                    for (i, v) in history.enumerated() {
                        guard let v else { started = false; continue }
                        if started { p.addLine(to: point(i, v)) } else { p.move(to: point(i, v)); started = true }
                    }
                }
                .stroke(tint, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

/// CPU, GPU and memory of the Mac that runs Infinitary (never the iPhone), sampled every two seconds like the desktop panel.
struct ResourcesView: View {
    @ObservedObject var model: AppModel
    @State private var cpu: [Double?] = []
    @State private var gpu: [Double?] = []
    @State private var memory: [Double?] = []
    @State private var memoryDetail: String?
    /// True while the numbers are the panel's saved reading; false when only the Mac's general reading reaches this phone.
    @State private var savedReading = false
    @State private var observation: ComputerResources.Computer.Observation?

    private var macName: String {
        if case .connected(let mac, _) = model.phase { return mac }
        return "your Mac"
    }

    var body: some View {
        List {
            Section {
                Meter(label: "CPU", history: cpu).infinitaryRow()
                Meter(label: "GPU", history: gpu).infinitaryRow()
                Meter(label: "Memory", history: memory, detail: memoryDetail).infinitaryRow()
            } footer: {
                if savedReading {
                    Text("Measured on \(macName), the Mac running Infinitary. Not this iPhone. GPU and memory are the panel's reading, saved by the Mac every minute.")
                } else {
                    Text("Measured on \(macName), the Mac running Infinitary. Not this iPhone. The Mac does not let the phone read the panel's saved GPU and memory yet, so GPU stays blank and memory is macOS's own count, which includes compressed and cached memory and reads higher than the desktop panel.")
                }
            }
            if let memory = observation?.memory {
                Section("Memory details") {
                    LabeledContent("Pressure", value: (memory.memoryPressure ?? "normal").capitalized).infinitaryRow()
                    LabeledContent("Available", value: bytes(memory.availableBytes)).infinitaryRow()
                    LabeledContent("Free", value: bytes(memory.freeBytes)).infinitaryRow()
                    LabeledContent("Inactive", value: bytes(memory.inactiveBytes)).infinitaryRow()
                    LabeledContent("File cache", value: bytes(memory.fileBackedBytes)).infinitaryRow()
                    LabeledContent("Purgeable", value: bytes(memory.purgeableBytes)).infinitaryRow()
                }
            }
            if let observation {
                Section("Processor") {
                    LabeledContent("Logical cores", value: "\(observation.cpu.logicalCpus)").infinitaryRow()
                    LabeledContent("Sampled every", value: "\(Int(observation.sampleMs)) ms").infinitaryRow()
                }
            }
        }
        .infinitaryScreen()
        .navigationTitle("Machine load").iOSInlineTitle()
        .task {
            while !Task.isCancelled {
                if model.phase.isConnected { await sample() }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    private func push(_ list: inout [Double?], _ value: Double?) {
        list.append(value)
        if list.count > Spark.capacity { list.removeFirst(list.count - Spark.capacity) }
    }

    private func sample() async {
        let home = await model.resources()?.computers.first { $0.computerId == nil }
        push(&cpu, home?.cpuUsed.map { $0 * 100 })
        observation = home?.reading.observation
        if let machine = await model.machineSample() {
            savedReading = true
            push(&gpu, machine.gpu)
            if let used = machine.memory, let percent = machine.memoryPercent {
                push(&memory, percent)
                memoryDetail = "\(gigabytes(used.usedBytes)) of \(gigabytes(used.totalBytes)) GB"
                return
            }
        } else {
            savedReading = false
            push(&gpu, nil)
        }
        push(&memory, home?.memoryUsed.map { $0 * 100 })
        memoryDetail = nil
    }
}

// MARK: Open pull requests

private func tone(_ checks: String) -> Color {
    switch checks { case "passed": Theme.accent; case "failed": Theme.danger; case "pending": Theme.warn; default: Theme.fg3 }
}

private func word(_ checks: String) -> String {
    switch checks { case "passed": "passed"; case "failed": "failed"; case "pending": "running"; default: "no checks" }
}

/// The desktop's "Open pull requests" panel: how many are open, an age filter (today, week, older) with bars,
/// and the groups Ready to merge, Needs attention and Waiting, each row led by its checks colour.
struct PullRequestsView: View {
    @ObservedObject var model: AppModel
    @State private var prs: OpenPRs?
    @State private var loaded = false
    @State private var refreshing = false
    @State private var age: OpenPRs.Age?
    @State private var expanded: Set<OpenPRs.Group> = DebugLaunch.has("-openGroups") ? Set(OpenPRs.Group.allCases) : []
    @State private var expandedBefore: Set<OpenPRs.Group> = []
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            if let blocked = prs?.blocked {
                Text(blocked).foregroundStyle(Theme.fg2).infinitaryRow()
            } else if let prs {
                tally(prs).infinitaryRow()
                if prs.changes.isEmpty {
                    Text("No open pull requests").foregroundStyle(Theme.fg2).infinitaryRow()
                } else {
                    ForEach(OpenPRs.Group.allCases) { group in groupSection(group, prs) }
                    if let age, shown(prs).isEmpty { Text("None opened \(ageWords(age))").foregroundStyle(Theme.fg2).infinitaryRow() }
                }
                if prs.status == "unreachable" { Text("Could not reach GitHub just now").font(.caption).foregroundStyle(Theme.fg3).infinitaryRow() }
            } else {
                Text(loaded ? "The Mac does not let the iPhone read this panel yet. Infinitary keeps panel data to the desktop app." : "Reading…").foregroundStyle(Theme.fg2).infinitaryRow()
            }
        }
        .infinitaryScreen()
        .navigationTitle("Open pull requests").iOSInlineTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { Task { await refreshNow() } } label: { Image(systemName: "arrow.clockwise") }
                    .disabled(refreshing).accessibilityLabel(refreshing ? "Reading GitHub" : "Refresh now")
            }
        }
        .refreshable { await refreshNow() }
        .task {
            // Read again every 30 seconds, and every 2 until the first answer (the phone may still be connecting).
            while !Task.isCancelled {
                if model.phase.isConnected { prs = await model.openPRs(); loaded = true }
                try? await Task.sleep(nanoseconds: prs == nil ? 2_000_000_000 : 30_000_000_000)
            }
        }
    }

    private func refreshNow() async {
        refreshing = true
        await model.refreshOpenPRs()
        prs = await model.openPRs()
        refreshing = false
    }

    private func ageWords(_ age: OpenPRs.Age) -> String {
        switch age { case .today: "today"; case .week: "this week"; case .older: "over a week ago" }
    }

    private func shown(_ prs: OpenPRs) -> [OpenPRs.Change] {
        guard let age else { return prs.changes }
        return prs.changes.filter { OpenPRs.age(of: $0) == age }
    }

    private func pick(_ next: OpenPRs.Age) {
        if age == next { age = nil; expanded = expandedBefore; return }
        if age == nil { expandedBefore = expanded }
        age = next
        expanded = Set(OpenPRs.Group.allCases)
    }

    private func tally(_ prs: OpenPRs) -> some View {
        let counts = prs.counts()
        let most = max(1, counts.values.max() ?? 1)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(prs.changes.count)").font(.title2.monospacedDigit()).foregroundStyle(Theme.fg1)
                Text("open").font(.subheadline).foregroundStyle(Theme.fg2)
                if prs.failedCount > 0 { Text("\(prs.failedCount) failed").font(.caption.weight(.semibold)).foregroundStyle(Theme.danger).padding(.leading, 6) }
            }
            if !prs.changes.isEmpty {
                HStack(spacing: 8) {
                    ForEach(OpenPRs.Age.allCases) { bucket in
                        let count = counts[bucket] ?? 0
                        Button { pick(bucket) } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(count)").font(.subheadline.monospacedDigit()).foregroundStyle(Theme.fg1)
                                    Text(bucket.label).font(.caption).foregroundStyle(Theme.fg2)
                                }
                                GeometryReader { box in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Theme.bg3)
                                        Capsule().fill(Theme.accent).frame(width: box.size.width * CGFloat(count) / CGFloat(most))
                                    }
                                }
                                .frame(height: 4)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(age == bucket ? Theme.bg3 : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(age == bucket ? Theme.accent.opacity(0.6) : Theme.line, lineWidth: 0.75))
                        }
                        .buttonStyle(.plain)
                        .disabled(count == 0 && age != bucket)
                        .opacity(count == 0 && age != bucket ? 0.5 : 1)
                        .accessibilityLabel("\(bucket.title): \(count)")
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder private func groupSection(_ group: OpenPRs.Group, _ prs: OpenPRs) -> some View {
        let rows = shown(prs).filter { OpenPRs.group(of: $0) == group }
        let isOpen = !rows.isEmpty && expanded.contains(group)
        Button {
            if expanded.contains(group) { expanded.remove(group) } else { expanded.insert(group) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.right").font(.caption2.weight(.semibold)).foregroundStyle(Theme.fg3)
                    .rotationEffect(.degrees(isOpen ? 90 : 0))
                Text(group.label.uppercased()).font(.caption.weight(.medium)).tracking(1).foregroundStyle(Theme.fg2)
                Text("\(rows.count)").font(.caption.monospacedDigit()).foregroundStyle(Theme.fg3)
                Spacer()
            }
        }
        .buttonStyle(.plain).disabled(rows.isEmpty).infinitaryRow()
        if isOpen {
            ForEach(rows) { change in
                Button { if let url = URL(string: change.url) { openURL(url) } } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Circle().fill(tone(change.checks)).frame(width: 8, height: 8).padding(.top, 6)
                            .shadow(color: tone(change.checks).opacity(0.5), radius: 3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(change.title).font(.subheadline).foregroundStyle(Theme.fg1).lineLimit(2)
                            HStack(spacing: 8) {
                                Text(change.projectName).foregroundStyle(Theme.fg3)
                                Text(change.shownLabel).foregroundStyle(Theme.fg3).font(.caption.monospaced())
                                Text(word(change.checks)).foregroundStyle(tone(change.checks))
                                if change.draft { Text("draft").foregroundStyle(Theme.fg2) }
                            }
                            .font(.caption)
                        }
                    }
                }
                .buttonStyle(.plain).infinitaryRow()
            }
        }
    }
}

private extension ConnectionPhase {
    var isConnected: Bool { if case .connected = self { return true } else { return false } }
}
