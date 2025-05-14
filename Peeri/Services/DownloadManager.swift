import Aria2Client
import Combine
import Foundation
import Models
import Shared
import SwiftUI
import os.log

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case failed(Error)
    case emulation  // New state for when aria2 isn't available
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
            if let message = notification.userInfo?["message"] as? String {
                lastError = message
            } else {
                lastError = "Aria2 is not available. Please install it to enable downloads."
            }
            connectionState = .emulation
            
            // Add sample downloads for UI testing in emulation mode
            addSampleDownloads()
        }
    }
    
    private func addSampleDownloads() {
        // Only add sample downloads if we're in emulation mode and have no downloads
        guard case .emulation = connectionState, downloads.isEmpty else { return }
        
        let sampleDownloads = [
            DownloadFile(
                url: URL(string: "https://example.com/sample1.mp4")!,
                fileName: "sample_video.mp4",
                fileSize: 1_073_741_824, // 1GB
                downloadedSize: 536_870_912, // 50%
                status: .downloading
            ),
            DownloadFile(
                url: URL(string: "https://example.com/sample2.zip")!,
                fileName: "sample_archive.zip",
                fileSize: 536_870_912, // 512MB
                downloadedSize: 536_870_912, // 100%
                status: .completed,
                completedAt: Date()
            ),
            DownloadFile(
                url: URL(string: "https://example.com/sample3.iso")!,
                fileName: "sample_image.iso",
                fileSize: 4_294_967_296, // 4GB
                downloadedSize: 1_073_741_824, // 25%
                status: .paused
            )
        ]
        
        downloads = sampleDownloads
        activeDownloads = [sampleDownloads[0]]
        pausedDownloads = [sampleDownloads[2]]
        completedDownloads = [sampleDownloads[1]]
        
        // Set some sample transfer rates
        totalDownloadRate = 5_242_880 // 5MB/s
        totalUploadRate = 1_048_576  // 1MB/s
    }
    
    private func initializeAria2Client() {
        connectionState = .connecting
        logger.info("Initializing Aria2 client with host: \(self.aria2Host), port: \(self.aria2Port)")
        aria2Client.initialize(false, aria2Host, aria2Port, aria2Token)
    }
    
    private func checkConnectionAndStartTimer() {
        // Allow a short delay for aria2 to start up
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            Task {
                await self.verifyConnection()
                self.startUpdateTimer()
            }
        }
    }
    
    private func verifyConnection() async {
        do {
            logger.info("Verifying connection to aria2...")
            let version = try await aria2Client.getVersion()
            logger.info("Connected to aria2 version: \(version)")
            connectionState = .connected
            lastError = nil
        } catch {
            logger.error("Failed to connect to aria2: \(error.localizedDescription)")
            connectionState = .failed(error)
            lastError = "Failed to connect to aria2: \(error.localizedDescription)"
            
            // Retry connection after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                Task {
                    await self.verifyConnection()
                }
            }
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
        // Use emulation mode if aria2 is not available
        if case .emulation = connectionState {
            await addEmulatedDownload(url: url)
            return
        }
        
        do {
            let options: [String: String] = [
                "dir": NSHomeDirectory() + "/Downloads",
                "out": url.lastPathComponent
            ]
            
            _ = try await aria2Client.addDownload(url, options)
            
            let newDownload = DownloadFile(
                url: url,
                fileName: url.lastPathComponent,
                status: .downloading
            )
            
            downloads.append(newDownload)
            activeDownloads.append(newDownload)
        } catch {
            logger.error("Failed to add download: \(error.localizedDescription)")
            lastError = "Failed to add download: \(error.localizedDescription)"
        }
    }
    
    private func addEmulatedDownload(url: URL) async {
        // Create a fake download with random size for emulation mode
        let fileName = url.lastPathComponent.isEmpty ? "download-\(UUID().uuidString.prefix(8))" : url.lastPathComponent
        let fileSize = Int64.random(in: 50_000_000...5_000_000_000) // Random size between 50MB and 5GB
        
        let newDownload = DownloadFile(
            url: url,
            fileName: fileName,
            fileSize: fileSize,
            downloadedSize: 0,
            status: .downloading
        )
        
        downloads.append(newDownload)
        activeDownloads.append(newDownload)
        
        // Simulate download progress over time
        Task {
            for _ in 1...10 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await updateEmulatedDownload(download: newDownload)
            }
        }
    }
    
    private func updateEmulatedDownload(download: DownloadFile) async {
        guard let index = downloads.firstIndex(where: { $0.id == download.id }),
              let activeIndex = activeDownloads.firstIndex(where: { $0.id == download.id }),
              let fileSize = download.fileSize else {
            return
        }
        
        // Increment download size by 10-20%
        let increment = Int64(Double(fileSize) * Double.random(in: 0.1...0.2))
        let newDownloadedSize = min(downloads[index].downloadedSize + increment, fileSize)
        downloads[index].downloadedSize = newDownloadedSize
        activeDownloads[activeIndex].downloadedSize = newDownloadedSize
        
        // Complete the download if it's finished
        if newDownloadedSize >= fileSize {
            downloads[index].status = .completed
            downloads[index].completedAt = Date()
            let download = activeDownloads.remove(at: activeIndex)
            completedDownloads.append(download)
        }
    }
    
    func pauseDownload(_ download: DownloadFile) async {
        // Use emulation mode if aria2 is not available
        if case .emulation = connectionState {
            await pauseEmulatedDownload(download)
            return
        }
        
        do {
            let success = try await aria2Client.pause(download.id.uuidString)
            if success {
                if let index = downloads.firstIndex(where: { $0.id == download.id }) {
                    downloads[index].status = .paused
                }
                
                if let index = activeDownloads.firstIndex(where: { $0.id == download.id }) {
                    let download = activeDownloads.remove(at: index)
                    pausedDownloads.append(download)
                }
            }
        } catch {
            logger.error("Failed to pause download: \(error.localizedDescription)")
            lastError = "Failed to pause download: \(error.localizedDescription)"
        }
    }
    
    private func pauseEmulatedDownload(_ download: DownloadFile) async {
        if let index = downloads.firstIndex(where: { $0.id == download.id }) {
            downloads[index].status = .paused
            
            if let activeIndex = activeDownloads.firstIndex(where: { $0.id == download.id }) {
                let download = activeDownloads.remove(at: activeIndex)
                pausedDownloads.append(download)
            }
        }
    }
    
    func resumeDownload(_ download: DownloadFile) async {
        // Use emulation mode if aria2 is not available
        if case .emulation = connectionState {
            await resumeEmulatedDownload(download)
            return
        }
        
        do {
            let success = try await aria2Client.unpause(download.id.uuidString)
            if success {
                if let index = downloads.firstIndex(where: { $0.id == download.id }) {
                    downloads[index].status = .downloading
                }
                
                if let index = pausedDownloads.firstIndex(where: { $0.id == download.id }) {
                    let download = pausedDownloads.remove(at: index)
                    activeDownloads.append(download)
                }
            }
        } catch {
            logger.error("Failed to resume download: \(error.localizedDescription)")
            lastError = "Failed to resume download: \(error.localizedDescription)"
        }
    }
    
    private func resumeEmulatedDownload(_ download: DownloadFile) async {
        if let index = downloads.firstIndex(where: { $0.id == download.id }) {
            downloads[index].status = .downloading
            
            if let pausedIndex = pausedDownloads.firstIndex(where: { $0.id == download.id }) {
                let download = pausedDownloads.remove(at: pausedIndex)
                activeDownloads.append(download)
                
                // Continue simulating download progress
                Task {
                    for _ in 1...5 {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        await updateEmulatedDownload(download: download)
                    }
                }
            }
        }
    }
    
    func cancelDownload(_ download: DownloadFile) async {
        // Use emulation mode if aria2 is not available
        if case .emulation = connectionState {
            await cancelEmulatedDownload(download)
            return
        }
        
        do {
            let success = try await aria2Client.remove(download.id.uuidString)
            if success {
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
            }
        } catch {
            logger.error("Failed to cancel download: \(error.localizedDescription)")
            lastError = "Failed to cancel download: \(error.localizedDescription)"
        }
    }
    
    private func cancelEmulatedDownload(_ download: DownloadFile) async {
        if let index = downloads.firstIndex(where: { $0.id == download.id }) {
            downloads.remove(at: index)
            
            if let activeIndex = activeDownloads.firstIndex(where: { $0.id == download.id }) {
                activeDownloads.remove(at: activeIndex)
            }
            
            if let pausedIndex = pausedDownloads.firstIndex(where: { $0.id == download.id }) {
                pausedDownloads.remove(at: pausedIndex)
            }
            
            if let completedIndex = completedDownloads.firstIndex(where: { $0.id == download.id }) {
                completedDownloads.remove(at: completedIndex)
            }
        }
    }
    
    private func updateDownloads() async {
        // For emulation mode, update the download rates periodically
        if case .emulation = connectionState {
            // Just update the simulated rates
            updateEmulationStatistics()
            return
        }
        
        do {
            // Skip update if not connected
            if case .connected = connectionState {
                // Get active downloads
                let activeFiles = try await aria2Client.tellActive()
                
                // Get waiting downloads
                let waitingFiles = try await aria2Client.tellWaiting(0, 10)
                
                // Get stopped downloads
                let stoppedFiles = try await aria2Client.tellStopped(0, 10)
                
                // Update statistics
                updateStatistics(activeFiles)
                
                // Update our model
                updateDownloadList(active: activeFiles, waiting: waitingFiles, stopped: stoppedFiles)
                
                // Ensure connection state is connected
                if case .failed = connectionState {
                    connectionState = .connected
                    lastError = nil
                }
            } else if case .failed = connectionState {
                // Try to reconnect if failed
                await verifyConnection()
            }
        } catch {
            logger.error("Failed to update downloads: \(error.localizedDescription)")
            lastError = "Failed to update downloads: \(error.localizedDescription)"
            
            // Set connection state to failed
            connectionState = .failed(error)
        }
    }
    
    private func updateEmulationStatistics() {
        // Simulate fluctuating download/upload rates
        if !activeDownloads.isEmpty {
            totalDownloadRate = Int64(Double(totalDownloadRate) * Double.random(in: 0.9...1.1))
            totalUploadRate = Int64(Double(totalUploadRate) * Double.random(in: 0.8...1.2))
        } else {
            totalDownloadRate = 0
            totalUploadRate = 0
        }
    }
    
    private func updateStatistics(_ activeFiles: [DownloadFile]) {
        // Calculate total download/upload rates
        var dlRate: Int64 = 0
        var ulRate: Int64 = 0
        
        for download in activeFiles {
            // We'd get the rates from Aria2 responses
            // This is a placeholder
            dlRate += 1000000 // 1MB/s
            ulRate += 500000 // 0.5MB/s
        }
        
        totalDownloadRate = dlRate
        totalUploadRate = ulRate
    }
    
    private func updateDownloadList(active: [DownloadFile], waiting: [DownloadFile], stopped: [DownloadFile]) {
        // Update main list
        downloads = active + waiting + stopped
        
        // Update category lists
        activeDownloads = active
        pausedDownloads = waiting
        completedDownloads = stopped.filter { $0.status == .completed }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}
