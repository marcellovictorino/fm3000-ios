// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "InfinitaryKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "InfinitaryKit", targets: ["InfinitaryKit"])],
    dependencies: [
        .package(url: "https://github.com/apple/swift-certificates.git", exact: "1.21.0"),
        // INF-1183: joining a home by its address signs in over SSH.
        .package(url: "https://github.com/apple/swift-nio-ssh.git", exact: "0.9.1"),
        .package(url: "https://github.com/apple/swift-nio.git", exact: "2.99.0"),
    ],
    targets: [
        .target(name: "InfinitaryKit", dependencies: [
            .product(name: "X509", package: "swift-certificates"),
            .product(name: "NIOSSH", package: "swift-nio-ssh"),
            .product(name: "NIOCore", package: "swift-nio"),
            .product(name: "NIOPosix", package: "swift-nio"),
        ]),
        .testTarget(name: "InfinitaryKitTests", dependencies: ["InfinitaryKit", .product(name: "NIOSSH", package: "swift-nio-ssh"), .product(name: "NIOCore", package: "swift-nio"), .product(name: "NIOPosix", package: "swift-nio")], resources: [.copy("Fixtures")]),
    ]
)
