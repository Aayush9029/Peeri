import Foundation
import Shared

public enum VideoFormatPreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case best
    case mp4
    case audioOnly

    public var id: String { rawValue }
}

public struct PeeriSettings: Codable, Equatable, Sendable {
    // MARK: - General Settings
    public var downloadDirectory: String
    public var downloadDirectoryBookmark: Data?
    public var advanced = Aria2Preferences()
    public var logLevel: String

    // MARK: - Connection Settings
    public var maxConcurrentDownloads: Int
    public var maxConnectionPerServer: Int
    public var split: Int
    public var minSplitSize: Int  // MB

    // MARK: - Speed Limits
    public var maxOverallDownloadLimit: Int  // KB/s, 0 = unlimited
    public var maxOverallUploadLimit: Int    // KB/s, 0 = unlimited

    // MARK: - BitTorrent Settings
    public var btEnableLPD: Bool
    public var btMaxPeers: Int
    public var btRequestPeerSpeedLimit: String
    public var enablePeerExchange: Bool
    public var seedingEnabled: Bool
    public var seedTimeMinutes: Int
    public var seedRatio: Double

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
        minSplitSize: Int = 1,
        maxOverallDownloadLimit: Int = 0,
        maxOverallUploadLimit: Int = 50,
        btEnableLPD: Bool = true,
        btMaxPeers: Int = 50,
        btRequestPeerSpeedLimit: String = "100K",
        enablePeerExchange: Bool = true,
        seedingEnabled: Bool = true,
        seedTimeMinutes: Int = 120,
        seedRatio: Double = 1,
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
        self.seedingEnabled = seedingEnabled
        self.seedTimeMinutes = seedTimeMinutes
        self.seedRatio = seedRatio
        self.checkIntegrity = checkIntegrity
        self.continueDownloads = continueDownloads
        self.videoFormatPreference = videoFormatPreference
    }

    public static let `default` = PeeriSettings()

    private enum CodingKeys: String, CodingKey {
        case downloadDirectory
        case downloadDirectoryBookmark
        case advanced
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
        case seedingEnabled
        case seedTimeMinutes
        case seedRatio
        case checkIntegrity
        case continueDownloads
        case videoFormatPreference
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.default
        advanced = try container.decodeIfPresent(Aria2Preferences.self, forKey: .advanced) ?? .init()

        downloadDirectory = try container.decodeIfPresent(String.self, forKey: .downloadDirectory) ?? defaults.downloadDirectory
        downloadDirectoryBookmark = try container.decodeIfPresent(Data.self, forKey: .downloadDirectoryBookmark)
        logLevel = try container.decodeIfPresent(String.self, forKey: .logLevel) ?? defaults.logLevel
        maxConcurrentDownloads = try container.decodeIfPresent(Int.self, forKey: .maxConcurrentDownloads) ?? defaults.maxConcurrentDownloads
        maxConnectionPerServer = try container.decodeIfPresent(Int.self, forKey: .maxConnectionPerServer) ?? defaults.maxConnectionPerServer
        split = try container.decodeIfPresent(Int.self, forKey: .split) ?? defaults.split
        if let minSplitSize = try? container.decode(Int.self, forKey: .minSplitSize) {
            self.minSplitSize = max(1, minSplitSize)
        } else if let legacyMinSplitSize = try? container.decode(String.self, forKey: .minSplitSize),
                  let minSplitSize = Self.megabytes(fromAria2SizeNotation: legacyMinSplitSize) {
            self.minSplitSize = minSplitSize
        } else {
            self.minSplitSize = defaults.minSplitSize
        }
        maxOverallDownloadLimit = try container.decodeIfPresent(Int.self, forKey: .maxOverallDownloadLimit) ?? defaults.maxOverallDownloadLimit
        maxOverallUploadLimit = try container.decodeIfPresent(Int.self, forKey: .maxOverallUploadLimit) ?? defaults.maxOverallUploadLimit
        btEnableLPD = try container.decodeIfPresent(Bool.self, forKey: .btEnableLPD) ?? defaults.btEnableLPD
        btMaxPeers = try container.decodeIfPresent(Int.self, forKey: .btMaxPeers) ?? defaults.btMaxPeers
        btRequestPeerSpeedLimit = try container.decodeIfPresent(String.self, forKey: .btRequestPeerSpeedLimit) ?? defaults.btRequestPeerSpeedLimit
        enablePeerExchange = try container.decodeIfPresent(Bool.self, forKey: .enablePeerExchange) ?? defaults.enablePeerExchange
        seedingEnabled = try container.decodeIfPresent(Bool.self, forKey: .seedingEnabled) ?? defaults.seedingEnabled
        seedTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .seedTimeMinutes) ?? defaults.seedTimeMinutes
        seedRatio = try container.decodeIfPresent(Double.self, forKey: .seedRatio) ?? defaults.seedRatio
        checkIntegrity = try container.decodeIfPresent(Bool.self, forKey: .checkIntegrity) ?? defaults.checkIntegrity
        continueDownloads = try container.decodeIfPresent(Bool.self, forKey: .continueDownloads) ?? defaults.continueDownloads
        videoFormatPreference = try container.decodeIfPresent(VideoFormatPreference.self, forKey: .videoFormatPreference) ?? defaults.videoFormatPreference
    }

    public func toAria2ConfigString(logPath: String) -> String {
        var options = toAria2GlobalOptions()
        options.merge([
            "enable-rpc": "true",
            "rpc-listen-all": "false",
            "rpc-listen-port": "16800",
            "rpc-secret": "peeri",
            "enable-dht": advanced.enableDHT ? "true" : "false",
            "enable-dht6": advanced.enableDHT6 && advanced.enableIPv6 ? "true" : "false",
            "disable-ipv6": advanced.enableIPv6 ? "false" : "true",
            "listen-port": "\(max(1024, min(advanced.listenPort, 65535)))",
            "dht-listen-port": "\(max(1024, min(advanced.listenPort, 65535)))",
            "bt-enable-lpd": btEnableLPD ? "true" : "false",
            "rpc-save-upload-metadata": "true",
            "bt-save-metadata": "true",
            "bt-load-saved-metadata": "true",
            "log": logPath
        ]) { _, new in new }
        return options.sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }.joined(separator: "\n") + "\n"
    }

    public func toAria2GlobalOptions() -> [String: String] {
        var options = toAria2DownloadOptions()
        options.merge([
            "max-concurrent-downloads": "\(max(1, min(maxConcurrentDownloads, 16)))",
            "max-overall-download-limit": maxOverallDownloadLimit > 0 ? "\(maxOverallDownloadLimit)K" : "0",
            "max-overall-upload-limit": maxOverallUploadLimit > 0 ? "\(maxOverallUploadLimit)K" : "0",
            "log-level": ["debug", "info", "notice", "warn", "error"].contains(logLevel) ? logLevel : "info"
        ]) { _, new in new }
        return options
    }

    public func toAria2DownloadOptions() -> [String: String] {
        var options = advanced.downloadOptions
        options.merge([
            "dir": downloadDirectory.replacingOccurrences(of: "\n", with: ""),
            "max-connection-per-server": "\(max(1, min(maxConnectionPerServer, 16)))",
            "split": "\(max(1, min(split, 16)))",
            "min-split-size": "\(max(1, min(minSplitSize, 1024)))M",
            "bt-max-peers": "\(max(0, min(btMaxPeers, 500)))",
            "bt-request-peer-speed-limit": Self.validSpeed(btRequestPeerSpeedLimit),
            "enable-peer-exchange": enablePeerExchange ? "true" : "false",
            "check-integrity": checkIntegrity ? "true" : "false",
            "continue": continueDownloads ? "true" : "false",
            "seed-time": seedingEnabled ? "\(max(1, min(seedTimeMinutes, 10080)))" : "0",
            "seed-ratio": "\(seedRatio.isFinite ? max(0, min(seedRatio, 100)) : 1)"
        ]) { _, new in new }
        return options
    }

    public var peerTargetSpeedKB: Int {
        get {
            let raw = btRequestPeerSpeedLimit.uppercased()
            let digits = raw.prefix { $0.isNumber }
            let amount = Int(digits) ?? 100
            let multiplier = raw.hasSuffix("M") ? 1024 : raw.hasSuffix("G") ? 1048576 : 1
            return min(amount, 1000000) * multiplier / (raw.last?.isNumber == true ? 1024 : 1)
        }
        set { btRequestPeerSpeedLimit = "\(max(0, min(newValue, 1000000)))K" }
    }

    private static func validSpeed(_ value: String) -> String {
        value.range(of: #"^\d+[KMG]?$"#, options: .regularExpression) != nil ? value : "100K"
    }

    private static func megabytes(fromAria2SizeNotation value: String) -> Int? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }

        let suffix = trimmedValue.last?.lowercased()
        let numberText: String
        let multiplier: Double

        switch suffix {
        case "k":
            numberText = String(trimmedValue.dropLast())
            multiplier = 1.0 / 1024.0
        case "m":
            numberText = String(trimmedValue.dropLast())
            multiplier = 1
        case "g":
            numberText = String(trimmedValue.dropLast())
            multiplier = 1024
        default:
            numberText = trimmedValue
            multiplier = 1.0 / 1_048_576.0
        }

        guard let number = Double(numberText) else { return nil }
        return max(1, Int((number * multiplier).rounded(.up)))
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
