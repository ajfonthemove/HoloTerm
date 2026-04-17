// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Terminal",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.4")
    ],
    targets: [
        .executableTarget(
            name: "Terminal",
            dependencies: ["SwiftTerm"]
        )
    ]
)
