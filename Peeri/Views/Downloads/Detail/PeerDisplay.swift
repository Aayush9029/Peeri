import Aria2Kit
import Foundation
import Shared

/// View-friendly projection of `Aria2PeerInfo`, parsing aria2's string fields
/// into typed values and deriving the peer's piece completion.
struct PeerDisplay: Identifiable {
    typealias ID = Tagged<PeerDisplay, String>

    let id: ID
    let ip: String
    let port: String
    let downloadSpeed: Int64
    let uploadSpeed: Int64
    let isSeeder: Bool
    let amChoking: Bool
    let peerChoking: Bool
    let progress: Double

    init(
        id: ID,
        ip: String,
        port: String,
        downloadSpeed: Int64,
        uploadSpeed: Int64,
        isSeeder: Bool,
        amChoking: Bool,
        peerChoking: Bool,
        progress: Double
    ) {
        self.id = id
        self.ip = ip
        self.port = port
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.isSeeder = isSeeder
        self.amChoking = amChoking
        self.peerChoking = peerChoking
        self.progress = progress
    }

    init(_ info: Aria2PeerInfo, numPieces: Int) {
        self.init(
            id: ID(rawValue: "[\(info.ip)]:\(info.port)"),
            ip: info.ip,
            port: info.port,
            downloadSpeed: Int64(info.downloadSpeed) ?? 0,
            uploadSpeed: Int64(info.uploadSpeed) ?? 0,
            isSeeder: info.seeder == "true",
            amChoking: info.amChoking == "true",
            peerChoking: info.peerChoking == "true",
            progress: Bitfield.fractionSet(hex: info.bitfield, count: numPieces)
        )
    }

    var formattedDownloadSpeed: String {
        guard downloadSpeed > 0 else { return "—" }
        return ByteCountFormatter.string(fromByteCount: downloadSpeed, countStyle: .binary) + "/s"
    }

    var formattedUploadSpeed: String {
        guard uploadSpeed > 0 else { return "—" }
        return ByteCountFormatter.string(fromByteCount: uploadSpeed, countStyle: .binary) + "/s"
    }
}

extension IdentifiedArrayOf<PeerDisplay> {
    /// Projects raw aria2 peers into a deduplicated, identified collection.
    static func from(_ peers: [Aria2PeerInfo], numPieces: Int) -> Self {
        IdentifiedArray(
            peers.map { PeerDisplay($0, numPieces: numPieces) },
            id: \.id,
            uniquingIDsWith: { first, _ in first }
        )
    }
}
