// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "InPurchase")

package.platforms = [
    .iOS(.v15),
    .tvOS(.v15),
//    .watchOS(.v7),
    .macOS(.v12),
//    .xrOS(.v1)
]

package.products = [
    .library(name: "InPurchase", targets: ["InPurchase"]),
]

package.targets = [
    .target(name: "InPurchase"),
]

package.swiftLanguageVersions = [.v5]
