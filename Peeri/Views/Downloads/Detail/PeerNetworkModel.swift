import Foundation
import Observation
import Shared

@Observable @MainActor
final class PeerNetworkModel {
    private(set) var peers: IdentifiedArrayOf<PeerDisplay> = []
    private(set) var visiblePeers: [PeerDisplay] = []
    private(set) var sampledAt = Date.distantPast
    private(set) var downloadSpeed: Int64 = 0
    private(set) var uploadSpeed: Int64 = 0
    private(set) var locations: [String: PeerLocation] = [:]
    var highlightedPeerID: PeerDisplay.ID?

    var hasTraffic: Bool { downloadSpeed > 0 || uploadSpeed > 0 }

    var regionSummary: String? {
        let names = Set(peers.compactMap { locations[$0.ip]?.name }).sorted()
        guard !names.isEmpty else { return nil }
        let visible = names.prefix(2).joined(separator: " · ")
        return names.count > 2 ? "\(visible) · \(names.count - 2) more" : visible
    }

    func updateLocations(_ locations: [String: PeerLocation]) {
        self.locations = locations
    }

    func update(_ peers: IdentifiedArrayOf<PeerDisplay>) {
        self.peers = peers
        sampledAt = .now
        downloadSpeed = peers.reduce(0) { $0 + max(0, $1.downloadSpeed) }
        uploadSpeed = peers.reduce(0) { $0 + max(0, $1.uploadSpeed) }
        let retainedIDs = Set(visiblePeers.map(\.id))
        visiblePeers = Array(peers.sorted {
            let leftRetained = retainedIDs.contains($0.id)
            let rightRetained = retainedIDs.contains($1.id)
            if leftRetained != rightRetained { return leftRetained }
            return $0.id.rawValue < $1.id.rawValue
        }.prefix(24)).sorted { $0.id.rawValue < $1.id.rawValue }
        if let highlightedPeerID, peers[id: highlightedPeerID] == nil {
            self.highlightedPeerID = nil
        }
    }
}
