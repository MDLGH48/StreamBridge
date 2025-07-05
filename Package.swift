// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ArrowStreamBridge",
    platforms: [
        .macOS(.v12),  // Or another platform your project targets
        .iOS(.v15),  // For iPhone and iPad support
    ],
    dependencies: [
        .package(url: "https://github.com/objectbox/objectbox-swift.git", from: "1.9.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package.
        // A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "ArrowStreamBridge",
            dependencies: [
                .product(name: "ObjectBox", package: "objectbox-swift")
            ]),
        .testTarget(
            name: "ArrowStreamBridgeTests",
            dependencies: ["ArrowStreamBridge"]),
    ]
)
