import Aria2Kit
import Combine
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

@MainActor
class DownloadManager: ObservableObject {
    @Published var downloads: IdentifiedArrayOf<DownloadFile> = []
    @Published var activeDownloads: IdentifiedArrayOf<DownloadFile> = []
    @Published var pausedDownloads: IdentifiedArrayOf<DownloadFile> = []
    @Published var completedDownloads: IdentifiedArrayOf<DownloadFile> = []

    @Published var totalDownloadRate: Int64 = 0
    @Published var totalUploadRate: Int64 = 0
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: String?

    @Published var downloadSpeedHistory: [Double] = Array(repeating: 0, count: 60)
    @Published var uploadSpeedHistory: [Double] = Array(repeating: 0, count: 60)
    @Published var sessionDownloaded: Int64 = 0
    @Published var sessionUploaded: Int64 = 0

    @Dependency(\.aria2Client) var aria2Client

    private var updateTimer: Timer?
    private let aria2Host = "localhost"
    private let aria2Port: UInt16 = 6800
    private let aria2Token = "peeri"
    private let logger = Logger(subsystem: "com.lovedoingthings.peeri", category: "DownloadManager")

    // File system paths for tracking downloads
    private let baseDownloadDir: URL
    private let downloadingDir: URL
    private let pausedDir: URL
    private let completedDir: URL
    private let metadataDir: URL

    init() {
        let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        baseDownloadDir = documentDir.appendingPathComponent("peeri/downloads", isDirectory: true)
        downloadingDir = baseDownloadDir.appendingPathComponent("downloading", isDirectory: true)
        pausedDir = baseDownloadDir.appendingPathComponent("paused", isDirectory: true)
        completedDir = baseDownloadDir.appendingPathComponent("completed", isDirectory: true)
        metadataDir = baseDownloadDir.appendingPathComponent("metadata", isDirectory: true)

        createDirectoryStructure()
        loadDownloadsFromFileSystem()
        setupNotificationObservers()
        initializeAria2Client()
        checkConnectionAndStartTimer()
    }

    private func createDirectoryStructure() {
        for directory in [baseDownloadDir, downloadingDir, pausedDir, completedDir, metadataDir] {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    private func loadDownloadsFromFileSystem() {
        guard let metadataFiles = try? FileManager.default.contentsOfDirectory(at: metadataDir, includingPropertiesForKeys: nil) else { return }

        for file in metadataFiles where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let download = try? JSONDecoder().decode(DownloadFile.self, from: data) else { continue }

            downloads[id: download.id] = download

            switch download.status {
            case .downloading: activeDownloads[id: download.id] = download
            case .paused: pausedDownloads[id: download.id] = download
            case .completed: completedDownloads[id: download.id] = download
            default: break
            }
        }

        logger.info("Loaded \(self.downloads.count) downloads from file system")
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAria2NotAvailable(_:)),
            name: NSNotification.Name("Aria2NotAvailable"),
            object: nil
        )
    }

    @objc private func handleAria2NotAvailable(_ notification: Notification) {
        Task { @MainActor in
            lastError = notification.userInfo?["message"] as? String ?? "Aria2 is not available."
            connectionState = .failed(NSError(domain: "Aria2", code: 1, userInfo: [NSLocalizedDescriptionKey: lastError!]))
        }
    }

    private func initializeAria2Client() {
        connectionState = .connecting
        logger.info("Initializing Aria2 client with host: \(self.aria2Host), port: \(self.aria2Port)")
        aria2Client.initialize(false, aria2Host, aria2Port, aria2Token)
    }

    private func checkConnectionAndStartTimer() {
        connectionState = .connecting
        startUpdateTimer()
        attemptConnection(retryCount: 0, maxRetries: 30)
    }

    private func attemptConnection(retryCount: Int, maxRetries: Int) {
        let delay = min(Double(retryCount) * 1.0 + 2.0, 10.0)

        guard retryCount <= maxRetries else {
            attemptConnection(retryCount: 0, maxRetries: maxRetries)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            Task {
                let success = await self.verifyConnection()
                if !success {
                    self.attemptConnection(retryCount: retryCount + 1, maxRetries: maxRetries)
                }
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
            return true
        } catch let timeoutError as TimeoutError {
            connectionState = .failed(timeoutError)
            lastError = "Connection timed out. Aria2 daemon may still be starting."
            return false
        } catch {
            connectionState = .failed(error)
            lastError = "Failed to connect to aria2: \(error.localizedDescription)"
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

    private func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { await self?.updateDownloads() }
        }
    }

    // MARK: - Download Actions

    func addDownload(url: URL) async {
        do {
            let downloadDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!.path
            let options: [String: String] = [
                "dir": downloadDir,
                "out": url.lastPathComponent.isEmpty ? "download" : url.lastPathComponent
            ]

            let gid = try await aria2Client.addDownload(url, options)
            logger.info("Added download with GID: \(gid)")

            let newDownload = try await aria2Client.tellStatus(gid)
            downloads[id: newDownload.id] = newDownload

            switch newDownload.status {
            case .completed: completedDownloads[id: newDownload.id] = newDownload
            default: activeDownloads[id: newDownload.id] = newDownload
            }

            saveDownloadMetadata(newDownload)
            Task { await updateDownloads() }
        } catch {
            logger.error("Failed to add download: \(error.localizedDescription)")
            lastError = "Failed to add download: \(error.localizedDescription)"
        }
    }

    func addTorrent(fileURL: URL) async {
        do {
            let base64 = try Data(contentsOf: fileURL).base64EncodedString()
            let downloadDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!.path

            let gid = try await aria2Client.addTorrent(base64, [], ["dir": downloadDir])
            logger.info("Added torrent with GID: \(gid)")
            Task { await updateDownloads() }
        } catch {
            logger.error("Failed to add torrent: \(error.localizedDescription)")
            lastError = "Failed to add torrent: \(error.localizedDescription)"
        }
    }

    func pauseDownload(_ download: DownloadFile) async {
        do {
            let success = try await aria2Client.pause(download.gid)
            guard success else { return }

            // O(1) update via IdentifiedArray
            downloads[id: download.id]?.status = .paused
            if let updated = downloads[id: download.id] {
                saveDownloadMetadata(updated)
            }

            activeDownloads.remove(id: download.id)
            var paused = download
            paused.status = .paused
            pausedDownloads[id: download.id] = paused

            logger.info("Download paused: \(download.fileName)")
        } catch {
            logger.error("Failed to pause download: \(error.localizedDescription)")
            lastError = "Failed to pause download: \(error.localizedDescription)"
        }
    }

    func resumeDownload(_ download: DownloadFile) async {
        do {
            let success = try await aria2Client.unpause(download.gid)
            guard success else { return }

            downloads[id: download.id]?.status = .downloading
            if let updated = downloads[id: download.id] {
                saveDownloadMetadata(updated)
            }

            pausedDownloads.remove(id: download.id)
            var resumed = download
            resumed.status = .downloading
            activeDownloads[id: download.id] = resumed

            logger.info("Download resumed: \(download.fileName)")
        } catch {
            logger.error("Failed to resume download: \(error.localizedDescription)")
            lastError = "Failed to resume download: \(error.localizedDescription)"
        }
    }

    func cancelDownload(_ download: DownloadFile) async {
        do {
            let success = try await aria2Client.remove(download.gid)
            guard success else { return }

            // Remove metadata file
            let metadataPath = metadataDir.appendingPathComponent("\(download.id.uuidString).json")
            try? FileManager.default.removeItem(at: metadataPath)

            // Remove symlinks
            for directory in [downloadingDir, pausedDir, completedDir] {
                let linkPath = directory.appendingPathComponent(download.fileName)
                if FileManager.default.fileExists(atPath: linkPath.path) {
                    try? FileManager.default.removeItem(at: linkPath)
                }
            }

            // O(1) removal from all identified arrays
            downloads.remove(id: download.id)
            activeDownloads.remove(id: download.id)
            pausedDownloads.remove(id: download.id)
            completedDownloads.remove(id: download.id)

            logger.info("Download canceled: \(download.fileName)")
        } catch {
            logger.error("Failed to cancel download: \(error.localizedDescription)")
            lastError = "Failed to cancel download: \(error.localizedDescription)"
        }
    }

    func showInFinder(_ download: DownloadFile) {
        if let filePath = download.filePath {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: filePath)])
        } else {
            let downloadDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            let url = downloadDir.appendingPathComponent(download.fileName)
            if FileManager.default.fileExists(atPath: url.path) {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
    }

    // MARK: - Polling & Updates

    private func updateDownloads() async {
        do {
            await updateDownloadsFromFileSystem()

            guard case .connected = connectionState else {
                if case .failed = connectionState {
                    _ = await verifyConnection()
                }
                return
            }

            // Aria2Kit returns [DownloadFile] directly
            let activeFiles = try await aria2Client.tellActive()
            let waitingFiles = try await aria2Client.tellWaiting(0, 30)
            let stoppedFiles = try await aria2Client.tellStopped(0, 100)

            updateStatistics(activeFiles)
            await updateGlobalStats()
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

    private func updateDownloadsFromFileSystem() async {
        guard let metadataFiles = try? FileManager.default.contentsOfDirectory(at: metadataDir, includingPropertiesForKeys: nil) else { return }

        var newDownloads: IdentifiedArrayOf<DownloadFile> = []
        var newActive: IdentifiedArrayOf<DownloadFile> = []
        var newPaused: IdentifiedArrayOf<DownloadFile> = []
        var newCompleted: IdentifiedArrayOf<DownloadFile> = []

        for file in metadataFiles where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let download = try? JSONDecoder().decode(DownloadFile.self, from: data) else { continue }

            newDownloads[id: download.id] = download
            switch download.status {
            case .downloading: newActive[id: download.id] = download
            case .paused: newPaused[id: download.id] = download
            case .completed: newCompleted[id: download.id] = download
            default: break
            }
        }

        if !newDownloads.isEmpty && newDownloads.count != downloads.count {
            downloads = newDownloads
            activeDownloads = newActive
            pausedDownloads = newPaused
            completedDownloads = newCompleted
        }
    }

    private func updateStatistics(_ activeFiles: [DownloadFile]) {
        var dlRate: Int64 = 0
        var ulRate: Int64 = 0
        for download in activeFiles {
            if let speed = download.downloadSpeed { dlRate += speed }
            if let speed = download.uploadSpeed { ulRate += speed }
        }

        totalDownloadRate = dlRate
        totalUploadRate = ulRate

        // Rolling 60-sample speed history
        downloadSpeedHistory.append(Double(dlRate))
        uploadSpeedHistory.append(Double(ulRate))
        if downloadSpeedHistory.count > 60 { downloadSpeedHistory.removeFirst() }
        if uploadSpeedHistory.count > 60 { uploadSpeedHistory.removeFirst() }
    }

    private func updateGlobalStats() async {
        guard let stats = try? await aria2Client.getGlobalStat() else { return }
        sessionDownloaded += Int64(stats.downloadSpeed) ?? 0
        sessionUploaded += Int64(stats.uploadSpeed) ?? 0
    }

    private func updateDownloadList(active: [DownloadFile], waiting: [DownloadFile], stopped: [DownloadFile]) {
        let allNew = active + waiting + stopped

        // Save new/changed downloads to filesystem
        for download in allNew {
            let existing = downloads[id: download.id]
            if existing == nil || existing?.status != download.status || existing?.downloadedSize != download.downloadedSize {
                saveDownloadMetadata(download)
            }
        }

        // Rebuild identified arrays
        downloads = IdentifiedArray(uniqueElements: allNew)
        activeDownloads = IdentifiedArray(uniqueElements: active)
        pausedDownloads = IdentifiedArray(uniqueElements: (waiting + active).filter { $0.status == .paused })
        completedDownloads = IdentifiedArray(uniqueElements: stopped.filter { $0.status == .completed })
    }

    // MARK: - Persistence

    private func saveDownloadMetadata(_ download: DownloadFile) {
        let metadataPath = metadataDir.appendingPathComponent("\(download.id.uuidString).json")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            try encoder.encode(download).write(to: metadataPath)
            organizeDownloadByStatus(download)
        } catch {
            logger.error("Error saving metadata: \(error.localizedDescription)")
        }
    }

    private func organizeDownloadByStatus(_ download: DownloadFile) {
        let targetDir: URL
        switch download.status {
        case .downloading: targetDir = downloadingDir
        case .paused: targetDir = pausedDir
        case .completed: targetDir = completedDir
        default: return
        }

        let targetLink = targetDir.appendingPathComponent(download.fileName)
        let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let filePath = downloadsPath.appendingPathComponent(download.fileName)

        if FileManager.default.fileExists(atPath: filePath.path),
           !FileManager.default.fileExists(atPath: targetLink.path) {
            try? FileManager.default.createSymbolicLink(at: targetLink, withDestinationURL: filePath)
        }
    }

    // MARK: - Helpers

    func formatBytes(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0
        while value > 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        return String(format: "%.2f %@", value, units[unitIndex])
    }

    deinit {
        updateTimer?.invalidate()
    }
}
