// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TinyTask",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "TinyTask", targets: ["TinyRecorder"])
    ],
    targets: [
        .executableTarget(
            name: "TinyRecorder",
            path: "Sources/TinyRecorder"
        ),
        .testTarget(name: "TinyRecorderTests", dependencies: ["TinyRecorder"])
    ]
)
