// swift-tools-version: 5.10

import PackageDescription

extension Target.Dependency {
    // UI & Presentation
    static let ui: Self = "UI"
    static let assets: Self = "Assets"

    // Data & Models
    static let models: Self = "Models"
    static let shared: Self = "Shared"

    // Core Services
    static let clipboardClient: Self = "ClipboardClient"
    static let analyticsClient: Self = "AnalyticsClient"
    static let aria2Kit: Self = "Aria2Kit"

    // External Dependencies
    static let swiftDependencies: Self = .product(name: "Dependencies", package: "swift-dependencies")
    static let swiftDependenciesMacros: Self = .product(name: "DependenciesMacros", package: "swift-dependencies")
    static let swiftSharing: Self = .product(name: "Sharing", package: "swift-sharing")
    static let identifiedCollections: Self = .product(name: "IdentifiedCollections", package: "swift-identified-collections")
    static let sauce: Self = .product(name: "Sauce", package: "Sauce")
    static let keyboardShortcuts: Self = .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
}

let package = Package(
    name: "PeerKit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "UI", targets: ["UI"]),
        .library(name: "Assets", targets: ["Assets"]),
        .library(name: "Models", targets: ["Models"]),
        .library(name: "ClipboardClient", targets: ["ClipboardClient"]),
        .library(name: "AnalyticsClient", targets: ["AnalyticsClient"]),
        .library(name: "Shared", targets: ["Shared"]),
        .library(name: "Aria2Kit", targets: ["Aria2Kit"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.11.0"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.1.1"),
        .package(url: "https://github.com/rurza/KeyboardShortcuts.git", branch: "main"),
        .package(url: "https://github.com/pointfreeco/swift-sharing.git", from: "2.7.4"),
        .package(url: "https://github.com/Clipy/Sauce.git", from: "2.4.1")
    ],
    targets: [
        .target(
            name: "UI",
            dependencies: [
                .models,
                .keyboardShortcuts,
                .assets
            ]
        ),
        .target(
            name: "Assets",
            resources: [.process("Resources")]
        ),
        .target(
            name: "Models",
            dependencies: [
                .keyboardShortcuts
            ]
        ),
        .target(
            name: "Shared",
            dependencies: [
                .identifiedCollections,
                .swiftSharing,
                .swiftDependencies,
                .swiftDependenciesMacros
            ]
        ),
        .target(
            name: "ClipboardClient",
            dependencies: [
                .swiftDependencies,
                .sauce
            ]
        ),
        .target(
            name: "AnalyticsClient",
            dependencies: [
                .models,
                .swiftDependencies,
                .swiftDependenciesMacros
            ]
        ),
        .target(
            name: "Aria2Kit",
            dependencies: [
                .models,
                .swiftDependencies,
                .swiftDependenciesMacros
            ]
        ),
        .testTarget(
            name: "Aria2KitTests",
            dependencies: [
                .aria2Kit,
                .swiftDependencies
            ]
        ),
        .testTarget(
            name: "ModelsTests",
            dependencies: [
                .models
            ]
        )
    ]
)
