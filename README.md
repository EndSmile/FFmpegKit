# FFmpegKit (Minimal Remux Build)

Forked from [kingslay/FFmpegKit](https://github.com/kingslay/FFmpegKit). This is a **minimal build** tailored for HLS-to-MP4 remuxing on iOS, stripped down from ~1.3 GB to ~10 MB.

## What's included

Only the three FFmpeg libraries needed for container-level remuxing (no encoding, decoding, or filtering):

| Library | Purpose |
|---------|---------|
| **Libavformat** | HLS demuxer, MPEGTS demuxer, MOV demuxer, MP4/MOV muxer |
| **Libavcodec** | Codec parameter copying, packet handling, parsers (H.264/HEVC/AAC) |
| **Libavutil** | Utility functions (dictionary, error codes, timestamps) |

### Enabled components

- **Demuxers:** hls, mpegts, mov
- **Muxers:** mp4, mov
- **Parsers:** h264, hevc, aac, mpegaudio
- **Protocols:** file, crypto, data, http, tcp, hls
- **BSFs:** h264_mp4toannexb, hevc_mp4toannexb, aac_adtstoasc

### What's removed (vs upstream)

All external libraries and unnecessary FFmpeg components:

- MoltenVK, Vulkan, libshaderc, libplacebo (GPU rendering)
- libass, libfreetype, libfribidi, libharfbuzz (subtitle rendering)
- gmp, nettle, hogweed, gnutls (TLS/crypto)
- libsmbclient (Samba)
- libsrt (SRT streaming)
- libdav1d (AV1 decoder)
- libmpv (media player)
- libzvbi, lcms2, libfontconfig, libbluray
- Libavfilter, Libavdevice, Libswscale, Libswresample
- All encoders, decoders, and filters

## Platforms

- iOS (arm64)
- iOS Simulator (arm64, x86_64)

## Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/EndSmile/FFmpegKit.git", branch: "main")
]
```

## Rebuilding

To rebuild the minimal xcframeworks from source:

```bash
brew install nasm
swift package --disable-sandbox BuildFFmpeg enable-FFmpeg platforms=ios,isimulator disableGPL
```

## License

FFmpeg is licensed under LGPL 3.0 (this build does not enable GPL).
