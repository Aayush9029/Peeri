import Foundation

#if DEBUG

public extension DownloadFile {
    static let sampleDownloading = DownloadFile(
        id: .deterministic(from: "a1"),
        gid: "a1",
        url: URL(string: "https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso")!,
        fileName: "ubuntu-24.04-desktop-amd64.iso",
        filePath: "/Users/me/Downloads/ubuntu-24.04-desktop-amd64.iso",
        fileSize: 6_114_017_280,
        downloadedSize: 3_220_000_000,
        downloadSpeed: 15_728_640,
        uploadSpeed: 0,
        connections: 8,
        status: .downloading
    )

    static let sampleTorrent = DownloadFile(
        id: .deterministic(from: "g7"),
        gid: "g7",
        url: URL(string: "magnet:?xt=urn:btih:sintel4k")!,
        fileName: "Sintel (2010) 4K.mkv",
        fileSize: 8_589_934_592,
        downloadedSize: 5_153_960_755,
        downloadSpeed: 8_388_608,
        uploadSpeed: 1_048_576,
        connections: 22,
        numSeeders: 48,
        uploadedSize: 1_073_741_824,
        status: .downloading
    )

    static let sampleSeeding = DownloadFile(
        id: .deterministic(from: "b2"),
        gid: "b2",
        url: URL(string: "magnet:?xt=urn:btih:spring")!,
        fileName: "Blender Open Movie — Spring.mkv",
        filePath: "/Users/me/Downloads/spring.mkv",
        fileSize: 1_073_741_824,
        downloadedSize: 1_073_741_824,
        downloadSpeed: 0,
        uploadSpeed: 2_097_152,
        connections: 14,
        numSeeders: 32,
        uploadedSize: 4_294_967_296,
        status: .seeding
    )

    static let samplePending = DownloadFile(
        id: .deterministic(from: "f6"),
        gid: "f6",
        url: URL(string: "https://example.com/app-installer.dmg")!,
        fileName: "app-installer.dmg",
        fileSize: 268_435_456,
        status: .pending
    )

    static let samplePaused = DownloadFile(
        id: .deterministic(from: "c3"),
        gid: "c3",
        url: URL(string: "https://example.com/training-dataset.tar.gz")!,
        fileName: "training-dataset.tar.gz",
        fileSize: 9_663_676_416,
        downloadedSize: 2_415_919_104,
        status: .paused
    )

    static let sampleCompleted = DownloadFile(
        id: .deterministic(from: "d4"),
        gid: "d4",
        url: URL(string: "https://example.com/vacation-photos.zip")!,
        fileName: "vacation-photos.zip",
        filePath: "/Users/me/Downloads/vacation-photos.zip",
        fileSize: 536_870_912,
        downloadedSize: 536_870_912,
        status: .completed
    )

    static let sampleFailed = DownloadFile(
        id: .deterministic(from: "e5"),
        gid: "e5",
        url: URL(string: "https://broken.example.com/missing.bin")!,
        fileName: "missing.bin",
        status: .failed
    )
}

public extension Array where Element == DownloadFile {
    static var sampleActive: [DownloadFile] { [.sampleDownloading, .sampleTorrent, .sampleSeeding] }
    static var sampleWaiting: [DownloadFile] { [.samplePending] }
    static var sampleStopped: [DownloadFile] { [.sampleCompleted, .sampleFailed, .samplePaused] }
    static var sampleList: [DownloadFile] { sampleActive + sampleWaiting + sampleStopped }
}

#endif
