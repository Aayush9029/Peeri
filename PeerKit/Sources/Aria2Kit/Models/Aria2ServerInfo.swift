import Foundation

/// Server group for a file in a download, returned by `aria2.getServers`.
public struct Aria2ServerGroup: Decodable, Sendable {
    /// 1-based file index
    public let index: String
    /// Connected servers for this file
    public let servers: [Aria2ServerDetail]
}

/// Individual server connection details.
public struct Aria2ServerDetail: Decodable, Sendable {
    /// Original URI
    public let uri: String
    /// URI currently used (may differ after redirects)
    public let currentUri: String
    /// Download speed from this server (bytes/sec)
    public let downloadSpeed: String
}
