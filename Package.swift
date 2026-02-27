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
            checksum: "d79795fb32fd71cee343514fbdd51d9a5df2cc94a3c5e7685c3f8098ec390c25"
        ),
    ]
)
