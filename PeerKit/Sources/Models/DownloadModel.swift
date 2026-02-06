import Foundation
import KeyboardShortcuts
import Tagged

public struct DownloadFile: Identifiable, Codable, Hashable {
    public typealias ID = Tagged<DownloadFile, UUID>

    public var id: ID
    public var gid: String
    public var url: URL
    public var fileName: String
    public var filePath: String?
    public var fileSize: Int64?
    public var downloadedSize: Int64
    public var downloadSpeed: Int64?
    public var uploadSpeed: Int64?
    public var status: DownloadStatus
    public var createdAt: Date
    public var completedAt: Date?

    public init(
        id: ID = .init(UUID()),
        gid: String = "",
        url: URL,
        fileName: String,
        filePath: String? = nil,
        fileSize: Int64? = nil,
        downloadedSize: Int64 = 0,
        downloadSpeed: Int64? = nil,
        uploadSpeed: Int64? = nil,
        status: DownloadStatus = .pending,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.gid = gid
        self.url = url
        self.fileName = fileName
        self.filePath = filePath
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

// MARK: - Deterministic ID from GID

public extension DownloadFile.ID {
    /// Creates a deterministic DownloadFile.ID from an aria2 GID string (16-char hex).
    /// The same GID always produces the same ID.
    static func deterministic(from name: String) -> DownloadFile.ID {
        let padded = name.padding(toLength: 32, withPad: "0", startingAt: 0)
        let s = padded
        let formatted = "\(s.prefix(8))-\(s.dropFirst(8).prefix(4))-\(s.dropFirst(12).prefix(4))-\(s.dropFirst(16).prefix(4))-\(s.dropFirst(20).prefix(12))"
        return DownloadFile.ID(UUID(uuidString: formatted) ?? UUID())
    }
}
