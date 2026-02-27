// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "MPVKit",
    platforms: [.iOS(.v13), .tvOS(.v13)],
    products: [
        .library(
            name: "MPVKit-GPL",
            targets: ["_MPVKit-GPL"]
        ),
    ],
    targets: [
        .target(
            name: "_MPVKit-GPL",
            dependencies: ["MPVKit"],
            path: "Sources/_MPVKit-GPL",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("Metal"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("VideoToolbox"),
                .linkedLibrary("bz2"),
                .linkedLibrary("iconv"),
                .linkedLibrary("xml2"),
                .linkedLibrary("z"),
                .linkedLibrary("c++"),
                .linkedLibrary("resolv"),
                .linkedLibrary("expat"),
            ]
        ),
        // Combined framework - includes libmpv, FFmpeg, and all dependencies
        .binaryTarget(
            name: "MPVKit",
            url: "https://github.com/streamyfin/MPVKit/releases/download/0.40.0-av/MPVKit-GPL-Frameworks.zip",
            checksum: "5c5e7f48fb64674ab5880fbbd39a16e0fda527b0a3bdc4614d1f79e9eacf48a2"
        ),
    ]
)
