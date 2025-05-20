import Foundation
import KeyboardShortcuts

public struct DownloadFile: Identifiable, Codable, Hashable {
    public var id: UUID
    public var url: URL
    public var fileName: String
    public var fileSize: Int64?
    public var downloadedSize: Int64
    public var downloadSpeed: Int64?
    public var uploadSpeed: Int64?
    public var status: DownloadStatus
    public var createdAt: Date
    public var completedAt: Date?
    
    public init(
        id: UUID = UUID(),
        url: URL,
        fileName: String,
        fileSize: Int64? = nil,
        downloadedSize: Int64 = 0,
        downloadSpeed: Int64? = nil,
        uploadSpeed: Int64? = nil,
        status: DownloadStatus = .pending,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.url = url
        self.fileName = fileName
        self.fileSize = fileSize
        self.downloadedSize = downloadedSize
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
    
    public var progress: Double {
        guard let fileSize = fileSize, fileSize > 0 else { return 0 }
        return Double(downloadedSize) / Double(fileSize)
    }
}

public enum DownloadStatus: String, Codable {
    case pending
    case downloading
    case paused
    case completed
    case failed
}