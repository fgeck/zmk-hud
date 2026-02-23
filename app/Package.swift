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
    targets: [
        .executableTarget(
            name: "ZMKHud",
            path: "Sources"
        ),
        .testTarget(
            name: "ZMKHudTests",
            dependencies: ["ZMKHud"],
            path: "Tests"
        )
    ]
)
