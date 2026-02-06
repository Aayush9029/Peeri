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

// MARK: - Shared Keys

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
    @ObservationIgnored @Shared(.downloads) var downloads

    var totalDownloadRate: Int64 = 0
    var totalUploadRate: Int64 = 0
    var connectionState: ConnectionState = .disconnected
    var lastError: String?

    var downloadSpeedHistory: [Double] = Array(repeating: 0, count: 60)
    var uploadSpeedHistory: [Double] = Array(repeating: 0, count: 60)
    var sessionDownloaded: Int64 = 0
    var sessionUploaded: Int64 = 0

    // Computed category views — no more manual array sync
    var activeDownloads: [DownloadFile] {
        downloads.filter { $0.status == .downloading }
    }

    var pausedDownloads: [DownloadFile] {
        downloads.filter { $0.status == .paused }
    }

    var completedDownloads: [DownloadFile] {
        downloads.filter { $0.status == .completed }
    }

    @ObservationIgnored @Dependency(\.aria2Client) var aria2Client

    nonisolated(unsafe) private var updateTimer: Timer?
    private let aria2Host = "localhost"
    private let aria2Port: UInt16 = 16800
    private let aria2Token = "peeri"
    private let logger = Logger(subsystem: "com.lovedoingthings.peeri", category: "DownloadManager")

    private var hasEverConnected = false

    init() {
        setupNotificationObservers()
        initializeAria2Client()
        checkConnectionAndStartTimer()
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
        // First few attempts are fast, then back off
        let delay: Double
        if retryCount == 0 {
            delay = 0.2  // Try immediately first
        } else if retryCount < 5 {
            delay = Double(retryCount) * 0.3  // 0.3s, 0.6s, 0.9s, 1.2s, 1.5s
        } else {
            delay = min(Double(retryCount) * 0.5 + 2.0, 10.0)  // Cap at 10s
        }

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
            $downloads.withLock { $0[id: newDownload.id] = newDownload }

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

            $downloads.withLock { $0[id: download.id]?.status = .paused }
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

            $downloads.withLock { $0[id: download.id]?.status = .downloading }
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

            $downloads.withLock { $0.remove(id: download.id) }
            logger.info("Download canceled: \(download.fileName)")
        } catch {
            logger.error("Failed to cancel download: \(error.localizedDescription)")
            lastError = "Failed to cancel download: \(error.localizedDescription)"
        }
    }

    func removeDownload(_ download: DownloadFile) {
        $downloads.withLock { $0.remove(id: download.id) }
        logger.info("Download removed from list: \(download.fileName)")
    }

    // MARK: - Settings Application

    func applySettings(_ settings: PeeriSettings) async {
        do {
            let options = settings.toAria2GlobalOptions()
            try await aria2Client.changeGlobalOption(options)
            logger.info("Applied runtime settings to aria2")
        } catch {
            logger.error("Failed to apply settings: \(error)")
            lastError = "Failed to apply settings: \(error.localizedDescription)"
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
            guard case .connected = connectionState else {
                if case .failed = connectionState {
                    _ = await verifyConnection()
                }
                return
            }

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

    private func updateStatistics(_ activeFiles: [DownloadFile]) {
        var dlRate: Int64 = 0
        var ulRate: Int64 = 0
        for download in activeFiles {
            if let speed = download.downloadSpeed { dlRate += speed }
            if let speed = download.uploadSpeed { ulRate += speed }
        }

        totalDownloadRate = dlRate
        totalUploadRate = ulRate

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
        $downloads.withLock { $0 = IdentifiedArray(uniqueElements: allNew) }
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
        let timer = updateTimer
        timer?.invalidate()
    }
}
