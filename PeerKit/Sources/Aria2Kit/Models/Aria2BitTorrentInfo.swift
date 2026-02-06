import Foundation

/// BitTorrent-specific metadata from a `.torrent` file, nested within `Aria2StatusResponse`.
public struct Aria2BitTorrentInfo: Decodable, Sendable {
    /// List of lists of announce (tracker) URIs
    public let announceList: [[String]]?
    /// Torrent comment
    public let comment: String?
    /// Creation timestamp (seconds since epoch)
    public let creationDate: Int?
    /// File mode: "single" or "multi"
    public let mode: String?
    /// Info dictionary data
    public let info: Aria2BTNameInfo?
}

/// The `info` sub-object containing the torrent name.
public struct Aria2BTNameInfo: Decodable, Sendable {
    /// Name from the info dictionary (uses name.utf-8 if available)
    public let name: String
}
