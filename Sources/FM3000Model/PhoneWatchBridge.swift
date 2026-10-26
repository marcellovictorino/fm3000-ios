#if os(iOS)
import FM3000WatchLink
import Foundation
import WatchConnectivity

/// The phone's side of the watch: answers each message the watch sends with `WatchService`. A message from the watch wakes this app
/// in the background, so the bridge starts the connection itself, and stops it again afterwards when the app is not on screen.
@MainActor
public final class PhoneWatchBridge: NSObject, WCSessionDelegate {
    private let service: WatchService
    private let model: AppModel
    /// Set by the app: true while its window is on screen (false until the first scene change tells it), so a background wake knows to stop the connection after it answers.
    public var appIsActive = false

    public init(model: AppModel) {
        self.model = model
        service = WatchService(model: model)
        super.init()
    }

    public func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    public nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    public nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    public nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    public nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let request = WatchWire.request(from: message) else {
            replyHandler(WatchWire.message(WatchReply(cards: nil, problem: "The phone did not understand that.")))
            return
        }
        nonisolated(unsafe) let reply = replyHandler
        Task { @MainActor in
            let answer = await service.handle(request)
            reply(WatchWire.message(answer))
            if !appIsActive { model.stop() }
        }
    }
}
#endif
