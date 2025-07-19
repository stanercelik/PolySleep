// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PolyNapShared",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "PolyNapShared",
            targets: ["PolyNapShared"]
        )
    ],
    dependencies: [
        // SwiftData ve diğer gerekli framework'ler
    ],
    targets: [
        .target(
            name: "PolyNapShared",
            dependencies: [],
            path: "Sources/PolyNapShared",
            sources: [
                "Models",
                "Repository",
                "Services",
                "Utils"
            ],
            linkerSettings: [
                .linkedFramework("HealthKit")
            ]
        ),
        .testTarget(
            name: "PolyNapSharedTests",
            dependencies: ["PolyNapShared"]
        )
    ]
) 