// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "MPVKit",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13)],
    products: [
        .library(
            name: "MPVKit",
            targets: ["_MPVKit"]
        ),
        .library(
            name: "MPVKit-GPL",
            targets: ["_MPVKit-GPL"]
        ),
    ],
    targets: [
        .target(
            name: "_MPVKit",
            dependencies: [
                "Libmpv", "_FFmpeg", "Libuchardet", "Libbluray",
                .target(name: "Libluajit", condition: .when(platforms: [.macOS])),
            ],
            path: "Sources/_MPVKit",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreAudio"),
            ]
        ),
        .target(
            name: "_FFmpeg",
            dependencies: [
                "Libavcodec", "Libavdevice", "Libavfilter", "Libavformat", "Libavutil", "Libswresample", "Libswscale",
                "Libssl", "Libcrypto", "Libass", "Libfreetype", "Libfribidi", "Libharfbuzz",
                "MoltenVK", "Libshaderc_combined", "lcms2", "Libplacebo", "Libdovi", "Libunibreak",
                "gmp", "nettle", "hogweed", "gnutls", "Libdav1d", "Libuavs3d"
            ],
            path: "Sources/_FFmpeg",
            linkerSettings: [
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("Metal"),
                .linkedFramework("VideoToolbox"),
                .linkedLibrary("bz2"),
                .linkedLibrary("iconv"),
                .linkedLibrary("expat"),
                .linkedLibrary("resolv"),
                .linkedLibrary("xml2"),
                .linkedLibrary("z"),
                .linkedLibrary("c++"),
            ]
        ),
        .target(
            name: "_MPVKit-GPL",
            dependencies: [
                "Libmpv-GPL", "_FFmpeg-GPL", "Libuchardet", "Libbluray",
                .target(name: "Libluajit", condition: .when(platforms: [.macOS])),
            ],
            path: "Sources/_MPVKit-GPL",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreAudio"),
            ]
        ),
        .target(
            name: "_FFmpeg-GPL",
            dependencies: [
                "Libavcodec-GPL", "Libavdevice-GPL", "Libavfilter-GPL", "Libavformat-GPL", "Libavutil-GPL", "Libswresample-GPL", "Libswscale-GPL",
                "Libssl", "Libcrypto", "Libass", "Libfreetype", "Libfribidi", "Libharfbuzz",
                "MoltenVK", "Libshaderc_combined", "lcms2", "Libplacebo", "Libdovi", "Libunibreak",
                "Libsmbclient", "gmp", "nettle", "hogweed", "gnutls", "Libdav1d", "Libuavs3d"
            ],
            path: "Sources/_FFmpeg-GPL",
            linkerSettings: [
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("Metal"),
                .linkedFramework("VideoToolbox"),
                .linkedLibrary("bz2"),
                .linkedLibrary("iconv"),
                .linkedLibrary("expat"),
                .linkedLibrary("resolv"),
                .linkedLibrary("xml2"),
                .linkedLibrary("z"),
                .linkedLibrary("c++"),
            ]
        ),

        // GPL versions - using release binaries from avfoundation-support branch
        .binaryTarget(
            name: "Libmpv-GPL",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libmpv.xcframework.zip",
            checksum: "651a2bd6c43fdb38c940be4f1954b9a142456c50765609d3d1f1e4e5a48b5f94"
        ),
        .binaryTarget(
            name: "Libavcodec-GPL",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libavcodec.xcframework.zip",
            checksum: "742e188119efc6f62e22739401b7545277c8e0cab40df4b077b427eac4ea4e7d"
        ),
        .binaryTarget(
            name: "Libavdevice-GPL",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libavdevice.xcframework.zip",
            checksum: "0a806764fea4fda05095b7626df216029ef03246c42599d793e788384124ef11"
        ),
        .binaryTarget(
            name: "Libavformat-GPL",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libavformat.xcframework.zip",
            checksum: "23c53227f19d10c73b1faf39a328c846b3d8b47310045df7abe3eb3292005b12"
        ),
        .binaryTarget(
            name: "Libavfilter-GPL",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libavfilter.xcframework.zip",
            checksum: "45d091004e54720cee1c6098da1602a60b09e6ede01db83e4593ffafcbab740f"
        ),
        .binaryTarget(
            name: "Libavutil-GPL",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libavutil.xcframework.zip",
            checksum: "805ff8ae222ff68fe5dab2871fb583ec63e6aacdc0355e71e627691d9273ee5e"
        ),
        .binaryTarget(
            name: "Libswresample-GPL",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libswresample.xcframework.zip",
            checksum: "961da78874dff928b9011353b6a28e111b0d8ba4ee55c46c0148eb914a0a53ae"
        ),
        .binaryTarget(
            name: "Libswscale-GPL",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libswscale.xcframework.zip",
            checksum: "1d0559cce3579691bad0abb141f593b6185592832719da1d74a9342b72c3cb97"
        ),
        //AUTO_GENERATE_TARGETS_BEGIN//

        .binaryTarget(
            name: "Libcrypto",
            url: "https://github.com/mpvkit/openssl-build/releases/download/3.3.2-xcode/Libcrypto.xcframework.zip",
            checksum: "2ee7fc0fa9c7c7fbdfcad0803d34ea3143456943681fdab6cf8cf094f4253053"
        ),
        .binaryTarget(
            name: "Libssl",
            url: "https://github.com/mpvkit/openssl-build/releases/download/3.3.2-xcode/Libssl.xcframework.zip",
            checksum: "cc57f4dd19659ddeaff1ff440764d0b439a6a93c8c4617241ba1243aa9fe5ad7"
        ),

        .binaryTarget(
            name: "gmp",
            url: "https://github.com/mpvkit/gnutls-build/releases/download/3.8.8-xcode/gmp.xcframework.zip",
            checksum: "019faab8625fedb38bb934fafb73a547c9cb29ccdeabfd3998256d1ea0760e2c"
        ),

        .binaryTarget(
            name: "nettle",
            url: "https://github.com/mpvkit/gnutls-build/releases/download/3.8.8-xcode/nettle.xcframework.zip",
            checksum: "bd4dbeea46a9abc02797c2f503d79636ee09b8a5f8ed4d2bbe2cc00e29c066cb"
        ),
        .binaryTarget(
            name: "hogweed",
            url: "https://github.com/mpvkit/gnutls-build/releases/download/3.8.8-xcode/hogweed.xcframework.zip",
            checksum: "48c300eadfbe61ab08b56a08fc5b979c84839c8bba665caf6515079949db0cbf"
        ),

        .binaryTarget(
            name: "gnutls",
            url: "https://github.com/mpvkit/gnutls-build/releases/download/3.8.8-xcode/gnutls.xcframework.zip",
            checksum: "8be5568b3bcaa7378e470b6eb2b11f1af86b5d5637229d1d3eb725a2e0c4b9da"
        ),

        // Local libass 0.17.4 builds (from avfoundation-support release)
        .binaryTarget(
            name: "Libunibreak",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libunibreak.xcframework.zip",
            checksum: "cd0d2e9f1be69aa2c83cb1325494bba2410e18e7f87f8570634a5228e771990c"
        ),

        .binaryTarget(
            name: "Libfreetype",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libfreetype.xcframework.zip",
            checksum: "5c8cdb23ecf4c16646c77bf0ee0b4382e088a14c548baf3dc25f53ad77741353"
        ),

        .binaryTarget(
            name: "Libfribidi",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libfribidi.xcframework.zip",
            checksum: "54227fe68fc35a12033550f727f5beebcf00ebc6f59f6b5a3965f75384a9017c"
        ),

        .binaryTarget(
            name: "Libharfbuzz",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libharfbuzz.xcframework.zip",
            checksum: "dbdc09260566195c0c9feb0e752a95f2607170233ef5dc01dcdfec1aede2c277"
        ),

        .binaryTarget(
            name: "Libass",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libass.xcframework.zip",
            checksum: "4ce1f49e45c31e88bf8f6bc11eb5d76c92622ec3cf2547e0b1ecc7d89b3eb3ef"
        ),

        .binaryTarget(
            name: "Libsmbclient",
            url: "https://github.com/mpvkit/libsmbclient-build/releases/download/4.15.13-xcode/Libsmbclient.xcframework.zip",
            checksum: "eca7ec0f3a226441c051773e2742670c85a2de522957b3580d3ccd65071281e5"
        ),

        .binaryTarget(
            name: "Libbluray",
            url: "https://github.com/mpvkit/libbluray-build/releases/download/1.3.4-xcode/Libbluray.xcframework.zip",
            checksum: "24d313a3a8808b95bd9bda7338ff9ec2141748cc172920b7733a435b2f39a690"
        ),

        .binaryTarget(
            name: "Libuavs3d",
            url: "https://github.com/mpvkit/libuavs3d-build/releases/download/1.2.1-xcode/Libuavs3d.xcframework.zip",
            checksum: "1e69250279be9334cd2f6849abdc884c8e4bb29212467b6f071fdc1ac2010b6b"
        ),

        .binaryTarget(
            name: "Libdovi",
            url: "https://github.com/mpvkit/libdovi-build/releases/download/3.3.1-xcode/Libdovi.xcframework.zip",
            checksum: "20021f2644da6986ae4ee456d8f917774f7c1324532843ff795ac3034ee7c88e"
        ),

        .binaryTarget(
            name: "MoltenVK",
            url: "https://github.com/mpvkit/moltenvk-build/releases/download/1.4.0-xcode/MoltenVK.xcframework.zip",
            checksum: "37cfd1af378058883f5c961966477cd6accf9923f0e48e0dfa2cf42a95b797fc"
        ),

        .binaryTarget(
            name: "Libshaderc_combined",
            url: "https://github.com/mpvkit/libshaderc-build/releases/download/2025.4.0-xcode/Libshaderc_combined.xcframework.zip",
            checksum: "dad5fe829dde498f41680f37adebac993fd7c04751042be2d79895eea5b24fb5"
        ),

        .binaryTarget(
            name: "lcms2",
            url: "https://github.com/mpvkit/lcms2-build/releases/download/2.16.0-xcode/lcms2.xcframework.zip",
            checksum: "9a08673dce386b0f75f6505ccb58df1f17421bffe035a6aebd4ab532fdc77274"
        ),

        .binaryTarget(
            name: "Libplacebo",
            url: "https://github.com/mpvkit/libplacebo-build/releases/download/7.351.0-xcode/Libplacebo.xcframework.zip",
            checksum: "75ec29cf670b4319509065f6c3b6acd99a220be372ac849b428e8bcba377b3f5"
        ),

        .binaryTarget(
            name: "Libdav1d",
            url: "https://github.com/mpvkit/libdav1d-build/releases/download/1.5.2-xcode/Libdav1d.xcframework.zip",
            checksum: "8a8b78e23e28ecc213232805f3c1936141fc9befe113e87234f4f897f430a532"
        ),

        .binaryTarget(
            name: "Libavcodec",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libavcodec.xcframework.zip",
            checksum: "742e188119efc6f62e22739401b7545277c8e0cab40df4b077b427eac4ea4e7d"
        ),
        .binaryTarget(
            name: "Libavdevice",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libavdevice.xcframework.zip",
            checksum: "0a806764fea4fda05095b7626df216029ef03246c42599d793e788384124ef11"
        ),
        .binaryTarget(
            name: "Libavformat",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libavformat.xcframework.zip",
            checksum: "23c53227f19d10c73b1faf39a328c846b3d8b47310045df7abe3eb3292005b12"
        ),
        .binaryTarget(
            name: "Libavfilter",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libavfilter.xcframework.zip",
            checksum: "45d091004e54720cee1c6098da1602a60b09e6ede01db83e4593ffafcbab740f"
        ),
        .binaryTarget(
            name: "Libavutil",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libavutil.xcframework.zip",
            checksum: "805ff8ae222ff68fe5dab2871fb583ec63e6aacdc0355e71e627691d9273ee5e"
        ),
        .binaryTarget(
            name: "Libswresample",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libswresample.xcframework.zip",
            checksum: "961da78874dff928b9011353b6a28e111b0d8ba4ee55c46c0148eb914a0a53ae"
        ),
        .binaryTarget(
            name: "Libswscale",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libswscale.xcframework.zip",
            checksum: "1d0559cce3579691bad0abb141f593b6185592832719da1d74a9342b72c3cb97"
        ),

        .binaryTarget(
            name: "Libuchardet",
            url: "https://github.com/mpvkit/libuchardet-build/releases/download/0.0.8-xcode/Libuchardet.xcframework.zip",
            checksum: "503202caa0dafb6996b2443f53408a713b49f6c2d4a26d7856fd6143513a50d7"
        ),

        .binaryTarget(
            name: "Libluajit",
            url: "https://github.com/mpvkit/libluajit-build/releases/download/2.1.0-xcode/Libluajit.xcframework.zip",
            checksum: "8e76f267ee100ff5f3bbde7641b2240566df722241cdf8e135be7ef3d29e237a"
        ),

        .binaryTarget(
            name: "Libmpv",
            url: "https://github.com/Alexk2309/MPVKit/releases/download/avfoundation-support/Libmpv.xcframework.zip",
            checksum: "651a2bd6c43fdb38c940be4f1954b9a142456c50765609d3d1f1e4e5a48b5f94"
        ),
        //AUTO_GENERATE_TARGETS_END//
    ]
)