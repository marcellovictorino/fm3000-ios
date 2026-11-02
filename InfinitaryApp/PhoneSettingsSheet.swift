import InfinitaryKit
import SwiftUI

/// INF-1062, the captain's pick: Settings at the bar's left is this phone's own sheet, with what this device can do,
/// that appearance follows it and the app's version. Leave and Forget stay with the computer in its sheet.
struct PhoneSettingsSheet: View {
    let session: ReadOnlySession
    @Environment(\.dismiss) private var dismiss

    private var device: String { UIDevice.current.userInterfaceIdiom == .pad ? "This iPad" : "This phone" }

    /// The version the person would read back to someone, as the app was built: the marketing version and its build.
    static var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let short = info["CFBundleShortVersionString"] as? String ?? "0"
        let build = info["CFBundleVersion"] as? String ?? "0"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PhoneTheme.space5) {
                    VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                        Text(device).font(PhoneFont.headline)
                        Text(session.contact == "in-reach" && session.access != "full"
                            ? "Reads cards, Activity and tasks. \(PhoneUpdate.side(phone: PhoneContract.version, computer: session.homeVersion).words)"
                            : "Answers cards, sends messages and controls tasks on your computer.")
                            .font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
                        Text("Conversation stays on your computer.").font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
                    }
                    VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                        Text("Appearance").font(PhoneFont.headline)
                        Text("Follows this device’s setting.").font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
                    }
                    VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                        Text("Infinitary").font(PhoneFont.headline)
                        Text("Version \(Self.version)").font(PhoneFont.data).foregroundStyle(PhoneTheme.muted)
                            .accessibilityIdentifier("app-version")
                    }
                }.padding(PhoneTheme.space5).frame(maxWidth: .infinity, alignment: .leading)
            }
            .phoneTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }.accessibilityIdentifier("close-phone-settings")
            } }
        }
        .font(PhoneFont.body).foregroundStyle(PhoneTheme.text).tint(PhoneTheme.accent)
        .presentationDetents([.medium, .large]).presentationDragIndicator(.visible).phoneSheetSurface()
    }
}
