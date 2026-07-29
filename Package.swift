// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CodexInfo",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "CodexInfo", targets: ["CodexInfo"])],
    targets: [
        .executableTarget(name: "CodexInfo"),
        .executableTarget(name: "ClaudeInfoBridge")
    ]
)
