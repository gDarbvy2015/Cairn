// swift-tools-version: 6.0
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
  targets: [
    .target(name: "Fetch"),
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
  ],
  swiftLanguageModes: [.v6]
)
