//
//  BuildFFMPEG.swift
//
//
//  Created by kintan on 12/26/23.
//

import Foundation

class BuildFFMPEG: BaseBuild {
    init() {
        super.init(library: .FFmpeg)
        if Utility.shell("which nasm") == nil {
            Utility.shell("brew install nasm")
        }
        if Utility.shell("which sdl2-config") == nil {
            Utility.shell("brew install sdl2")
        }
        let lldbFile = URL.currentDirectory + "LLDBInitFile"
        try? FileManager.default.removeItem(at: lldbFile)
        FileManager.default.createFile(atPath: lldbFile.path, contents: nil, attributes: nil)
        let path = directoryURL + "libavcodec/videotoolbox.c"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: "kCVPixelBufferOpenGLESCompatibilityKey", with: "kCVPixelBufferMetalCompatibilityKey")
            str = str.replacingOccurrences(of: "kCVPixelBufferIOSurfaceOpenGLTextureCompatibilityKey", with: "kCVPixelBufferMetalCompatibilityKey")
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
    }

    override func flagsDependencelibrarys() -> [Library] {
        []
    }

    override func frameworks() throws -> [String] {
        var frameworks: [String] = []
        if let platform = platforms().first {
            if let arch = platform.architectures.first {
                let lib = thinDir(platform: platform, arch: arch) + "lib"
                let fileNames = try FileManager.default.contentsOfDirectory(atPath: lib.path)
                for fileName in fileNames {
                    if fileName.hasPrefix("lib"), fileName.hasSuffix(".a") {
                        // 因为其他库也可能引入libavformat,所以把lib改成大写，这样就可以排在前面，覆盖别的库。
                        frameworks.append("Lib" + fileName.dropFirst(3).dropLast(2))
                    }
                }
            }
        }
        return frameworks
    }

    override func ldFlags(platform: PlatformType, arch: ArchType) -> [String] {
        var ldFlags = super.ldFlags(platform: platform, arch: arch)
        ldFlags.append("-lc++")
        return ldFlags
    }

    override func environment(platform: PlatformType, arch: ArchType) -> [String: String] {
        var env = super.environment(platform: platform, arch: arch)
        env["CPPFLAGS"] = env["CFLAGS"]
        return env
    }

    override func build(platform: PlatformType, arch: ArchType, buildURL: URL) throws {
        try super.build(platform: platform, arch: arch, buildURL: buildURL)
        let prefix = thinDir(platform: platform, arch: arch)
        let lldbFile = URL.currentDirectory + "LLDBInitFile"
        if let data = FileManager.default.contents(atPath: lldbFile.path), var str = String(data: data, encoding: .utf8) {
            str.append("settings \(str.isEmpty ? "set" : "append") target.source-map \((buildURL + "src").path) \(directoryURL.path)\n")
            try str.write(toFile: lldbFile.path, atomically: true, encoding: .utf8)
        }
        try FileManager.default.copyItem(at: buildURL + "config.h", to: prefix + "include/libavutil/config.h")
        try FileManager.default.copyItem(at: buildURL + "config.h", to: prefix + "include/libavcodec/config.h")
        try FileManager.default.copyItem(at: buildURL + "config.h", to: prefix + "include/libavformat/config.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/getenv_utf8.h", to: prefix + "include/libavutil/getenv_utf8.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/libm.h", to: prefix + "include/libavutil/libm.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/thread.h", to: prefix + "include/libavutil/thread.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/intmath.h", to: prefix + "include/libavutil/intmath.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/mem_internal.h", to: prefix + "include/libavutil/mem_internal.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/attributes_internal.h", to: prefix + "include/libavutil/attributes_internal.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavcodec/mathops.h", to: prefix + "include/libavcodec/mathops.h")
        try FileManager.default.copyItem(at: buildURL + "src/libavformat/os_support.h", to: prefix + "include/libavformat/os_support.h")
        let internalPath = prefix + "include/libavutil/internal.h"
        try FileManager.default.copyItem(at: buildURL + "src/libavutil/internal.h", to: internalPath)
        if let data = FileManager.default.contents(atPath: internalPath.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: """
            #include "timer.h"
            """, with: """
            // #include "timer.h"
            """)
            str = str.replacingOccurrences(of: "kCVPixelBufferIOSurfaceOpenGLTextureCompatibilityKey", with: "kCVPixelBufferMetalCompatibilityKey")
            try str.write(toFile: internalPath.path, atomically: true, encoding: .utf8)
        }
        if platform == .macos, arch.executable {
            let fftoolsFile = URL.currentDirectory + "../Sources/fftools"
            try? FileManager.default.removeItem(at: fftoolsFile)
            if !FileManager.default.fileExists(atPath: (fftoolsFile + "include/compat").path) {
                try FileManager.default.createDirectory(at: fftoolsFile + "include/compat", withIntermediateDirectories: true)
            }
            try FileManager.default.copyItem(at: buildURL + "src/compat/va_copy.h", to: fftoolsFile + "include/compat/va_copy.h")
            try FileManager.default.copyItem(at: buildURL + "config.h", to: fftoolsFile + "include/config.h")
            try FileManager.default.copyItem(at: buildURL + "config_components.h", to: fftoolsFile + "include/config_components.h")
            if !FileManager.default.fileExists(atPath: (fftoolsFile + "include/libavdevice").path) {
                try FileManager.default.createDirectory(at: fftoolsFile + "include/libavdevice", withIntermediateDirectories: true)
            }
            try FileManager.default.copyItem(at: buildURL + "src/libavdevice/avdevice.h", to: fftoolsFile + "include/libavdevice/avdevice.h")
            try FileManager.default.copyItem(at: buildURL + "src/libavdevice/version_major.h", to: fftoolsFile + "include/libavdevice/version_major.h")
            try FileManager.default.copyItem(at: buildURL + "src/libavdevice/version.h", to: fftoolsFile + "include/libavdevice/version.h")
            if !FileManager.default.fileExists(atPath: (fftoolsFile + "include/libpostproc").path) {
                try FileManager.default.createDirectory(at: fftoolsFile + "include/libpostproc", withIntermediateDirectories: true)
            }
            try FileManager.default.copyItem(at: buildURL + "src/libpostproc/postprocess_internal.h", to: fftoolsFile + "include/libpostproc/postprocess_internal.h")
            try FileManager.default.copyItem(at: buildURL + "src/libpostproc/postprocess.h", to: fftoolsFile + "include/libpostproc/postprocess.h")
            try FileManager.default.copyItem(at: buildURL + "src/libpostproc/version_major.h", to: fftoolsFile + "include/libpostproc/version_major.h")
            try FileManager.default.copyItem(at: buildURL + "src/libpostproc/version.h", to: fftoolsFile + "include/libpostproc/version.h")
            let ffplayFile = URL.currentDirectory + "../Sources/ffplay"
            try? FileManager.default.removeItem(at: ffplayFile)
            try FileManager.default.createDirectory(at: ffplayFile, withIntermediateDirectories: true)
            let ffprobeFile = URL.currentDirectory + "../Sources/ffprobe"
            try? FileManager.default.removeItem(at: ffprobeFile)
            try FileManager.default.createDirectory(at: ffprobeFile, withIntermediateDirectories: true)
            let ffmpegFile = URL.currentDirectory + "../Sources/ffmpeg"
            try? FileManager.default.removeItem(at: ffmpegFile)
            try FileManager.default.createDirectory(at: ffmpegFile + "include", withIntermediateDirectories: true)
            let fftools = buildURL + "src/fftools"
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: fftools.path)
            for fileName in fileNames {
                if fileName.hasPrefix("ffplay") {
                    try FileManager.default.copyItem(at: fftools + fileName, to: ffplayFile + fileName)
                } else if fileName.hasPrefix("ffprobe") {
                    try FileManager.default.copyItem(at: fftools + fileName, to: ffprobeFile + fileName)
                } else if fileName.hasPrefix("ffmpeg") {
                    if fileName.hasSuffix(".h") {
                        try FileManager.default.copyItem(at: fftools + fileName, to: ffmpegFile + "include" + fileName)
                    } else {
                        try FileManager.default.copyItem(at: fftools + fileName, to: ffmpegFile + fileName)
                    }
                } else if fileName.hasSuffix(".h") {
                    try FileManager.default.copyItem(at: fftools + fileName, to: fftoolsFile + "include" + fileName)
                } else if fileName.hasSuffix(".c") {
                    try FileManager.default.copyItem(at: fftools + fileName, to: fftoolsFile + fileName)
                }
            }
            let prefix = scratch(platform: platform, arch: arch)
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: "/usr/local/bin/ffmpeg"))
            try? FileManager.default.copyItem(at: prefix + "ffmpeg", to: URL(fileURLWithPath: "/usr/local/bin/ffmpeg"))
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: "/usr/local/bin/ffplay"))
            try? FileManager.default.copyItem(at: prefix + "ffplay", to: URL(fileURLWithPath: "/usr/local/bin/ffplay"))
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: "/usr/local/bin/ffprobe"))
            try? FileManager.default.copyItem(at: prefix + "ffprobe", to: URL(fileURLWithPath: "/usr/local/bin/ffprobe"))
        }
    }

    override func frameworkExcludeHeaders(_ framework: String) -> [String] {
        if framework == "Libavcodec" {
            return ["xvmc", "vdpau", "qsv", "dxva2", "d3d11va", "mathops", "videotoolbox"]
        } else if framework == "Libavutil" {
            return ["hwcontext_vulkan", "hwcontext_vdpau", "hwcontext_vaapi", "hwcontext_qsv", "hwcontext_opencl", "hwcontext_dxva2", "hwcontext_d3d11va", "hwcontext_cuda", "hwcontext_videotoolbox", "getenv_utf8", "intmath", "libm", "thread", "mem_internal", "internal", "attributes_internal"]
        } else if framework == "Libavformat" {
            return ["os_support"]
        } else {
            return super.frameworkExcludeHeaders(framework)
        }
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        var arguments = [
            "--prefix=\(thinDir(platform: platform, arch: arch).path)",
        ]
        arguments += ffmpegConfiguers
        arguments += Build.ffmpegConfiguers
        arguments.append("--arch=\(arch.cpuFamily)")
        arguments.append("--target-os=darwin")
        if platform == .maccatalyst || arch == .x86_64 {
            arguments.append("--disable-neon")
            arguments.append("--disable-asm")
        } else {
            arguments.append("--enable-neon")
            arguments.append("--enable-asm")
        }
        arguments.append("--disable-programs")
        return arguments
    }

    private let ffmpegConfiguers = [
        "--disable-armv5te", "--disable-armv6", "--disable-armv6t2",
        "--disable-bzlib", "--disable-gray", "--disable-iconv", "--disable-linux-perf",
        "--disable-shared", "--disable-small", "--disable-swscale-alpha", "--disable-symver", "--disable-xlib",
        "--enable-cross-compile",
        "--enable-optimizations", "--enable-pic", "--enable-runtime-cpudetect", "--enable-static", "--enable-thumb", "--enable-version3",
        "--pkg-config-flags=--static",
        "--disable-doc", "--disable-htmlpages", "--disable-manpages", "--disable-podpages", "--disable-txtpages",
        "--enable-avcodec", "--enable-avformat", "--enable-avutil", "--enable-network",
        "--disable-swresample", "--disable-swscale", "--disable-avfilter", "--disable-avdevice", "--disable-postproc",
        "--disable-devices", "--disable-outdevs", "--disable-indevs",
        "--disable-programs",
        "--disable-d3d11va", "--disable-dxva2", "--disable-vaapi", "--disable-vdpau",
        "--disable-everything",
        "--enable-demuxer=hls", "--enable-demuxer=mpegts", "--enable-demuxer=mov",
        "--enable-muxer=mp4", "--enable-muxer=mov",
        "--enable-protocol=file", "--enable-protocol=crypto", "--enable-protocol=data",
        "--enable-protocol=http", "--enable-protocol=tcp", "--enable-protocol=hls",
        "--enable-bsf=h264_mp4toannexb", "--enable-bsf=hevc_mp4toannexb", "--enable-bsf=aac_adtstoasc",
        "--enable-parser=h264", "--enable-parser=hevc", "--enable-parser=aac", "--enable-parser=mpegaudio",
    ]
}

class BuildZvbi: BaseBuild {
    init() {
        super.init(library: .libzvbi)
        let path = directoryURL + "configure.ac"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: "AC_FUNC_MALLOC", with: "")
            str = str.replacingOccurrences(of: "AC_FUNC_REALLOC", with: "")
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
    }

    override func platforms() -> [PlatformType] {
        super.platforms().filter {
            $0 != .maccatalyst
        }
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        ["--host=\(platform.host(arch: arch))",
         "--prefix=\(thinDir(platform: platform, arch: arch).path)"]
    }
}

class BuildSRT: BaseBuild {
    init() {
        super.init(library: .libsrt)
    }

    override func arguments(platform: PlatformType, arch _: ArchType) -> [String] {
        [
            "-Wno-dev",
//            "-DUSE_ENCLIB=openssl",
            "-DUSE_ENCLIB=gnutls",
            "-DENABLE_STDCXX_SYNC=1",
            "-DENABLE_CXX11=1",
            "-DUSE_OPENSSL_PC=1",
            "-DENABLE_DEBUG=0",
            "-DENABLE_LOGGING=0",
            "-DENABLE_HEAVY_LOGGING=0",
            "-DENABLE_APPS=0",
            "-DENABLE_SHARED=0",
            platform == .maccatalyst ? "-DENABLE_MONOTONIC_CLOCK=0" : "-DENABLE_MONOTONIC_CLOCK=1",
        ]
    }
}

class BuildFontconfig: BaseBuild {
    init() {
        super.init(library: .libfontconfig)
    }

    override func arguments(platform _: PlatformType, arch _: ArchType) -> [String] {
        [
            "-Ddoc=disabled",
            "-Dtests=disabled",
        ]
    }
}

class BuildBluray: BaseBuild {
    init() {
        super.init(library: .libbluray)
    }

    // 只有macos支持mount
    override func platforms() -> [PlatformType] {
        [.macos]
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--disable-bdjava-jar",
            "--disable-silent-rules",
            "--disable-dependency-tracking",
            "--host=\(platform.host(arch: arch))",
            "--prefix=\(thinDir(platform: platform, arch: arch).path)",
        ]
    }
}
