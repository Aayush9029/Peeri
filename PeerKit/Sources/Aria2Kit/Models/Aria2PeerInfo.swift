import Foundation

/// Peer information for a BitTorrent download, returned by `aria2.getPeers`.
public struct Aria2PeerInfo: Decodable, Sendable {
    /// Percent-encoded peer ID
    public let peerId: String?
    /// IP address of the peer
    public let ip: String
    /// Port number of the peer
    public let port: String
    /// Hexadecimal representation of the download progress of the peer
    public let bitfield: String?
    /// "true" if aria2 is choking the peer
    public let amChoking: String
    /// "true" if the peer is choking aria2
    public let peerChoking: String
    /// Download speed (bytes/sec) obtained from this peer
    public let downloadSpeed: String
    /// Upload speed (bytes/sec) uploaded to this peer
    public let uploadSpeed: String
    /// "true" if this peer is a seeder
    public let seeder: String
}
