import InfinitaryKit
import SwiftUI
import UIKit

/// INF-1183: Join by its address. One field for the account and computer, such as kun@studio, and
/// an optional port, with the computers on this network under them (INF-1312); then, as the join needs them, the computer's fingerprint asked once, and the
/// password typed once or this phone's key to copy. The link the computer answers is never shown.
struct PhoneAddressSheet: View {
    @Bindable var model: PhoneModel
    let close: () -> Void
    @State private var address = ""
    @State private var port = ""
    @State private var account = ""
    @State private var password = ""
    @State private var copied = false
    @State private var nearby = NearbyComputers()
    @State private var askingSweep = false
    @Environment(\.scenePhase) private var phase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PhoneTheme.space4) {
                    if let join = model.addressJoin { step(join) } else { typing }
                }.padding(PhoneTheme.space5).frame(maxWidth: 468).frame(maxWidth: .infinity)
            }
            .phoneTitle("Join by its address")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { model.cancelAddressJoin(); close() } } }
            // INF-1312: the list looks only while the person is typing an address with the app in front.
            .onChange(of: phase == .active && model.addressJoin == nil, initial: true) { _, typing in
                if typing { nearby.start() } else { nearby.stop() }
            }
            .onDisappear { nearby.stop() }
            .alert("Look at every address on this network?", isPresented: $askingSweep) {
                Button("Look") { nearby.sweepNetwork() }.accessibilityIdentifier("ssh-sweep-confirm")
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Infinitary tries each address here for a sign-in, which can look like probing to whoever runs the network. Only look on your own network.")
            }
        }.phoneSheetSurface()
    }

    private var typing: some View {
        Group {
            Text("Type your account and your computer, as you would sign in to it. Remote Login must be on in your Mac’s Sharing settings, or SSH on Linux.")
                .font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
            // Return in either field continues, as Continue does.
            TextField("kun@studio", text: $address)
                .textFieldStyle(.phone).keyboardType(.URL)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .submitLabel(.go).onSubmit(submit)
                .accessibilityIdentifier("ssh-address")
            TextField("Port (22)", text: $port)
                .textFieldStyle(.phone).keyboardType(.numberPad)
                .onSubmit(submit)
                .accessibilityIdentifier("ssh-port")
            onThisNetwork
            PhoneChoiceRow {
                Button("Continue", action: submit).buttonStyle(PhoneChoiceStyle(.primary))
                    .disabled(address.isEmpty).accessibilityIdentifier("ssh-continue")
            }
        }
    }

    /// INF-1312, the captain's answers on INF-1312: the computers here with Remote Login on, under a field for the
    /// account so a tap fills the whole address, and a sweep of the other addresses only after a yes.
    private var onThisNetwork: some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space2) {
            Text("On this network").font(PhoneFont.micro).textCase(.uppercase).foregroundStyle(PhoneTheme.secondary)
                .accessibilityAddTraits(.isHeader)
            let computers = nearby.computers
            if computers.isEmpty {
                Text(lookingWords).font(PhoneFont.caption)
                    .foregroundStyle(nearby.looking == .notAllowed ? PhoneTheme.warning : PhoneTheme.secondary)
                    .accessibilityIdentifier("nearby-ssh-state")
            } else {
                TextField("Your account", text: $account)
                    .textFieldStyle(.phone)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .accessibilityIdentifier("ssh-account")
                Text("Type your account, then tap your computer to fill its address.")
                    .font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
                PhoneList {
                    ForEach(computers) { computer in
                        Button { pick(computer) } label: {
                            PhoneRow(symbol: .computer, title: computer.name,
                                     line: computer.swept ? "Answers a sign-in, not announced" : computer.host,
                                     lineFont: computer.swept ? PhoneFont.caption : PhoneFont.data)
                        }.accessibilityIdentifier("nearby-ssh-" + computer.id)
                    }
                }.buttonStyle(PhoneRowStyle()).disabled(account.isEmpty)
            }
            switch nearby.sweep {
            case .idle:
                Button("Not listed? Look at every address on this network") { askingSweep = true }
                    .font(PhoneFont.caption).foregroundStyle(PhoneTheme.accent).buttonStyle(.borderless).frame(minHeight: 44)
                    .accessibilityIdentifier("ssh-sweep")
            case .sweeping(let addresses):
                HStack(spacing: PhoneTheme.space2) {
                    ProgressView()
                    Text("Trying \(addresses) addresses on this network…").font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
                }.frame(minHeight: 44).accessibilityIdentifier("ssh-sweeping")
            case .done:
                if !nearby.computers.contains(where: \.swept) {
                    Text("No other computer on this network answered a sign-in. You can still type an address.")
                        .font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary).accessibilityIdentifier("ssh-swept")
                }
            case .noNetwork:
                Text("This phone is not on a network it can look on. You can still type an address.")
                    .font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary).accessibilityIdentifier("ssh-swept")
            }
        }
    }

    /// The Mac's own list's words (`nearbyMacsWords`, src/shared/nearbyMacs.ts), with the phone's Settings.
    private var lookingWords: String {
        switch nearby.looking {
        case .looking: "Looking for computers on this network with Remote Login on…"
        case .notAllowed: "iOS has not let Infinitary look for computers on this network. Allow Local Network for Infinitary in Settings. You can still type an address."
        case .failed: "Could not look for computers on this network. You can still type an address."
        }
    }

    private func pick(_ computer: NearbyComputer) {
        address = "\(account.trimmingCharacters(in: .whitespaces))@\(computer.host)"
        port = computer.port == 22 ? "" : String(computer.port)
    }

    private func submit() { if !address.isEmpty { model.joinByAddress(address, port: port) } }

    // INF-1312: each step says what it has to say, then its reason, then its buttons in one row, the default last.
    @ViewBuilder private func step(_ join: AddressJoin) -> some View {
        let host = join.address.host
        switch join.step {
        case .working:
            ProgressView("Signing in to \(host)…").frame(maxWidth: .infinity).accessibilityIdentifier("ssh-working")
        case .trust(let key):
            Text("Is this \(host)?").font(PhoneFont.headline)
            Text("This phone has not signed in to \(host) before. Its fingerprint is:")
                .font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
            Text(key.fingerprint).font(PhoneFont.data).textSelection(.enabled)
                .padding(PhoneTheme.space3).frame(maxWidth: .infinity, alignment: .leading).phoneInput()
                .accessibilityIdentifier("ssh-fingerprint")
            Text("Only continue on your own network or with your own computer. This phone asks once, and stops if the fingerprint ever changes.")
                .font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
            problem(join)
            PhoneChoiceRow {
                Button("Not this one") { model.cancelAddressJoin(); close() }
                    .buttonStyle(PhoneChoiceStyle(.secondary)).accessibilityIdentifier("ssh-not-this-one")
                Button("Trust \(host)") { model.trustHome() }
                    .buttonStyle(PhoneChoiceStyle(.primary)).accessibilityIdentifier("ssh-trust")
            }
        case .keyRefused(let takesPassword):
            if takesPassword {
                Text("\(host) has not let this phone’s key in yet. Type your password there once, and Infinitary lets the key in. It keeps none of the password.")
                    .font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
                SecureField("Your password on \(host)", text: $password)
                    .textFieldStyle(.phone).textContentType(.password)
                    .accessibilityIdentifier("ssh-password")
                Text("Or copy this phone’s key to your account there, then try again.")
                    .font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
            } else {
                Text("\(host) did not let this phone’s key in, and it takes no password. Add this key to your account’s authorized keys there, then try again.")
                    .font(PhoneFont.callout).foregroundStyle(PhoneTheme.secondary)
            }
            if let line = model.sshKeyLine {
                // The key box carries its copy mark at its edge.
                HStack(alignment: .top, spacing: PhoneTheme.space2) {
                    Text(line).font(PhoneFont.micro).textSelection(.enabled).lineLimit(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("ssh-public-key")
                    Button { UIPasteboard.general.string = line; copied = true } label: {
                        PhoneSymbol.copy.image.frame(minWidth: 44, minHeight: 44)
                    }.buttonStyle(.borderless)
                        .accessibilityLabel(copied ? "Copied" : "Copy this phone’s key").accessibilityIdentifier("ssh-copy-key")
                }.padding(.leading, PhoneTheme.space3).padding(.top, PhoneTheme.space3).padding(.bottom, 2).phoneInput()
            }
            problem(join)
            PhoneChoiceRow {
                Button("Try again") { model.tryAddressAgain() }
                    .buttonStyle(PhoneChoiceStyle(takesPassword ? .secondary : .primary)).accessibilityIdentifier("ssh-try-again")
                if takesPassword {
                    Button("Sign in once") { let typed = password; password = ""; model.sendPassword(typed) }
                        .buttonStyle(PhoneChoiceStyle(.primary)).disabled(password.isEmpty)
                        .accessibilityIdentifier("ssh-send-password")
                }
            }
        case .stopped:
            problem(join)
            PhoneChoiceRow {
                Button("Try again") { model.tryAddressAgain() }
                    .buttonStyle(PhoneChoiceStyle(.primary)).accessibilityIdentifier("ssh-try-again")
            }
        }
    }

    @ViewBuilder private func problem(_ join: AddressJoin) -> some View {
        if let problem = join.problem {
            Text(problem).font(PhoneFont.callout).foregroundStyle(PhoneTheme.warning)
                .accessibilityIdentifier("ssh-problem")
        }
    }
}
