// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bestline",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Bestline",
            targets: ["Bestline"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CBestline",
            sources: ["bestline.c"],
            publicHeadersPath: "."
        ),
        .target(
            name: "Bestline",
            dependencies: ["CBestline"]
        ),
        .testTarget(
            name: "BestlineTests",
            dependencies: ["Bestline"]
        ),
    ]
)
