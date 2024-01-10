// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to
// build this package.

import PackageDescription

let package = Package(
    name: "PasscodeLock",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "PasscodeLock",
            targets: ["PasscodeLock"]
        ),
    ],
    targets: [
        .target(
            name: "PasscodeLock",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
