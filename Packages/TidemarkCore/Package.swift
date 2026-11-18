// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TidemarkCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TidemarkCore", targets: ["TidemarkCore"])
    ],
    targets: [
        .target(name: "TidemarkCore"),
        .testTarget(name: "TidemarkCoreTests", dependencies: ["TidemarkCore"])
    ]
)
