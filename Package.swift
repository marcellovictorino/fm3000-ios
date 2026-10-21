// swift-tools-version:5.9
import PackageDescription

// FM3000Core  - everything below the screens: pairing link, pin, device key and
//               certificate, TLS 1.3 dial, /pair, the /connection WebSocket, wire models.
// FM3000UI    - the SwiftUI screens and the model behind them. Builds for macOS too, so
//               it is type-checked without an iOS SDK.
// fm-checks   - the test suite as a plain executable (this Mac has no XCTest).
// fm-probe    - a command line client built from the same core, for the fake Mac and for
//               trying a real pairing link from the Mac before the phone.
let package = Package(
    name: "FM3000",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "FM3000Core", targets: ["FM3000Core"]),
        .library(name: "FM3000UI", targets: ["FM3000UI"]),
    ],
    targets: [
        .target(name: "FM3000Core"),
        .target(name: "FM3000UI", dependencies: ["FM3000Core"]),
        .executableTarget(name: "fm-checks", dependencies: ["FM3000Core", "FM3000UI"]),
        .executableTarget(name: "fm-probe", dependencies: ["FM3000Core", "FM3000UI"]),
    ]
)
