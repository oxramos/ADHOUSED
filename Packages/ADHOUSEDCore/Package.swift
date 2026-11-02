// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ADHOUSEDCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "ADHOUSEDCore",
            targets: ["ADHOUSEDCore"]
        )
    ],
    targets: [
        .target(
            name: "ADHOUSEDCore",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "ADHOUSEDCoreTests",
            dependencies: ["ADHOUSEDCore"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
