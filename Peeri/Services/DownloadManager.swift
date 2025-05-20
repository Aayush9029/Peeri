import Aria2Client
import Combine
import Foundation
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
    @Published var downloads: [DownloadFile] = []
    @Published var activeDownloads: [DownloadFile] = []
    @Published var pausedDownloads: [DownloadFile] = []
    @Published var completedDownloads: [DownloadFile] = []
    
    @Published var totalDownloadRate: Int64 = 0
    @Published var totalUploadRate: Int64 = 0
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: String?
    
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
        // Setup directory structure for tracking downloads
        let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        baseDownloadDir = documentDir.appendingPathComponent("peeri/downloads", isDirectory: true)
        downloadingDir = baseDownloadDir.appendingPathComponent("downloading", isDirectory: true)
        pausedDir = baseDownloadDir.appendingPathComponent("paused", isDirectory: true) 
        completedDir = baseDownloadDir.appendingPathComponent("completed", isDirectory: true)
        metadataDir = baseDownloadDir.appendingPathComponent("metadata", isDirectory: true)
        
        // Create the directory structure
        createDirectoryStructure()
        
        // Load existing downloads from file system
        loadDownloadsFromFileSystem()
        
        setupNotificationObservers()
        initializeAria2Client()
        checkConnectionAndStartTimer()
    }
    
    private func createDirectoryStructure() {
        let directories = [baseDownloadDir, downloadingDir, pausedDir, completedDir, metadataDir]
        
        for directory in directories {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                print("Created directory: \(directory.path)")
            } catch {
                print("Error creating directory \(directory.path): \(error.localizedDescription)")
            }
        }
    }
    
    private func loadDownloadsFromFileSystem() {
        // Load metadata files from the metadata directory
        do {
            let metadataFiles = try FileManager.default.contentsOfDirectory(at: metadataDir, includingPropertiesForKeys: nil)
            
            for metadataFile in metadataFiles {
                if metadataFile.pathExtension == "json" {
                    do {
                        let data = try Data(contentsOf: metadataFile)
                        let decoder = JSONDecoder()
                        let download = try decoder.decode(DownloadFile.self, from: data)
                        
                        // Add to our lists based on status
                        downloads.append(download)
                        
                        switch download.status {
                        case .downloading:
                            activeDownloads.append(download)
                        case .paused:
                            pausedDownloads.append(download)
                        case .completed:
                            completedDownloads.append(download)
                        default:
                            break
                        }
                    } catch {
                        print("Error loading download metadata from \(metadataFile.path): \(error.localizedDescription)")
                    }
                }
            }
            
            print("Loaded \(downloads.count) downloads from file system")
        } catch {
            print("Error reading metadata directory: \(error.localizedDescription)")
        }
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
            if let message = notification.userInfo?["message"] as? String {
                lastError = message
            } else {
                lastError = "Aria2 is not available. Please install it to enable downloads."
            }
            connectionState = .failed(NSError(domain: "Aria2ClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Aria2 daemon not available"]))
        }
    }
    
    private func initializeAria2Client() {
        connectionState = .connecting
        print("Initializing Aria2 client with host: \(aria2Host), port: \(aria2Port)")
        aria2Client.initialize(false, aria2Host, aria2Port, aria2Token)
    }
    
    private func checkConnectionAndStartTimer() {
        // Allow time for aria2c daemon to fully start up
        logger.info("Scheduling connection verification with 4-second delay to allow daemon startup...")
        connectionState = .connecting
        
        // Start update timer regardless to ensure UI updates
        startUpdateTimer()
        
        // Retry connection with increasing delays until successful
        attemptConnection(retryCount: 0, maxRetries: 30) // keep retrying for a long time
    }
    
    private func attemptConnection(retryCount: Int, maxRetries: Int) {
        // Calculate delay - start with smaller delays, then increase up to max of 10 seconds
        let delay = min(Double(retryCount) * 1.0 + 2.0, 10.0) // 2s, 3s, 4s... up to 10s max
        
        guard retryCount <= maxRetries else {
            logger.error("Maximum connection attempts reached. Continuing to retry indefinitely...")
            // Start over with retries instead of giving up
            attemptConnection(retryCount: 0, maxRetries: maxRetries)
            return
        }
        
        logger.info("Connection attempt \(retryCount + 1) scheduled in \(delay) seconds...")
        
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
            logger.info("Verifying connection to aria2...")
            connectionState = .connecting
            
            let version = try await withTimeout(seconds: 3.0) {
                try await self.aria2Client.getVersion()
            }
            
            logger.info("Connected to aria2 version: \(version)")
            connectionState = .connected
            lastError = nil
            return true
        } catch let timeoutError as TimeoutError {
            logger.error("Connection timed out: \(timeoutError.localizedDescription)")
            connectionState = .failed(timeoutError)
            lastError = "Connection timed out. Aria2 daemon may still be starting."
            return false
        } catch {
            logger.error("Failed to connect to aria2: \(error.localizedDescription)")
            connectionState = .failed(error)
            lastError = "Failed to connect to aria2: \(error.localizedDescription)"
            return false
        }
    }
    
    // Helper to add timeout to async calls
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: Result<T, Error>.self) { group in
            // Add the actual operation
            group.addTask {
                do {
                    return try .success(await operation())
                } catch {
                    return .failure(error)
                }
            }
            
            // Add a timeout task
            group.addTask {
                do {
                    try await Task.sleep(nanoseconds: UInt64(seconds * 1000000000))
                } catch {
                    // Handle cancellation
                }
                return .failure(TimeoutError())
            }
            
            // Return the first result and cancel the other task
            guard let result = try await group.next() else {
                fatalError("Task group returned no results, which should never happen")
            }
            
            // Cancel the remaining task
            group.cancelAll()
            
            // Process the result
            switch result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
            }
        }
    }
    
    // Custom error for timeouts
    private struct TimeoutError: Error, LocalizedError {
        var errorDescription: String? {
            return "Operation timed out"
        }
    }
    
    private func startUpdateTimer() {
        // Clear existing timer if any
        updateTimer?.invalidate()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task {
                await self?.updateDownloads()
            }
        }
        logger.info("Started update timer")
    }
    
    func addDownload(url: URL) async {
        do {
            // Use FileManager to ensure we have a clean path
            let downloadDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!.path
            
            // Create options with clean path and file name
            let options: [String: String] = [
                "dir": downloadDir,
                "out": url.lastPathComponent.isEmpty ? "download" : url.lastPathComponent
            ]
            
            let gid = try await aria2Client.addDownload(url, options)
            print("Added download with GID: \(gid)")
            
            // Store the GID explicitly (we could use this to match up with returned downloads)
            print("After adding download, manually checking stopped downloads")
            let stoppedFiles = try await aria2Client.tellStopped(0, 100)
            for file in stoppedFiles {
                print("  Existing stopped file: \(file.id) - \(file.fileName) - Status: \(file.status.rawValue)")
            }
            
            // Create a new download file object with the given URL
            let newDownload = DownloadFile(
                id: UUID(uuidString: gid.replacingOccurrences(of: "^[a-f0-9]{16}$", with: "$0-0000-0000-0000-000000000000", options: .regularExpression)) ?? UUID(),
                url: url,
                fileName: url.lastPathComponent.isEmpty ? "download" : url.lastPathComponent,
                status: .downloading
            )
            
            print("Created new download with ID: \(newDownload.id.uuidString) for file: \(newDownload.fileName)")
            
            // Check if the download is already completed
            let stopResponse = try await aria2Client.tellStatus(gid)
            
            // Update status based on response
            var downloadToSave = newDownload
            if stopResponse == .completed {
                print("Download already completed, marking as completed")
                downloadToSave.status = .completed
                downloadToSave.completedAt = Date()
                
                // Add to our tracking lists
                downloads.append(downloadToSave)
                completedDownloads.append(downloadToSave)
            } else {
                // Add to our tracking lists
                downloads.append(downloadToSave)
                activeDownloads.append(downloadToSave)
            }
            
            // Save download metadata to disk
            saveDownloadMetadata(downloadToSave)
            
            print("Download added - Current counts: Active=\(activeDownloads.count), Completed=\(completedDownloads.count)")
            
            // Force an immediate update
            Task {
                await updateDownloads()
            }
        } catch {
            logger.error("Failed to add download: \(error.localizedDescription)")
            lastError = "Failed to add download: \(error.localizedDescription)"
        }
    }
    
    func pauseDownload(_ download: DownloadFile) async {
        do {
            let success = try await aria2Client.pause(download.id.uuidString)
            if success {
                if let index = downloads.firstIndex(where: { $0.id == download.id }) {
                    var updatedDownload = downloads[index]
                    updatedDownload.status = .paused
                    downloads[index] = updatedDownload
                    
                    // Save updated status to filesystem
                    saveDownloadMetadata(updatedDownload)
                }
                
                if let index = activeDownloads.firstIndex(where: { $0.id == download.id }) {
                    let download = activeDownloads.remove(at: index)
                    pausedDownloads.append(download)
                }
                
                print("Download paused: \(download.fileName)")
            }
        } catch {
            logger.error("Failed to pause download: \(error.localizedDescription)")
            lastError = "Failed to pause download: \(error.localizedDescription)"
        }
    }
    
    func resumeDownload(_ download: DownloadFile) async {
        do {
            let success = try await aria2Client.unpause(download.id.uuidString)
            if success {
                if let index = downloads.firstIndex(where: { $0.id == download.id }) {
                    var updatedDownload = downloads[index]
                    updatedDownload.status = .downloading
                    downloads[index] = updatedDownload
                    
                    // Save updated status to filesystem
                    saveDownloadMetadata(updatedDownload)
                }
                
                if let index = pausedDownloads.firstIndex(where: { $0.id == download.id }) {
                    let download = pausedDownloads.remove(at: index)
                    activeDownloads.append(download)
                }
                
                print("Download resumed: \(download.fileName)")
            }
        } catch {
            logger.error("Failed to resume download: \(error.localizedDescription)")
            lastError = "Failed to resume download: \(error.localizedDescription)"
        }
    }
    
    func cancelDownload(_ download: DownloadFile) async {
        do {
            let success = try await aria2Client.remove(download.id.uuidString)
            if success {
                // Remove metadata file
                let metadataPath = metadataDir.appendingPathComponent("\(download.id.uuidString).json")
                try? FileManager.default.removeItem(at: metadataPath)
                
                // Remove symlinks in status folders
                for directory in [downloadingDir, pausedDir, completedDir] {
                    let linkPath = directory.appendingPathComponent(download.fileName)
                    if FileManager.default.fileExists(atPath: linkPath.path) {
                        try? FileManager.default.removeItem(at: linkPath)
                    }
                }
                
                // Remove from in-memory lists
                if let index = downloads.firstIndex(where: { $0.id == download.id }) {
                    downloads.remove(at: index)
                }
                
                if let index = activeDownloads.firstIndex(where: { $0.id == download.id }) {
                    activeDownloads.remove(at: index)
                }
                
                if let index = pausedDownloads.firstIndex(where: { $0.id == download.id }) {
                    pausedDownloads.remove(at: index)
                }
                
                if let index = completedDownloads.firstIndex(where: { $0.id == download.id }) {
                    completedDownloads.remove(at: index)
                }
                
                print("Download canceled and removed: \(download.fileName)")
            }
        } catch {
            logger.error("Failed to cancel download: \(error.localizedDescription)")
            lastError = "Failed to cancel download: \(error.localizedDescription)"
        }
    }
    
    private func updateDownloads() async {
        do {
            // Also update from the filesystem regardless of connection state
            await updateDownloadsFromFileSystem()
            
            // Skip update if not connected
            if case .connected = connectionState {
                // Get active downloads
                let activeFiles = try await aria2Client.tellActive()
                
                // Get waiting downloads
                let waitingFiles = try await aria2Client.tellWaiting(0, 30)
                
                // Get stopped downloads - increase the number to handle more completed downloads
                let stoppedFiles = try await aria2Client.tellStopped(0, 100)
                
                // Debug log stopped files details
                print("Stopped files received from aria2: \(stoppedFiles.count)")
                for file in stoppedFiles {
                    print("  Stopped file: \(file.id) - \(file.fileName) - Status: \(file.status.rawValue)")
                }
                
                // Update statistics
                updateStatistics(activeFiles)
                
                // Log the active downloads to see progress
                if !activeFiles.isEmpty {
                    logger.info("Active downloads: \(activeFiles.count)")
                    for download in activeFiles {
                        let progressPercent = String(format: "%.1f%%", download.progress * 100)
                        // MUST USE PRINT HERE
                        print("\(download.fileName): \(progressPercent) complete, \(formatBytes(download.downloadedSize))/\(formatBytes(download.fileSize ?? 0))")
                    }
                }
                
                // Log completed downloads
                if !stoppedFiles.filter({ $0.status == .completed }).isEmpty {
                    logger.info("Completed downloads: \(stoppedFiles.filter { $0.status == .completed }.count)")
                }
                
                // Update our model
                updateDownloadList(active: activeFiles, waiting: waitingFiles, stopped: stoppedFiles)
                
                // Ensure connection state is connected
                if case .failed = connectionState {
                    connectionState = .connected
                    lastError = nil
                }
            } else if case .failed = connectionState {
                // Try to reconnect if failed
                _ = await verifyConnection()
            }
        } catch {
            logger.error("Failed to update downloads: \(error.localizedDescription)")
            lastError = "Failed to update downloads: \(error.localizedDescription)"
            
            // Set connection state to failed
            connectionState = .failed(error)
        }
    }
    
    private func updateDownloadsFromFileSystem() async {
        // This is a fallback method to ensure downloads are still displayed
        // even if Aria2 is not communicating properly
        
        do {
            print("Updating downloads from filesystem...")
            
            // Reset in-memory lists
            var newDownloads: [DownloadFile] = []
            var newActiveDownloads: [DownloadFile] = []
            var newPausedDownloads: [DownloadFile] = []
            var newCompletedDownloads: [DownloadFile] = []
            
            // Read all metadata files
            let metadataFiles = try FileManager.default.contentsOfDirectory(at: metadataDir, includingPropertiesForKeys: nil)
            
            for metadataFile in metadataFiles {
                if metadataFile.pathExtension == "json" {
                    do {
                        let data = try Data(contentsOf: metadataFile)
                        let decoder = JSONDecoder()
                        let download = try decoder.decode(DownloadFile.self, from: data)
                        
                        // Add to our lists based on status
                        newDownloads.append(download)
                        
                        switch download.status {
                        case .downloading:
                            newActiveDownloads.append(download)
                        case .paused:
                            newPausedDownloads.append(download)
                        case .completed:
                            newCompletedDownloads.append(download)
                        default:
                            break
                        }
                    } catch {
                        print("Error loading download metadata from \(metadataFile.path): \(error.localizedDescription)")
                    }
                }
            }
            
            // Update our UI state only if we have downloads from the filesystem
            if !newDownloads.isEmpty {
                print("Found \(newDownloads.count) downloads in filesystem")
                
                // Only update if the number of downloads has changed
                if newDownloads.count != downloads.count {
                    downloads = newDownloads
                    activeDownloads = newActiveDownloads
                    pausedDownloads = newPausedDownloads
                    completedDownloads = newCompletedDownloads
                    
                    print("Updated download lists from filesystem - Downloads: \(downloads.count), Active: \(activeDownloads.count), Paused: \(pausedDownloads.count), Completed: \(completedDownloads.count)")
                }
            }
        } catch {
            print("Error updating downloads from filesystem: \(error.localizedDescription)")
        }
    }
    
    private func updateStatistics(_ activeFiles: [DownloadFile]) {
        // Calculate total download/upload rates
        var dlRate: Int64 = 0
        var ulRate: Int64 = 0
        
        for download in activeFiles {
            // Use actual download rates from the files when available
            if let downloadSpeed = download.downloadSpeed {
                dlRate += downloadSpeed
            }
            
            if let uploadSpeed = download.uploadSpeed {
                ulRate += uploadSpeed
            }
        }
        
        // If no active downloads or rates not available, reset to 0
        totalDownloadRate = dlRate
        totalUploadRate = ulRate
        
        // Log the rates for debugging
        if dlRate > 0 {
            // MUST USE PRINT HERE
            print("Current download rate: \(formatBytes(dlRate))/s, upload rate: \(formatBytes(ulRate))/s")
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0
        
        while value > 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.2f %@", value, units[unitIndex])
    }
    
    private func updateDownloadList(active: [DownloadFile], waiting: [DownloadFile], stopped: [DownloadFile]) {
        // Log current state
        print("Updating download lists - Active: \(active.count), Waiting: \(waiting.count), Stopped: \(stopped.count)")
        
        // Update main list
        let newDownloads = active + waiting + stopped
        
        // Save new downloads to the filesystem and update our lists
        for download in newDownloads {
            // Check if this is a new download we haven't seen before
            if !downloads.contains(where: { $0.id == download.id }) {
                saveDownloadMetadata(download)
            } 
            // Check if status has changed
            else if let existingIndex = downloads.firstIndex(where: { $0.id == download.id }),
                    downloads[existingIndex].status != download.status {
                // Status changed, update the metadata
                saveDownloadMetadata(download)
            }
        }
        
        // Update our in-memory lists
        downloads = newDownloads
        activeDownloads = active
        pausedDownloads = waiting
        completedDownloads = stopped.filter { $0.status == .completed }
        
        // Debug log the current state
        print("Updated download lists - Downloads: \(downloads.count), Active: \(activeDownloads.count), Paused: \(pausedDownloads.count), Completed: \(completedDownloads.count)")
        
        // Print details of each download
        for download in downloads {
            print("Download in list: \(download.id.uuidString) - \(download.fileName) - Status: \(download.status.rawValue)")
        }
    }
    
    private func saveDownloadMetadata(_ download: DownloadFile) {
        // Create a filename based on the download ID
        let metadataPath = metadataDir.appendingPathComponent("\(download.id.uuidString).json")
        
        do {
            // Encode the download to JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(download)
            
            // Write to disk
            try data.write(to: metadataPath)
            print("Saved metadata for download: \(download.fileName) at \(metadataPath.path)")
            
            // Also organize the download in the appropriate folder
            organizeDownloadByStatus(download)
        } catch {
            print("Error saving download metadata: \(error.localizedDescription)")
        }
    }
    
    private func organizeDownloadByStatus(_ download: DownloadFile) {
        // Get the appropriate directory for this download's status
        let targetDir: URL
        switch download.status {
        case .downloading:
            targetDir = downloadingDir
        case .paused:
            targetDir = pausedDir
        case .completed:
            targetDir = completedDir
        default:
            return // Don't organize other statuses
        }
        
        // Create a symlink if needed
        let targetLink = targetDir.appendingPathComponent(download.fileName)
        
        // Check if the actual file exists in the downloads directory
        let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let filePath = downloadsPath.appendingPathComponent(download.fileName)
        
        if FileManager.default.fileExists(atPath: filePath.path) {
            // Create symbolic link if it doesn't exist already
            if !FileManager.default.fileExists(atPath: targetLink.path) {
                do {
                    try FileManager.default.createSymbolicLink(at: targetLink, withDestinationURL: filePath)
                    print("Created symbolic link for \(download.fileName) in \(targetDir.lastPathComponent) directory")
                } catch {
                    print("Error creating symbolic link: \(error.localizedDescription)")
                }
            }
        } else {
            print("File does not exist at expected path: \(filePath.path)")
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}
