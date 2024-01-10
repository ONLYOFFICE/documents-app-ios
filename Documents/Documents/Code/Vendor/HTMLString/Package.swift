// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to
// build this package.

import PackageDescription

let package = Package(
    name: "HTMLString",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "HTMLString",
            targets: ["HTMLString"]
        ),
    ],
    targets: [
        .target(
            name: "HTMLString"
        ),
        .testTarget(
            name: "HTMLStringTests",
            dependencies: [
                "HTMLString",
            ]
        ),
    ]
)
