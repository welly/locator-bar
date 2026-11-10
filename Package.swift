// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LocatorBar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "LocatorBar",
            path: "Sources/LocatorBar",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
