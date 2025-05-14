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
    
    func pauseDownload(_ download: DownloadFile) async {
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
    
    func resumeDownload(_ download: DownloadFile) async {
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
    
    func cancelDownload(_ download: DownloadFile) async {
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
    
    private func updateDownloads() async {
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
