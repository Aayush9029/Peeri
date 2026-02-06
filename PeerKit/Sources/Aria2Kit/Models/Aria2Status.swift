import Foundation

/// Typed response for aria2 tellStatus / tellActive / tellWaiting / tellStopped
public struct Aria2StatusResponse: Decodable, Sendable {
    public let gid: String
    public let status: String
    public let totalLength: String
    public let completedLength: String
    public let downloadSpeed: String
    public let uploadSpeed: String
    public let files: [Aria2FileInfo]?
    public let infoHash: String?
    public let numSeeders: String?
    public let numPieces: String?
    public let pieceLength: String?
    public let connections: String?
    public let dir: String?
    public let errorCode: String?
    public let errorMessage: String?
    /// Total uploaded bytes
    public let uploadLength: String?
    /// Hex piece availability map
    public let bitfield: String?
    /// "true" if local is seeder (BT only)
    public let seeder: String?
    /// GIDs generated from this download
    public let followedBy: [String]?
    /// Parent download GID
    public let following: String?
    /// Parent download GID (multi-file)
    public let belongsTo: String?
    /// Verified bytes during hash check
    public let verifiedLength: String?
    /// "true" if awaiting hash check
    public let verifyIntegrityPending: String?
    /// BitTorrent metadata sub-object
    public let bittorrent: Aria2BitTorrentInfo?
}

public struct Aria2FileInfo: Decodable, Sendable {
    public let index: String
    public let path: String
    public let length: String
    public let completedLength: String
    public let selected: String?
    public let uris: [Aria2UriInfo]?
}

public struct Aria2UriInfo: Decodable, Sendable {
    public let uri: String
    public let status: String
}
