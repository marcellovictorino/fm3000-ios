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

    var body: some View {
        VStack(spacing: 0) {
            switch model.phase {
            case .connecting:
                banner("Connecting to your Mac…", tint: .orange)
            case .offline(let reason):
                banner(reason, tint: .red) { Button("Retry") { model.start() }.buttonStyle(.bordered) }
            case .connected(_, .read):
                banner("This app is older than your Mac's Firstmate 3000. You can read, not change.", tint: .orange)
            case .connected, .unpaired:
                EmptyView()
            }
            if let notice = model.notice {
                banner(notice, tint: .blue) { Button("OK") { model.notice = nil }.buttonStyle(.bordered) }
            }
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
