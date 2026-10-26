import FM3000Core
import FM3000Model
import SwiftUI

/// How much of the Claude and Codex subscriptions is used, five-hour and weekly windows, as the Mac's quota panel measured it.
struct QuotaView: View {
    @ObservedObject var model: AppModel
    @State private var snapshot: QuotaSnapshot?
    @State private var loaded = false

    var body: some View {
        List {
            if let snapshot, !snapshot.shown.isEmpty {
                ForEach(snapshot.shown) { provider in
                    Section {
                        if let why = provider.unavailable, provider.windows.isEmpty {
                            Text(why).font(.footnote).foregroundStyle(Theme.fg2)
                        } else {
                            QuotaRow(title: "5 hours", window: provider.fiveHour, stale: provider.stale)
                            QuotaRow(title: "Week", window: provider.weekly, stale: provider.stale)
                        }
                    } header: {
                        Text([provider.label, provider.plan?.capitalized].compactMap { $0 }.joined(separator: " · "))
                    } footer: {
                        if provider.stale { Text("Last good reading\(provider.measuredAt.map { ", " + relativeTime($0) } ?? "").") }
                    }
                    .listRowBackground(Theme.bg2)
                }
            } else if loaded {
                Text("The Mac has no quota reading to show right now. Open the Quota panel on the Mac to refresh it.")
                    .font(.footnote).foregroundStyle(Theme.fg2).listRowBackground(Color.clear)
            } else {
                ProgressView().frame(maxWidth: .infinity).listRowBackground(Color.clear)
            }
        }
        .infinitaryScreen()
        .navigationTitle("Quota").iOSInlineTitle()
        .task(id: model.phase) {
            guard case .connected = model.phase else { return }
            snapshot = await model.quota(); loaded = true
        }
        .refreshable { snapshot = await model.quota() }
    }
}

private struct QuotaRow: View {
    let title: String
    let window: QuotaSnapshot.Window?
    let stale: Bool

    /// Green within pace, amber up to ten points ahead of it, red beyond.
    static func tint(_ pace: QuotaPace) -> Color {
        switch pace {
        case .withinPace: return Theme.ok
        case .slightlyAhead: return Theme.warn
        case .wellAhead: return Theme.danger
        case .unknown: return Theme.accent
        }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let now = context.date.timeIntervalSince1970 * 1000
            let used = window?.percentUsed
            let ideal = window?.idealUsedPercent(nowMs: now)
            let tint = used == nil ? Theme.fg3 : Self.tint(window?.pace(nowMs: now) ?? .unknown)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title).font(.subheadline).foregroundStyle(Theme.fg2)
                    Spacer()
                    Text(used.map { "\(Int($0.rounded()))% used" } ?? "No figure").font(.title3.monospacedDigit()).foregroundStyle(tint)
                }
                PaceBar(used: used, ideal: ideal, tint: tint)
                HStack {
                    if let reset = window?.resetsIn(nowMs: now) {
                        Text(reset == "now" ? "Resets now" : "Resets in \(reset)")
                    } else if let text = window?.resetText {
                        Text(text)
                    }
                    Spacer()
                    if let ideal { Text("Even pace \(Int(ideal.rounded()))%") }
                }
                .font(.caption.monospacedDigit()).foregroundStyle(Theme.fg3)
            }
            .padding(.vertical, 4)
            .opacity(stale ? 0.6 : 1)
            .accessibilityElement(children: .combine)
        }
    }
}

/// The used share as a filled bar, with a white tick and arrow where even use would be by now: a fill past the
/// tick is use ahead of pace.
private struct PaceBar: View {
    let used: Double?
    let ideal: Double?
    let tint: Color

    var body: some View {
        GeometryReader { box in
            let width = box.size.width
            ZStack(alignment: .topLeading) {
                Capsule().fill(Theme.bg3).frame(height: 8).offset(y: 9)
                if let used { Capsule().fill(tint).frame(width: max(width * CGFloat(used) / 100, 8), height: 8).offset(y: 9) }
                if let ideal {
                    let x = width * CGFloat(ideal) / 100
                    Image(systemName: "arrowtriangle.down.fill").font(.system(size: 9)).foregroundStyle(Theme.fg1)
                        .frame(width: 12, height: 9).offset(x: x - 6, y: -1)
                    Rectangle().fill(Theme.fg1).frame(width: 2, height: 14).offset(x: x - 1, y: 6)
                }
            }
        }
        .frame(height: 20)
        .accessibilityHidden(true)
    }
}
