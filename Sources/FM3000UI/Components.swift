import FM3000Core
import FM3000Model
import SwiftUI

extension View {
    /// Modifiers that exist on iOS only, so these screens also type-check as macOS code.
    @ViewBuilder func iOSInlineTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder func plainTextInput() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.never).autocorrectionDisabled()
        #else
        self
        #endif
    }
}

/// Says where the connection stands, and the Mac's last refusal, above every screen.
struct StatusBanner: View {
    @ObservedObject var model: AppModel
    /// A dropped socket usually comes back within a second or two: the banner waits for a sustained outage.
    @State private var outageShown = false
    private static let outageGrace: UInt64 = 10_000_000_000

    private var isDown: Bool {
        switch model.phase { case .connecting, .offline: true; default: false }
    }

    var body: some View {
        VStack(spacing: 0) {
            switch model.phase {
            case .connecting where outageShown:
                banner("Connecting to your Mac…", tint: Theme.warn)
            case .connecting:
                EmptyView()
            case .offline(let reason) where outageShown:
                banner(reason, tint: Theme.danger) { Button("Retry") { model.start() }.buttonStyle(.bordered) }
            case .connected(_, .read):
                banner("This app is older than your Mac's Infinitary. You can read, not change.", tint: Theme.warn)
            case .connected, .unpaired, .offline:
                EmptyView()
            }
            if let notice = model.notice {
                banner(notice, tint: Theme.accent) { Button("OK") { model.notice = nil }.buttonStyle(.bordered) }
            }
        }
        .task(id: isDown) {
            // Keyed on down or up, not the phase: retries flip connecting and offline, and must not restart the wait.
            guard isDown else { outageShown = false; return }
            try? await Task.sleep(nanoseconds: Self.outageGrace)
            if !Task.isCancelled { outageShown = true }
        }
    }

    private func banner<Trailing: View>(_ text: String, tint: Color, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) -> some View {
        HStack {
            Text(text).font(.footnote).frame(maxWidth: .infinity, alignment: .leading)
            trailing()
        }
        .padding(10)
        .background(tint.opacity(0.15))
    }
}

func relativeTime(_ millis: Double) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: Date(timeIntervalSince1970: millis / 1000), relativeTo: Date())
}

/// A small label for the model a task or card runs on, drawn at the top of the row; nothing when the Mac named none.
struct ModelPill: View {
    let name: String?

    var body: some View {
        if let name {
            Text(name).font(.caption2.weight(.semibold)).foregroundStyle(Theme.accent)
                .padding(.horizontal, 7).padding(.vertical, 2)
                .background(Theme.accent.opacity(0.14), in: Capsule())
                .accessibilityLabel("Model \(name)")
        }
    }
}

/// A card's choice button drawn like the desktop's `Button` (`design/core/Button.tsx`): the default is a filled accent button with
/// dark text, the others are outlined (danger in red), ghost is bare text, and a press goes to the stronger fill. The choice that was
/// picked reads as selected (filled, with a check), and the others step back.
struct CardActionButton: View {
    let action: CardAction
    let selected: Bool
    let working: Bool
    let dimmed: Bool
    let perform: () -> Void

    private var variant: String { action.variant ?? (action.isDefault ? "primary" : "secondary") }

    var body: some View {
        Button(action: perform) {
            HStack(spacing: 8) {
                if working { ProgressView().controlSize(.small) }
                else if selected { Image(systemName: "checkmark") }
                Text(working ? "Sending…" : action.label)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(CardActionStyle(variant: variant, selected: selected))
        .opacity(dimmed ? 0.45 : 1)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct CardActionStyle: ButtonStyle {
    let variant: String
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let filled = selected || variant == "primary"
        let tone: Color = variant == "danger" ? Theme.danger : Theme.accent
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(filled ? Theme.bg0 : (variant == "danger" ? Theme.danger : (variant == "ghost" ? Theme.fg2 : Theme.fg1)))
            .padding(.vertical, 12).padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(filled ? (pressed ? (variant == "danger" ? Theme.danger.opacity(0.8) : Theme.accentStrong) : tone)
                                 : (pressed ? (variant == "danger" ? Theme.danger.opacity(0.15) : Theme.bg3) : .clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(filled || variant == "ghost" ? Color.clear : (variant == "danger" ? Theme.danger : Theme.line.opacity(2)), lineWidth: 1)
            )
    }
}
