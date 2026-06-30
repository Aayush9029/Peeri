import Foundation

#if DEBUG

// MARK: - Preview Value

public extension Aria2Client {
    /// Network-free client backed by sample data so SwiftUI previews render
    /// fully populated without a live aria2 daemon.
    static var previewValue: Self {
        var client = Self()
        client.initialize = { _, _, _, _ in }
        client.addDownload = { _, _ in "preview-gid" }
        client.addTorrent = { _, _, _ in "preview-gid" }
        client.tellStatus = { _ in .sampleDownloading }
        client.tellActive = { .sampleActive }
        client.tellWaiting = { _, _ in .sampleWaiting }
        client.tellStopped = { _, _ in .sampleStopped }
        client.pause = { _ in true }
        client.unpause = { _ in true }
        client.remove = { _ in true }
        client.getVersion = { "1.37.0 (preview)" }
        client.getGlobalStat = {
            Aria2GlobalStatResponse(
                downloadSpeed: "15728640",
                uploadSpeed: "2097152",
                numActive: "3",
                numWaiting: "1",
                numStopped: "3",
                numStoppedTotal: "3"
            )
        }
        return client
    }
}

#endif
