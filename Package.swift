// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "core-database",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CoreDatabase",
            targets: ["CoreDatabase"]
        ),
    ],
    dependencies: [
        .package(name: "Overture", url: "https://github.com/pointfreeco/swift-overture.git", from: "0.5.0"),
        .package(name: "core", url: "https://github.com/Qase/swift-core.git", .branch("master")),
        .package(name: "overture-operators", url: "https://github.com/Qase/swift-overture-operators.git", .branch("master")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CoreDatabase",
            dependencies: [
                "Overture",
                .product(name: "Core", package: "core"),
                .product(name: "OvertureOperators", package: "overture-operators"),
            ]
        ),
        .testTarget(
            name: "CoreDatabaseTests",
            dependencies: ["CoreDatabase"]
        ),
    ]
)
