// swift-tools-version:5.9
import PackageDescription

// FM3000Core  - everything below the screens: pairing link, pin, device key and
//               certificate, TLS 1.3 dial, /pair, the /connection WebSocket, wire models.
// FM3000Model - the app's state and every request the screens make (no SwiftUI), so the
//               end-to-end run drives the real thing.
// FM3000WatchLink - what the phone and the Apple Watch say to each other (plain Codable messages, Foundation only), so the
//               watch app links nothing else.
// FM3000UI    - the SwiftUI screens. Needs Xcode's toolchain (SwiftUI's macros); the rest does not.
// fm-checks   - the test suite as a plain executable (this Mac has no XCTest).
// fm-probe    - a command line client built from the same core, for the fake Mac and for
//               trying a real pairing link from the Mac before the phone.
let package = Package(
    name: "FM3000",
    platforms: [.iOS(.v16), .macOS(.v13), .watchOS(.v10)],
    products: [
        .library(name: "FM3000Core", targets: ["FM3000Core"]),
        .library(name: "FM3000Model", targets: ["FM3000Model"]),
        .library(name: "FM3000UI", targets: ["FM3000UI"]),
        .library(name: "FM3000WatchLink", targets: ["FM3000WatchLink"]),
    ],
    targets: [
        .target(name: "FM3000Core"),
        .target(name: "FM3000WatchLink"),
        .target(name: "FM3000Model", dependencies: ["FM3000Core", "FM3000WatchLink"]),
        .target(name: "FM3000UI", dependencies: ["FM3000Core", "FM3000Model"]),
        .executableTarget(name: "fm-checks", dependencies: ["FM3000Core", "FM3000Model", "FM3000WatchLink"]),
        .executableTarget(name: "fm-probe", dependencies: ["FM3000Core", "FM3000Model", "FM3000WatchLink"]),
    ]
)
