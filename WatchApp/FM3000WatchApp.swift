import FM3000WatchLink
import SwiftUI

@main
struct FM3000WatchApp: App {
    @StateObject private var model = WatchModel()

    var body: some Scene {
        WindowGroup { WatchRoot(model: model) }
    }
}
