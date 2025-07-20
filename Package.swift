// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package: Package = Package(
    name: "StreamBridge",
    platforms: [
        .macOS(.v14), .iOS(.v17),
    ],
    products: [
        .library(
            name: "StreamBridge",
            targets: ["StreamBridge"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.1"),
        .package(url: "https://github.com/objectbox/objectbox-swift-spm.git", from: "4.4.0"),
        .package(url: "https://github.com/wickwirew/Runtime", .upToNextMajor(from: "2.2.7")),
        .package(url: "https://github.com/stackotter/swift-macro-toolkit.git", from: "0.6.0"),
         .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.5.0")

    ],
    targets: [

        .target(
            name: "StreamBridge",
            dependencies: [
                "StreamBridgeMacros",
                .product(name: "ObjectBox.xcframework", package: "objectbox-swift-spm"),
            ]),
        .testTarget(
            name: "StreamBridgeTests",
            dependencies: ["StreamBridge"]
        ),
        .macro(
            name: "StreamBridgeMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "ObjectBox.xcframework", package: "objectbox-swift-spm"),
                .product(name: "Runtime", package: "Runtime"),
                .product(name: "MacroToolkit", package: "swift-macro-toolkit"),  // Added
            ]
        ),

        .testTarget(
            name: "StreamBridgeMacrosTests",
            dependencies: [
                "StreamBridgeMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                .product(name: "MacroTesting", package: "swift-macro-testing"),
            ]
        ),
    ]
)
