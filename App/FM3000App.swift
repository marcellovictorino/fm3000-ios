import FM3000Core
import FM3000Model
import FM3000UI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct FM3000App: App {
    @StateObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    /// Answers the Apple Watch, which asks this phone because it cannot reach the Mac itself.
    private let watchBridge: PhoneWatchBridge

    init() {
        let model = AppModel(grants: KeychainGrantStore(), identities: KeychainIdentityStore(), deviceName: Self.deviceName())
        _model = StateObject(wrappedValue: model)
        watchBridge = PhoneWatchBridge(model: model)
        watchBridge.activate()
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .onOpenURL { url in if !model.isPaired { model.incomingLink = url.absoluteString } }
                .task {
                    #if DEBUG
                    // Simulator runs: `-pairLink <link>` pairs without typing, so a script can drive the app.
                    // Only in debug builds; a release build never reads a link from its launch arguments.
                    let arguments = ProcessInfo.processInfo.arguments
                    if let flag = arguments.firstIndex(of: "-pairLink"), flag + 1 < arguments.count, !model.isPaired {
                        _ = await model.pair(withLink: arguments[flag + 1])
                    }
                    #endif
                    model.start()
                }
                .onChange(of: scenePhase) { _, phase in
                    // iOS closes sockets in the background; the app catches up with its cursor on return.
                    watchBridge.appIsActive = phase == .active
                    if phase == .active { model.start() } else if phase == .background { model.stop() }
                }
        }
    }

    /// The label the Mac lists this phone by: Settings > Devices shows it.
    static func deviceName() -> String {
        #if canImport(UIKit)
        let raw = UIDevice.current.name
        #else
        let raw = "iPhone"
        #endif
        let clean = raw.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }.map(String.init).joined()
        let trimmed = String(clean.prefix(64)).trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "iPhone" : trimmed
    }
}
