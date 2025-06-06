// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PolyNap",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PolyNap",
            targets: ["PolyNap"]),
    ],
    dependencies: [
        // Supabase bağımlılığı kaldırıldı
    ],
    targets: [
        .target(
            name: "PolyNap",
            dependencies: [
                // Supabase bağımlılığı kaldırıldı
            ]),
        .testTarget(
            name: "PolyNapTests",
            dependencies: ["PolyNap"]),
    ]
)
