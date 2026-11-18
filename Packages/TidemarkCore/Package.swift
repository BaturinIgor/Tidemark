// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TidemarkCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TidemarkCore", targets: ["TidemarkCore"])
    ],
    targets: [
        .target(name: "TidemarkCore", resources: [.process("Resources")]),
        .testTarget(name: "TidemarkCoreTests", dependencies: ["TidemarkCore"])
    ]
)
