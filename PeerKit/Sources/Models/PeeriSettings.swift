import Foundation
import Shared

public enum VideoFormatPreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case best
    case mp4
    case audioOnly

    public var id: String { rawValue }
}

public struct PeeriSettings: Codable, Equatable {
    // MARK: - General Settings
    public var downloadDirectory: String
    public var downloadDirectoryBookmark: Data?
    public var logLevel: String

    // MARK: - Connection Settings
    public var maxConcurrentDownloads: Int
    public var maxConnectionPerServer: Int
    public var split: Int
    public var minSplitSize: String

    // MARK: - Speed Limits
    public var maxOverallDownloadLimit: Int  // KB/s, 0 = unlimited
    public var maxOverallUploadLimit: Int    // KB/s, 0 = unlimited

    // MARK: - BitTorrent Settings
    public var btEnableLPD: Bool
    public var btMaxPeers: Int
    public var btRequestPeerSpeedLimit: String
    public var enablePeerExchange: Bool

    // MARK: - Advanced Settings
    public var checkIntegrity: Bool
    public var continueDownloads: Bool

    // MARK: - Video Settings
    public var videoFormatPreference: VideoFormatPreference

    public init(
        downloadDirectory: String = NSHomeDirectory() + "/Downloads",
        downloadDirectoryBookmark: Data? = nil,
        logLevel: String = "info",
        maxConcurrentDownloads: Int = 5,
        maxConnectionPerServer: Int = 10,
        split: Int = 10,
        minSplitSize: String = "1M",
        maxOverallDownloadLimit: Int = 0,
        maxOverallUploadLimit: Int = 50,
        btEnableLPD: Bool = true,
        btMaxPeers: Int = 50,
        btRequestPeerSpeedLimit: String = "100K",
        enablePeerExchange: Bool = true,
        checkIntegrity: Bool = true,
        continueDownloads: Bool = true,
        videoFormatPreference: VideoFormatPreference = .best
    ) {
        self.downloadDirectory = downloadDirectory
        self.downloadDirectoryBookmark = downloadDirectoryBookmark
        self.logLevel = logLevel
        self.maxConcurrentDownloads = maxConcurrentDownloads
        self.maxConnectionPerServer = maxConnectionPerServer
        self.split = split
        self.minSplitSize = minSplitSize
        self.maxOverallDownloadLimit = maxOverallDownloadLimit
        self.maxOverallUploadLimit = maxOverallUploadLimit
        self.btEnableLPD = btEnableLPD
        self.btMaxPeers = btMaxPeers
        self.btRequestPeerSpeedLimit = btRequestPeerSpeedLimit
        self.enablePeerExchange = enablePeerExchange
        self.checkIntegrity = checkIntegrity
        self.continueDownloads = continueDownloads
        self.videoFormatPreference = videoFormatPreference
    }

    public static let `default` = PeeriSettings()

    private enum CodingKeys: String, CodingKey {
        case downloadDirectory
        case downloadDirectoryBookmark
        case logLevel
        case maxConcurrentDownloads
        case maxConnectionPerServer
        case split
        case minSplitSize
        case maxOverallDownloadLimit
        case maxOverallUploadLimit
        case btEnableLPD
        case btMaxPeers
        case btRequestPeerSpeedLimit
        case enablePeerExchange
        case checkIntegrity
        case continueDownloads
        case videoFormatPreference
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.default

        downloadDirectory = try container.decodeIfPresent(String.self, forKey: .downloadDirectory) ?? defaults.downloadDirectory
        downloadDirectoryBookmark = try container.decodeIfPresent(Data.self, forKey: .downloadDirectoryBookmark)
        logLevel = try container.decodeIfPresent(String.self, forKey: .logLevel) ?? defaults.logLevel
        maxConcurrentDownloads = try container.decodeIfPresent(Int.self, forKey: .maxConcurrentDownloads) ?? defaults.maxConcurrentDownloads
        maxConnectionPerServer = try container.decodeIfPresent(Int.self, forKey: .maxConnectionPerServer) ?? defaults.maxConnectionPerServer
        split = try container.decodeIfPresent(Int.self, forKey: .split) ?? defaults.split
        minSplitSize = try container.decodeIfPresent(String.self, forKey: .minSplitSize) ?? defaults.minSplitSize
        maxOverallDownloadLimit = try container.decodeIfPresent(Int.self, forKey: .maxOverallDownloadLimit) ?? defaults.maxOverallDownloadLimit
        maxOverallUploadLimit = try container.decodeIfPresent(Int.self, forKey: .maxOverallUploadLimit) ?? defaults.maxOverallUploadLimit
        btEnableLPD = try container.decodeIfPresent(Bool.self, forKey: .btEnableLPD) ?? defaults.btEnableLPD
        btMaxPeers = try container.decodeIfPresent(Int.self, forKey: .btMaxPeers) ?? defaults.btMaxPeers
        btRequestPeerSpeedLimit = try container.decodeIfPresent(String.self, forKey: .btRequestPeerSpeedLimit) ?? defaults.btRequestPeerSpeedLimit
        enablePeerExchange = try container.decodeIfPresent(Bool.self, forKey: .enablePeerExchange) ?? defaults.enablePeerExchange
        checkIntegrity = try container.decodeIfPresent(Bool.self, forKey: .checkIntegrity) ?? defaults.checkIntegrity
        continueDownloads = try container.decodeIfPresent(Bool.self, forKey: .continueDownloads) ?? defaults.continueDownloads
        videoFormatPreference = try container.decodeIfPresent(VideoFormatPreference.self, forKey: .videoFormatPreference) ?? defaults.videoFormatPreference
    }

    /// Generate aria2.conf file content from settings
    public func toAria2ConfigString(logPath: String) -> String {
        """
        # Aria2 Configuration - Generated by Peeri

        # Downloads directory
        dir=\(downloadDirectory)

        # Enable JSON-RPC server
        enable-rpc=true
        rpc-listen-all=true
        rpc-listen-port=16800
        rpc-secret=peeri

        # BitTorrent settings
        bt-enable-lpd=\(btEnableLPD ? "true" : "false")
        bt-max-peers=\(btMaxPeers)
        bt-request-peer-speed-limit=\(btRequestPeerSpeedLimit)
        enable-peer-exchange=\(enablePeerExchange ? "true" : "false")

        # Connection settings
        max-concurrent-downloads=\(maxConcurrentDownloads)
        max-connection-per-server=\(maxConnectionPerServer)
        max-overall-download-limit=\(maxOverallDownloadLimit > 0 ? "\(maxOverallDownloadLimit)K" : "0")
        max-overall-upload-limit=\(maxOverallUploadLimit > 0 ? "\(maxOverallUploadLimit)K" : "0")
        min-split-size=\(minSplitSize)
        split=\(split)

        # Logging
        log=\(logPath)
        log-level=\(logLevel)

        # Other settings
        check-integrity=\(checkIntegrity ? "true" : "false")
        continue=\(continueDownloads ? "true" : "false")
        """
    }

    /// Generate runtime-changeable options for aria2
    public func toAria2GlobalOptions() -> [String: String] {
        [
            "max-concurrent-downloads": "\(maxConcurrentDownloads)",
            "max-connection-per-server": "\(maxConnectionPerServer)",
            "split": "\(split)",
            "min-split-size": minSplitSize,
            "max-overall-download-limit": maxOverallDownloadLimit > 0 ? "\(maxOverallDownloadLimit)K" : "0",
            "max-overall-upload-limit": maxOverallUploadLimit > 0 ? "\(maxOverallUploadLimit)K" : "0",
            "bt-max-peers": "\(btMaxPeers)",
            "bt-request-peer-speed-limit": btRequestPeerSpeedLimit,
            "log-level": logLevel
        ]
    }
}

// MARK: - SharedKey Extension

extension SharedKey where Self == FileStorageKey<PeeriSettings>.Default {
    public static var settings: Self {
        Self[.fileStorage(
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Peeri/settings.json")
        ), default: .default]
    }
}
