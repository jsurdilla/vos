// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VoiceOS",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "VoiceOS",
            targets: ["VoiceOS"]
        )
    ],
    targets: [
        .executableTarget(
            name: "VoiceOS",
            path: "VoiceOS/VoiceOS"
        )
    ]
)
