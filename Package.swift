// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Fetch",
  platforms: [
    .iOS(.v13),
    .macCatalyst(.v13),
    .macOS(.v10_15),
    .watchOS(.v6),
    .tvOS(.v13),
  ],
  products: [
    .library(name: "Fetch", targets: ["Fetch"]),
    .library(name: "FetchFoundation", targets: ["FetchFoundation"]),
    .library(name: "FetchMock", targets: ["FetchMock"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras.git", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "Fetch",
      dependencies: [.product(name: "ConcurrencyExtras", package: "swift-concurrency-extras")]),
    .testTarget(
      name: "FetchTests",
      dependencies: [
        "Fetch",
        "FetchFoundation",
        "FetchMock",
      ]
    ),
    .target(
      name: "FetchFoundation",
      dependencies: [
        "Fetch"
      ]
    ),
    .target(name: "FetchMock", dependencies: ["Fetch"]),
  ]
)
