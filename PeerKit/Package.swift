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
    static let aria2Client: Self = "Aria2Client"

    // External Dependencies
    static let swiftDependencies: Self = .product(name: "Dependencies", package: "swift-dependencies")
    static let swiftDependenciesMacros: Self = .product(name: "DependenciesMacros", package: "swift-dependencies")
    static let swiftSharing: Self = .product(name: "Sharing", package: "swift-sharing")
    static let identifiedCollections: Self = .product(name: "IdentifiedCollections", package: "swift-identified-collections")
    static let sauce: Self = .product(name: "Sauce", package: "Sauce")
    static let keyboardShortcuts: Self = .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
    static let alamofire: Self = .product(name: "Alamofire", package: "Alamofire")
    static let anyCodable: Self = .product(name: "AnyCodable", package: "AnyCodable")
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
        .library(name: "Aria2Client", targets: ["Aria2Client"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.7.0"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.1.0"),
        .package(url: "https://github.com/rurza/KeyboardShortcuts.git", branch: "main"),
        .package(url: "https://github.com/mixpanel/mixpanel-swift", branch: "master"),
        .package(url: "https://github.com/pointfreeco/swift-sharing.git", from: "2.4.0"),
        .package(url: "https://github.com/Clipy/Sauce.git", from: "2.4.1"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.1"),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.0")
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
            name: "Aria2Client",
            dependencies: [
                .models,
                .swiftDependencies,
                .swiftDependenciesMacros,
                .alamofire,
                .anyCodable
            ]
        )
    ]
)
