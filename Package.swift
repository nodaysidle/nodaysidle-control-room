// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NODAYSIDLEControlRoom",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ControlRoomCore", targets: ["ControlRoomCore"]),
        .executable(name: "NODAYSIDLEControlRoom", targets: ["ControlRoom"])
    ],
    targets: [
        .target(name: "ControlRoomCore"),
        .executableTarget(name: "ControlRoom", dependencies: ["ControlRoomCore"], resources: [.process("Resources")]),
        .testTarget(name: "ControlRoomCoreTests", dependencies: ["ControlRoomCore"])
    ]
)
