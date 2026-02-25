// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ZMKHud",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ZMKHud", targets: ["ZMKHud"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ZMKHud",
            dependencies: ["Yams"],
            path: "Sources"
        ),
        .testTarget(
            name: "ZMKHudTests",
            dependencies: ["ZMKHud"],
            path: "Tests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
