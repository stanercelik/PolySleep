// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PolySleep",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PolySleep",
            targets: ["PolySleep"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "PolySleep",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ]),
        .testTarget(
            name: "PolySleepTests",
            dependencies: ["PolySleep"]),
    ]
)
