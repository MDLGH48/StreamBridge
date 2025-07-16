// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StreamBridge",
    platforms: [
        .macOS(.v14), .iOS(.v17), .tvOS(.v17),
        .watchOS(.v10), .macCatalyst(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "StreamBridge",
            targets: ["StreamBridge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/objectbox/objectbox-swift.git", from: "4.3.0"),
        .package(url: "https://github.com/wickwirew/Runtime", .upToNextMajor(from: "2.2.7"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "StreamBridge", dependencies: [
                .product(name: "ObjectBox", package: "objectbox-swift"),
                .product(name: "Runtime", package: "Runtime")
            ]),
        .testTarget(
            name: "StreamBridgeTests",
            dependencies: ["StreamBridge"]
        ),
    ]
)
