import FM3000Core
import FM3000Model
import SwiftUI

/// What is left of the Claude and Codex subscriptions, five-hour and weekly windows, as the Mac's quota panel measured it.
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

    private var left: Double? { window?.percentRemaining }
    private var tint: Color {
        guard let left else { return Theme.fg3 }
        return left < 15 ? Theme.danger : (left < 40 ? Theme.warn : Theme.accent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.subheadline).foregroundStyle(Theme.fg2)
                Spacer()
                Text(left.map { "\(Int($0.rounded()))% left" } ?? "No figure").font(.title3.monospacedDigit()).foregroundStyle(tint)
            }
            GeometryReader { box in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.bg3)
                    if let left { Capsule().fill(tint).frame(width: box.size.width * CGFloat(min(max(left, 0), 100)) / 100) }
                }
            }.frame(height: 6)
            if let reset = window?.resetsAtMs {
                Text("Resets \(Self.resetText(reset))").font(.caption).foregroundStyle(Theme.fg3)
            } else if let text = window?.resetText {
                Text(text).font(.caption).foregroundStyle(Theme.fg3)
            }
        }
        .padding(.vertical, 4)
        .opacity(stale ? 0.6 : 1)
    }

    static func resetText(_ ms: Double) -> String {
        let date = Date(timeIntervalSince1970: ms / 1000)
        let seconds = date.timeIntervalSinceNow
        if seconds <= 0 { return "now" }
        if seconds < 24 * 3600 { return "in " + (seconds < 3600 ? "\(Int(seconds / 60)) min" : String(format: "%dh %02dm", Int(seconds / 3600), Int(seconds) % 3600 / 60)) }
        return date.formatted(.dateTime.weekday(.wide).hour().minute())
    }
}
