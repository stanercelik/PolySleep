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
        // Supabase bağımlılığı kaldırıldı
    ],
    targets: [
        .target(
            name: "PolySleep",
            dependencies: [
                // Supabase bağımlılığı kaldırıldı
            ]),
        .testTarget(
            name: "PolySleepTests",
            dependencies: ["PolySleep"]),
    ]
)
