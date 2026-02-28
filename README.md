# MPVKit (AVFoundation Fork)

[![mpv](https://img.shields.io/badge/mpv-v0.40.0-blue.svg)](https://github.com/mpv-player/mpv)
[![ffmpeg](https://img.shields.io/badge/ffmpeg-n8.0-blue.svg)](https://github.com/FFmpeg/FFmpeg)
[![license](https://img.shields.io/badge/license-GPL--3.0-red.svg)](LICENSE)

This is a fork of [MPVKit](https://github.com/mpvkit/MPVKit) with **AVFoundation video output (`vo_avfoundation`)** support for iOS.

## Acknowledgments

Special thanks to the [MPVKit](https://github.com/mpvkit/MPVKit) team for creating and maintaining the original project that makes it possible to use `libmpv` on Apple platforms. This fork builds upon their excellent work.

Original project forked from [kingslay/FFmpegKit](https://github.com/kingslay/FFmpegKit).

## What's Different in This Fork?

This fork includes the **`vo_avfoundation`** video output driver, which:

- Renders video directly to `AVSampleBufferDisplayLayer`
- Enables **Picture-in-Picture (PiP)** support on iOS
- Uses hardware-accelerated VideoToolbox decoding
- Supports composite OSD for subtitle rendering in PiP

## ⭐ Support This Project

I'm doing this out of the goodness of my heart! If you find this project useful, please consider:

- ⭐ **Starring** this repository
- 👤 **Following** me on GitHub ([@Alexk2309](https://github.com/Alexk2309))

Your support helps me continue maintaining and improving this project. Thank you! 🙏

## License

**This fork is licensed under GPL v3.0.**

This build uses the GPL-licensed components including samba protocol support and other GPL libraries. By using this fork, you agree to the terms of the GPL v3.0 license.

See [LICENSE](LICENSE) for full details.

---

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Alexk2309/MPVKit.git", from: "0.40.0-av")
]
```

Or use Xcode: File → Add Package Dependencies → Enter `https://github.com/Alexk2309/MPVKit.git` → Select version `0.40.0-av` or later.

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'MPVKit-GPL', :git => 'https://github.com/Alexk2309/MPVKit.git', :tag => '0.40.0-av'
```

Then run:

```bash
pod install
```

### Usage

```swift
import Libmpv
```

## How to Build

```bash
make build
# specified platforms (ios,tvos,tvsimulator,isimulator)
make build platform=ios,tvos
# build GPL version
make build enable-gpl
# clean all build temp files and cache
make clean
# see help
make help
```

## Make Demo App Using the Local Build Version

If you want the demo app to use the local build version, you need to modify `Package.swift` to reference the local build xcframework file.

<details>
<summary>Click here for more information.</summary>
  
```
.binaryTarget(
    name: "Libmpv-GPL",
    path: "dist/release/Libmpv.xcframework.zip"
),
.binaryTarget(
    name: "Libavcodec-GPL",
    path: "dist/release/Libavcodec.xcframework.zip"
),
.binaryTarget(
    name: "Libavdevice-GPL",
    path: "dist/release/Libavdevice.xcframework.zip"
),
.binaryTarget(
    name: "Libavformat-GPL",
    path: "dist/release/Libavformat.xcframework.zip"
),
.binaryTarget(
    name: "Libavfilter-GPL",
    path: "dist/release/Libavfilter.xcframework.zip"
),
.binaryTarget(
    name: "Libavutil-GPL",
    path: "dist/release/Libavutil.xcframework.zip"
),
.binaryTarget(
    name: "Libswresample-GPL",
    path: "dist/release/Libswresample.xcframework.zip"
),
.binaryTarget(
    name: "Libswscale-GPL",
    path: "dist/release/Libswscale.xcframework.zip"
),
```

</details>

## Run Default mpv Player

```bash
./mpv.sh --input-commands='script-message display-stats-toggle' [url]
./mpv.sh --list-options
```

> Use <kbd>Shift</kbd>+<kbd>i</kbd> to show stats overlay

## Related Projects

* [moltenvk-build](https://github.com/mpvkit/moltenvk-build)
* [libplacebo-build](https://github.com/mpvkit/libplacebo-build)
* [libdovi-build](https://github.com/mpvkit/libdovi-build)
* [libshaderc-build](https://github.com/mpvkit/libshaderc-build)
* [libluajit-build](https://github.com/mpvkit/libluajit-build)
* [libass-build](https://github.com/mpvkit/libass-build)
* [libbluray-build](https://github.com/mpvkit/libbluray-build)
* [libsmbclient-build](https://github.com/mpvkit/libsmbclient-build)
* [gnutls-build](https://github.com/mpvkit/gnutls-build)
* [openssl-build](https://github.com/mpvkit/openssl-build)
