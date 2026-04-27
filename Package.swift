// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PodcastPilot",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "podcastpilot", targets: ["PodcastPilot"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "PodcastPilot",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/PodcastPilot",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "PodcastPilotTests",
            dependencies: ["PodcastPilot"],
            path: "Tests/PodcastPilotTests"
        ),
    ]
)
