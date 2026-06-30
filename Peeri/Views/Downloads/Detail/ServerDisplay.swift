import Aria2Kit
import Foundation
import Shared

/// View-friendly projection of a single connected HTTP/FTP server, flattened
/// across aria2's per-file server groups.
struct ServerDisplay: Identifiable {
    typealias ID = Tagged<ServerDisplay, String>

    let id: ID
    let host: String
    let currentURI: String
    let downloadSpeed: Int64

    init(id: ID, host: String, currentURI: String, downloadSpeed: Int64) {
        self.id = id
        self.host = host
        self.currentURI = currentURI
        self.downloadSpeed = downloadSpeed
    }

    init(_ detail: Aria2ServerDetail, index: Int) {
        let host = URL(string: detail.currentUri)?.host ?? detail.currentUri
        self.init(
            id: ID(rawValue: "\(index)-\(detail.currentUri)"),
            host: host,
            currentURI: detail.currentUri,
            downloadSpeed: Int64(detail.downloadSpeed) ?? 0
        )
    }

    var formattedDownloadSpeed: String {
        guard downloadSpeed > 0 else { return "—" }
        return ByteCountFormatter.string(fromByteCount: downloadSpeed, countStyle: .binary) + "/s"
    }
}

extension IdentifiedArrayOf<ServerDisplay> {
    /// Flattens aria2's per-file server groups into one identified collection.
    static func from(_ groups: [Aria2ServerGroup]) -> Self {
        let details = groups.flatMap(\.servers)
        return IdentifiedArray(
            details.enumerated().map { ServerDisplay($0.element, index: $0.offset) },
            id: \.id,
            uniquingIDsWith: { first, _ in first }
        )
    }
}
