import InfinitaryKit
import SwiftUI

/// INF-1062, the captain's pick: Settings at the bar's left is this phone's own sheet, with what this device can do,
/// its own Theme and the app's version. Leave and Forget stay with the computer in its sheet.
struct PhoneSettingsSheet: View {
    let session: ReadOnlySession
    @Environment(\.dismiss) private var dismiss
    @Environment(PhoneSecrets.self) private var secrets: PhoneSecrets?
    @Environment(PhoneAppearance.self) private var appearance: PhoneAppearance?
    @FocusState private var themeFocused: Bool

    private var device: String { UIDevice.current.userInterfaceIdiom == .pad ? "This iPad" : "This phone" }
    /// The same device inside a sentence: lowercasing the heading would read "this ipad".
    private var thisDevice: String { UIDevice.current.userInterfaceIdiom == .pad ? "this iPad" : "this phone" }
    /// The name this device offers with its approval key, the same one it joined with.
    private var label: String { UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone" }

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
                    if let secrets, secrets.standing != .unavailable { approvals(secrets) }
                    if let appearance { theme(appearance) }
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

    /// The captain's Approve and build: this device's own Theme, in Apple's segmented control like the computer's Dark
    /// and Light pills, worded Device, Dark and Light. The computer's Theme is never read or changed.
    private func theme(_ appearance: PhoneAppearance) -> some View {
        @Bindable var appearance = appearance
        return VStack(alignment: .leading, spacing: PhoneTheme.space2) {
            Text("Theme").font(PhoneFont.headline)
            Text("Set on this \(label) only. \(session.mac.name) keeps its own.")
                .font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary).accessibilityIdentifier("phone-theme-scope")
            Picker("Theme", selection: $appearance.look) {
                ForEach(PhoneLook.allCases, id: \.self) { look in Text(look.words).tag(look) }
            }
            .pickerStyle(.segmented).labelsHidden().accessibilityIdentifier("phone-theme")
            // A segmented control takes no keys of its own, and an unseen shortcut under a sheet never hears an unmodified
            // arrow. So the control holds focus while Settings is open and its arrows move the choice, with no command.
            .focusable().focused($themeFocused)
            .onKeyPress(.leftArrow) { appearance.step(by: -1); return .handled }
            .onKeyPress(.rightArrow) { appearance.step(by: 1); return .handled }
            .onAppear { themeFocused = true }
        }
    }

    /// INF-1109's phone approvals (docs/secrets.md, "Remote decisions"): only while the computer offers Secrets.
    private func approvals(_ secrets: PhoneSecrets) -> some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space2) {
            Text("Secrets approvals").font(PhoneFont.headline)
            switch secrets.standing {
            case .offered:
                Text("Confirm on \(session.mac.name). Check that it shows this code:")
                    .font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
                Text(secrets.key?.code ?? "").font(PhoneFont.title.monospacedDigit()).foregroundStyle(PhoneTheme.text)
                    .accessibilityLabel("Code \(secrets.key?.code ?? "")").accessibilityIdentifier("approval-code")
                Text("If the codes differ, choose Not now there.").font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
            case .enrolled:
                Text("\(device) can allow uses of your secrets. Each Allow asks for \(ApprovalKey.confirmation).")
                    .font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary).accessibilityIdentifier("approval-enrolled")
                Text("Code \(secrets.key?.code ?? "")").font(PhoneFont.data).foregroundStyle(PhoneTheme.muted)
                Text("To stop, open Settings → Secrets on \(session.mac.name).").font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
            case .replaced:
                Text("\(session.mac.name) holds an earlier approval from \(thisDevice). Set up approvals again to use this one.")
                    .font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
                setUp(secrets, "Set up again")
            case .damaged:
                // INF-1109: a record this phone reads but cannot decode. Only this choice replaces it, under a new
                // device name, so the computer confirms the new key like a first one and keeps any earlier one.
                // Short enough that the button stays in view at the sheet's medium height on an iPad.
                Text("\(device)’s approval setup is damaged. Set up approvals again replaces it, then \(session.mac.name) asks you to confirm a new code.")
                    .font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary).accessibilityIdentifier("approval-damaged")
                setUp(secrets, "Set up approvals again", again: true)
                Text("If \(session.mac.name) still lists an earlier approval from \(thisDevice), stop it in Settings → Secrets there.")
                    .font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
            case .none, .unavailable:
                Text("Allow uses of your secrets from \(thisDevice), with \(ApprovalKey.confirmation) each time. \(session.mac.name) asks you to confirm first.")
                    .font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
                setUp(secrets, "Set up approvals")
            }
            if let problem = secrets.problem {
                Text(problem).font(PhoneFont.callout).foregroundStyle(PhoneTheme.warning).accessibilityIdentifier("approval-problem")
            }
        }
    }

    private func setUp(_ secrets: PhoneSecrets, _ words: String, again: Bool = false) -> some View {
        Button(words) { Task { if again { await secrets.setUpAgain(label: label) } else { await secrets.setUp(label: label) } } }
            .buttonStyle(PhoneChoiceStyle(.primary))
            .disabled(secrets.busy || !session.canChange)
            .accessibilityIdentifier("approval-set-up")
    }
}
