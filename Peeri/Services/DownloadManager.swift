import Aria2Kit
import AppKit
import Foundation
import IdentifiedCollections
import Models
import os.log
import Shared
import SwiftUI

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case failed(Error)
}

extension SharedKey where Self == FileStorageKey<IdentifiedArrayOf<DownloadFile>>.Default {
    static var downloads: Self {
        Self[.fileStorage(
            URL.documentsDirectory.appending(path: "peeri/downloads/downloads.json")
        ), default: []]
    }
}

@MainActor
@Observable
final class DownloadManager {
    private(set) var downloads: IdentifiedArrayOf<DownloadFile> = []

    var totalDownloadRate: Int64 = 0
    var totalUploadRate: Int64 = 0
    var connectionState: ConnectionState = .disconnected
    var lastError: String?

    var downloadSpeedHistory: [Double] = Array(repeating: 0, count: 60)
    var uploadSpeedHistory: [Double] = Array(repeating: 0, count: 60)
    var sessionDownloaded: Int64 = 0
    var sessionUploaded: Int64 = 0

    var activeDownloads: [DownloadFile] { downloads.filter { $0.status == .downloading } }
    var pausedDownloads: [DownloadFile] { downloads.filter { $0.status == .paused } }
    var completedDownloads: [DownloadFile] { downloads.filter { $0.status == .completed } }

    var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }

    var hasActiveTransfers: Bool {
        downloads.contains { $0.status == .downloading || $0.status == .seeding }
    }

    @ObservationIgnored @Shared(.downloads) private var persistedDownloads
    @ObservationIgnored @Shared(.settings) private var settings
    @ObservationIgnored @Dependency(\.aria2Client) private var aria2Client

    @ObservationIgnored private var connectionTask: Task<Void, Never>?
    @ObservationIgnored private var updateTask: Task<Void, Never>?
    @ObservationIgnored private var videoDownloadTasks: [DownloadFile.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private var lastPersistedSignature = 0

    private let ytdlpClient = YTDLPClient()
    private let ytdlpGIDPrefix = "yt-dlp:"
    private let aria2Host = "localhost"
    private let aria2Port: UInt16 = 16800
    private let aria2Token = "peeri"
    private let logger = Logger(subsystem: "com.lovedoingthings.peeri", category: "DownloadManager")

    private var hasEverConnected = false

    init(startPolling: Bool = true) {
        downloads = persistedDownloads
        guard startPolling else { return }
        initializeAria2Client()
        checkConnectionAndStartTimer()
    }

    private func initializeAria2Client() {
        connectionState = .connecting
        logger.info("Initializing Aria2 client with host: \(self.aria2Host), port: \(self.aria2Port)")
        aria2Client.initialize(false, aria2Host, aria2Port, aria2Token)
    }

    private func checkConnectionAndStartTimer() {
        connectionState = .connecting
        startUpdateLoop()
        startConnectionTask()
    }

    private func startConnectionTask() {
        connectionTask?.cancel()
        connectionTask = Task { [weak self] in
            await self?.attemptConnection()
        }
    }

    private func attemptConnection(maxRetries: Int = 30) async {
        while !Task.isCancelled {
            for attempt in 0...maxRetries {
                let delay: UInt64
                if attempt == 0 {
                    delay = 200_000_000
                } else if attempt < 5 {
                    delay = UInt64(Double(attempt) * 0.3 * 1_000_000_000)
                } else {
                    delay = UInt64(min(Double(attempt) * 0.5 + 2.0, 10.0) * 1_000_000_000)
                }

                try? await Task.sleep(nanoseconds: delay)
                if Task.isCancelled { return }
                if await verifyConnection() { return }
            }
        }
    }

    private func verifyConnection() async -> Bool {
        do {
            connectionState = .connecting

            let version = try await withTimeout(seconds: 3.0) {
                try await self.aria2Client.getVersion()
            }

            logger.info("Connected to aria2 version: \(version)")
            connectionState = .connected
            lastError = nil
            hasEverConnected = true
            return true
        } catch let timeoutError as TimeoutError {
            if hasEverConnected {
                connectionState = .failed(timeoutError)
                lastError = "Connection timed out. Aria2 daemon may still be starting."
            }
            return false
        } catch {
            if hasEverConnected {
                connectionState = .failed(error)
                lastError = "Failed to connect to aria2: \(error.localizedDescription)"
            }
            return false
        }
    }

    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: Result<T, Error>.self) { group in
            group.addTask {
                do { return try .success(await operation()) }
                catch { return .failure(error) }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return .failure(TimeoutError())
            }

            guard let result = try await group.next() else {
                fatalError("Task group returned no results")
            }
            group.cancelAll()

            switch result {
            case .success(let value): return value
            case .failure(let error): throw error
            }
        }
    }

    private struct TimeoutError: Error, LocalizedError {
        var errorDescription: String? { "Operation timed out" }
    }

    private func startUpdateLoop() {
        updateTask?.cancel()
        updateTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.updateDownloads()
                let idle = self?.shouldIdle ?? true
                try? await Task.sleep(nanoseconds: idle ? 2_500_000_000 : 1_000_000_000)
                if Task.isCancelled { return }
            }
        }
    }

    private var shouldIdle: Bool { isConnected && !hasActiveTransfers }

    // MARK: - Download Actions

    func addDownload(url: URL) async {
        if ytdlpClient.canHandle(url) {
            startVideoDownload(url: url)
            return
        }

        do {
            let directory = DownloadDirectoryAccess(settings: settings)
            let didStartAccessing = directory.startAccessing()
            defer { directory.stopAccessing(didStartAccessing) }

            let options: [String: String] = [
                "dir": directory.url.path,
                "out": url.lastPathComponent.isEmpty ? "download" : url.lastPathComponent
            ]

            let gid = try await aria2Client.addDownload(url, options)
            logger.info("Added download with GID: \(gid)")

            let newDownload = try await aria2Client.tellStatus(gid)
            downloads[id: newDownload.id] = newDownload
            persistIfStructureChanged()

            await updateDownloads()
        } catch {
            logger.error("Failed to add download: \(error.localizedDescription)")
            lastError = "Failed to add download: \(error.localizedDescription)"
        }
    }

    func addTorrent(fileURL: URL) async {
        do {
            let base64 = try Data(contentsOf: fileURL).base64EncodedString()
            let directory = DownloadDirectoryAccess(settings: settings)
            let didStartAccessing = directory.startAccessing()
            defer { directory.stopAccessing(didStartAccessing) }

            let gid = try await aria2Client.addTorrent(base64, [], ["dir": directory.url.path])
            logger.info("Added torrent with GID: \(gid)")
            await updateDownloads()
        } catch {
            logger.error("Failed to add torrent: \(error.localizedDescription)")
            lastError = "Failed to add torrent: \(error.localizedDescription)"
        }
    }

    func pauseDownload(_ download: DownloadFile) async {
        guard !isYTDLPDownload(download) else { return }

        do {
            guard try await aria2Client.pause(download.gid) else { return }
            downloads[id: download.id]?.status = .paused
            persistIfStructureChanged()
            logger.info("Download paused: \(download.fileName)")
        } catch {
            logger.error("Failed to pause download: \(error.localizedDescription)")
            lastError = "Failed to pause download: \(error.localizedDescription)"
        }
    }

    func resumeDownload(_ download: DownloadFile) async {
        guard !isYTDLPDownload(download) else { return }

        do {
            guard try await aria2Client.unpause(download.gid) else { return }
            downloads[id: download.id]?.status = .downloading
            persistIfStructureChanged()
            logger.info("Download resumed: \(download.fileName)")
        } catch {
            logger.error("Failed to resume download: \(error.localizedDescription)")
            lastError = "Failed to resume download: \(error.localizedDescription)"
        }
    }

    func cancelDownload(_ download: DownloadFile) async {
        if isYTDLPDownload(download) {
            videoDownloadTasks[download.id]?.cancel()
            videoDownloadTasks[download.id] = nil
            downloads.remove(id: download.id)
            refreshCurrentRates()
            persistIfStructureChanged()
            logger.info("Video download canceled: \(download.fileName)")
            return
        }

        do {
            guard try await aria2Client.remove(download.gid) else { return }
            downloads.remove(id: download.id)
            persistIfStructureChanged()
            logger.info("Download canceled: \(download.fileName)")
        } catch {
            logger.error("Failed to cancel download: \(error.localizedDescription)")
            lastError = "Failed to cancel download: \(error.localizedDescription)"
        }
    }

    func removeDownload(_ download: DownloadFile) {
        if isYTDLPDownload(download) {
            videoDownloadTasks[download.id]?.cancel()
            videoDownloadTasks[download.id] = nil
        }
        downloads.remove(id: download.id)
        refreshCurrentRates()
        persistIfStructureChanged()
        logger.info("Download removed from list: \(download.fileName)")
    }

    func retryDownload(_ download: DownloadFile) async {
        await addDownload(url: download.url)
    }

    // MARK: - Detail Queries

    func peers(for gid: String) async -> [Aria2PeerInfo] {
        do {
            return try await aria2Client.getPeers(gid)
        } catch {
            logger.error("Failed to fetch peers for \(gid): \(error.localizedDescription)")
            return []
        }
    }

    func servers(for gid: String) async -> [Aria2ServerGroup] {
        do {
            return try await aria2Client.getServers(gid)
        } catch {
            logger.error("Failed to fetch servers for \(gid): \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Clipboard & Finder

    func showInFinder(_ download: DownloadFile) {
        if let filePath = download.filePath {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: filePath)])
        } else {
            let directory = DownloadDirectoryAccess(settings: settings)
            let url = directory.url.appendingPathComponent(download.fileName)
            if FileManager.default.fileExists(atPath: url.path) {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
    }

    func copyURL(_ download: DownloadFile) {
        copyToPasteboard(download.url.absoluteString)
    }

    func copyFilePath(_ download: DownloadFile) {
        guard let filePath = download.filePath else { return }
        copyToPasteboard(filePath)
    }

    private func copyToPasteboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }

    // MARK: - Settings

    func applySettings(_ settings: PeeriSettings) async {
        do {
            try await aria2Client.changeGlobalOption(settings.toAria2GlobalOptions())
            logger.info("Applied runtime settings to aria2")
        } catch {
            logger.error("Failed to apply settings: \(error)")
            lastError = "Failed to apply settings: \(error.localizedDescription)"
        }
    }

    // MARK: - Polling

    private func updateDownloads() async {
        do {
            guard case .connected = connectionState else {
                if case .failed = connectionState {
                    _ = await verifyConnection()
                }
                return
            }

            async let active = aria2Client.tellActive()
            async let waiting = aria2Client.tellWaiting(0, 30)
            async let stopped = aria2Client.tellStopped(0, 100)
            let (activeFiles, waitingFiles, stoppedFiles) = try await (active, waiting, stopped)

            updateStatistics(activeFiles)
            updateSessionTotals()
            updateDownloadList(active: activeFiles, waiting: waitingFiles, stopped: stoppedFiles)

            if case .failed = connectionState {
                connectionState = .connected
                lastError = nil
            }
        } catch {
            logger.error("Failed to update downloads: \(error.localizedDescription)")
            lastError = "Failed to update downloads: \(error.localizedDescription)"
            connectionState = .failed(error)
        }
    }

    private func updateStatistics(_ activeFiles: [DownloadFile]) {
        var dlRate: Int64 = 0
        var ulRate: Int64 = 0
        let activeTransfers = activeFiles + activeYTDLPDownloads()

        for download in activeTransfers {
            if let speed = download.downloadSpeed { dlRate += speed }
            if let speed = download.uploadSpeed { ulRate += speed }
        }

        if totalDownloadRate != dlRate { totalDownloadRate = dlRate }
        if totalUploadRate != ulRate { totalUploadRate = ulRate }

        let hasActivity = dlRate > 0 || ulRate > 0
            || activeTransfers.contains { $0.status == .downloading || $0.status == .seeding }

        guard hasActivity else { return }
        downloadSpeedHistory.append(Double(dlRate))
        uploadSpeedHistory.append(Double(ulRate))
        if downloadSpeedHistory.count > 60 { downloadSpeedHistory.removeFirst() }
        if uploadSpeedHistory.count > 60 { uploadSpeedHistory.removeFirst() }
    }

    private func updateSessionTotals() {
        let down = downloads.reduce(Int64(0)) { $0 + $1.downloadedSize }
        let up = downloads.reduce(Int64(0)) { $0 + ($1.uploadedSize ?? 0) }
        if sessionDownloaded != down { sessionDownloaded = down }
        if sessionUploaded != up { sessionUploaded = up }
    }

    private func updateDownloadList(active: [DownloadFile], waiting: [DownloadFile], stopped: [DownloadFile]) {
        let videoDownloads = Array(downloads.filter(isYTDLPDownload))
        let newList = IdentifiedArray(uniqueElements: videoDownloads + active + waiting + stopped)
        guard newList != downloads else { return }
        downloads = newList
        persistIfStructureChanged()
    }

    private func startVideoDownload(url: URL) {
        let id = DownloadFile.ID(UUID())
        let gid = ytdlpGIDPrefix + UUID().uuidString
        let initialName = url.host(percentEncoded: false) ?? "Video Download"

        downloads[id: id] = DownloadFile(
            id: id,
            gid: gid,
            url: url,
            fileName: initialName,
            status: .pending
        )
        persistIfStructureChanged()

        videoDownloadTasks[id]?.cancel()
        videoDownloadTasks[id] = Task { [weak self] in
            await self?.runVideoDownload(id: id, url: url, initialName: initialName)
        }
    }

    private func runVideoDownload(id: DownloadFile.ID, url: URL, initialName: String) async {
        let directory = DownloadDirectoryAccess(settings: settings)
        let didStartAccessing = directory.startAccessing()
        defer {
            directory.stopAccessing(didStartAccessing)
            videoDownloadTasks[id] = nil
        }

        do {
            if let metadata = try? await ytdlpClient.metadata(for: url) {
                try Task.checkCancellation()
                downloads[id: id]?.fileName = metadata.title ?? initialName
                downloads[id: id]?.thumbnailURL = metadata.thumbnailURL
                downloads[id: id]?.status = .downloading
                persistIfStructureChanged()
            } else {
                downloads[id: id]?.status = .downloading
            }

            try Task.checkCancellation()

            let result = try await ytdlpClient.download(
                url: url,
                to: directory.url,
                formatPreference: settings.videoFormatPreference
            ) { [weak self] progress in
                await MainActor.run { [weak self] in
                    self?.updateVideoDownload(id: id, progress: progress)
                }
            }

            try Task.checkCancellation()

            if let outputURL = result.outputURL {
                let attributes = try? FileManager.default.attributesOfItem(atPath: outputURL.path)
                let size = (attributes?[.size] as? NSNumber)?.int64Value
                downloads[id: id]?.fileName = outputURL.lastPathComponent
                downloads[id: id]?.filePath = outputURL.path
                downloads[id: id]?.fileSize = size
                downloads[id: id]?.downloadedSize = size ?? downloads[id: id]?.downloadedSize ?? 0
            }
            downloads[id: id]?.progressFraction = 1
            downloads[id: id]?.downloadSpeed = 0
            downloads[id: id]?.status = .completed
            refreshCurrentRates()
            persistIfStructureChanged()
        } catch is CancellationError {
            downloads.remove(id: id)
            refreshCurrentRates()
            persistIfStructureChanged()
        } catch {
            logger.error("Failed to add video download: \(error.localizedDescription)")
            downloads[id: id]?.status = .failed
            downloads[id: id]?.downloadSpeed = 0
            refreshCurrentRates()
            lastError = "Failed to download video: \(error.localizedDescription)"
            persistIfStructureChanged()
        }
    }

    private func updateVideoDownload(id: DownloadFile.ID, progress: YTDLPProgress) {
        guard downloads[id: id] != nil else { return }

        if let totalBytes = progress.totalBytes, totalBytes > 0 {
            let currentSize = downloads[id: id]?.fileSize ?? 0
            if progress.status == "finished" || totalBytes > currentSize {
                downloads[id: id]?.fileSize = totalBytes
            }
        }

        if let downloadedBytes = progress.downloadedBytes {
            downloads[id: id]?.downloadedSize = downloadedBytes
        } else if
            let fraction = progress.fraction,
            let fileSize = downloads[id: id]?.fileSize
        {
            downloads[id: id]?.downloadedSize = Int64(Double(fileSize) * fraction)
        }

        if let fraction = progress.fraction {
            let currentFraction = downloads[id: id]?.progressFraction ?? 0
            downloads[id: id]?.progressFraction = max(currentFraction, fraction)
        }
        downloads[id: id]?.downloadSpeed = progress.speed ?? downloads[id: id]?.downloadSpeed
        downloads[id: id]?.status = .downloading
        refreshCurrentRates()
        updateSessionTotals()
        persistIfStructureChanged()
    }

    private func activeYTDLPDownloads() -> [DownloadFile] {
        downloads.filter { isYTDLPDownload($0) && $0.status == .downloading }
    }

    private func refreshCurrentRates() {
        let activeTransfers = downloads.filter { $0.status == .downloading || $0.status == .seeding }
        let dlRate = activeTransfers.compactMap(\.downloadSpeed).reduce(0, +)
        let ulRate = activeTransfers.compactMap(\.uploadSpeed).reduce(0, +)
        if totalDownloadRate != dlRate { totalDownloadRate = dlRate }
        if totalUploadRate != ulRate { totalUploadRate = ulRate }
    }

    private func isYTDLPDownload(_ download: DownloadFile) -> Bool {
        download.gid.hasPrefix(ytdlpGIDPrefix)
    }

    private func persistIfStructureChanged() {
        var hasher = Hasher()
        for download in downloads {
            hasher.combine(download.id)
            hasher.combine(download.status)
            hasher.combine(download.fileName)
            hasher.combine(download.filePath)
            hasher.combine(download.fileSize)
            hasher.combine(download.downloadedSize)
            hasher.combine(download.progressFraction)
            hasher.combine(download.downloadSpeed)
            hasher.combine(download.thumbnailURL)
        }
        let signature = hasher.finalize()
        guard signature != lastPersistedSignature else { return }
        lastPersistedSignature = signature
        $persistedDownloads.withLock { $0 = downloads }
    }

    deinit {
        connectionTask?.cancel()
        updateTask?.cancel()
        videoDownloadTasks.values.forEach { $0.cancel() }
    }
}

#if DEBUG
extension DownloadManager {
    static func preview(downloads: [DownloadFile] = .sampleList) -> DownloadManager {
        withDependencies {
            $0.aria2Client = .previewValue
        } operation: {
            let manager = DownloadManager(startPolling: false)
            manager.seedPreviewState(downloads: downloads)
            return manager
        }
    }

    private func seedPreviewState(downloads: [DownloadFile]) {
        self.downloads = IdentifiedArray(uniqueElements: downloads)
        connectionState = .connected
        totalDownloadRate = downloads.compactMap(\.downloadSpeed).reduce(0, +)
        totalUploadRate = downloads.compactMap(\.uploadSpeed).reduce(0, +)
        sessionDownloaded = downloads.reduce(0) { $0 + $1.downloadedSize }
        sessionUploaded = downloads.reduce(0) { $0 + ($1.uploadedSize ?? 0) }
        downloadSpeedHistory = Self.sampleHistory(peak: Double(max(totalDownloadRate, 1_048_576)))
        uploadSpeedHistory = Self.sampleHistory(peak: Double(max(totalUploadRate, 524_288)))
    }

    private static func sampleHistory(peak: Double) -> [Double] {
        (0..<60).map { index in
            let phase = Double(index) / 60 * .pi * 4
            return peak * (0.45 + 0.4 * (sin(phase) * 0.5 + 0.5))
        }
    }
}
#endif
