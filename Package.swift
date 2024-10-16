// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "HDWalletKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "HDWalletKit",
            targets: ["HDWalletKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.8.1"),
        .package(url: "https://github.com/sunimp/SWCryptoKit.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.54.6"),
    ],
    targets: [
        .target(
            name: "HDWalletKit",
            dependencies: [
                "SWCryptoKit",
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "_CryptoExtras", package: "swift-crypto"),
            ]),
        .testTarget(
            name: "HDWalletKitTests",
            dependencies: [
                "HDWalletKit"
            ]),
    ]
)
