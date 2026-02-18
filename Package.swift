// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ContextSwitcher",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ContextSwitcher",
            path: "ContextSwitcher"
        )
    ]
)
