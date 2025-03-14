// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "HTTP",
  platforms: [
    .iOS(.v13),
    .macCatalyst(.v13),
    .macOS(.v10_15),
    .watchOS(.v6),
    .tvOS(.v13),
  ],
  products: [
    .library(name: "HTTP", targets: ["HTTP"]),
    .library(name: "HTTPFoundation", targets: ["HTTPFoundation"]),
    .library(name: "HTTPMock", targets: ["HTTPMock"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-http-types", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "HTTP",
      dependencies: [
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
      ]
    ),
    .testTarget(
      name: "HTTPTests",
      dependencies: [
        "HTTP",
        "HTTPFoundation",
        "HTTPMock",
        .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
      ]
    ),
    .target(
      name: "HTTPFoundation",
      dependencies: [
        "HTTP"
      ]
    ),
    .target(name: "HTTPMock", dependencies: ["HTTP"]),
  ],
  swiftLanguageModes: [.v6]
)
