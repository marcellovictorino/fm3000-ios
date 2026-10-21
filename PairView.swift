import FM3000Core
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// First launch: paste the link made in Settings > Devices on the Mac. Nothing is sent until
/// the person has read where it will connect and confirmed.
struct PairView: View {
    @ObservedObject var model: AppModel
    @State private var text = ""
    @State private var pending: PairingLink?
    @State private var working = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("On your Mac, open Firstmate 3000 > Settings > Devices, make a link for another computer, copy it, then paste it here. The link works once, for ten minutes. Tailscale must be on, on this phone and on the Mac.")
                        .font(.callout)
                }
                Section("Link") {
                    TextField("firstmate3000://join?…", text: $text, axis: .vertical).lineLimit(3...6).plainTextInput()
                    #if canImport(UIKit)
                    Button("Paste from clipboard") { text = UIPasteboard.general.string ?? text }
                    #endif
                }
                if let notice = model.notice {
                    Section { Text(notice).foregroundStyle(.red) }
                }
                Section {
                    Button(working ? "Pairing…" : "Review and pair") { review() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || working)
                }
            }
            .navigationTitle("Pair with your Mac")
            .iOSInlineTitle()
            .alert("Pair with this Mac?", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })) {
                Button("Cancel", role: .cancel) { pending = nil }
                Button("Pair") { pair() }
            } message: {
                if let link = pending {
                    Text("This phone will control Firstmate 3000 at \(link.at.description). Anything you type here counts as your own words, so pair only your own Mac.")
                }
            }
        }
    }

    private func review() {
        do { pending = try PairingLink.parse(text); model.notice = nil }
        catch { model.notice = error.localizedDescription }
    }

    private func pair() {
        let value = text
        pending = nil
        working = true
        Task {
            _ = await model.pair(withLink: value)
            working = false
            if model.isPaired { text = "" }
        }
    }
}
