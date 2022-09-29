// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PacketProtocol",
    platforms: [
        .iOS(.v14),
        .watchOS(.v7),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "PacketProtocol",
            targets: ["PacketProtocol"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(name: "PacketProtocol"),
        .testTarget(
            name: "PacketProtocolTests",
            dependencies: ["PacketProtocol"],
            resources: [.copy("TestData"),]),
    ]
)
