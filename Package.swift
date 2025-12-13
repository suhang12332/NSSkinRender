// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SkinRenderKit",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "SkinRenderKit",
      targets: ["SkinRenderKit"]
    )
  ],
  targets: [
    .target(
      name: "SkinRenderKit"
    )
  ]
)
