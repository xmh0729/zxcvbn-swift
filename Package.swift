// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Zxcvbn",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "Zxcvbn",
            targets: ["Zxcvbn"]
        ),
    ],
    targets: [
        .target(
            name: "Zxcvbn"
        ),
        .testTarget(
            name: "ZxcvbnTests",
            dependencies: ["Zxcvbn"]
        ),
        .executableTarget(
            name: "ZxcvbnTestRunner",
            dependencies: ["Zxcvbn"],
            path: "Tests/ZxcvbnTestRunner"
        ),
    ]
)
