// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "vos",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(
      name: "vos",
      targets: ["vos"]
    )
  ],
  targets: [
    .executableTarget(
      name: "vos",
      path: "vos/vos"
    )
  ]
)
