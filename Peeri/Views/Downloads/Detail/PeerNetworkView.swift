import SwiftUI

struct PeerNetworkView: View {
    let model: PeerNetworkModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 16) {
            TimelineView(.animation(minimumInterval: 1.0 / 24, paused: reduceMotion || !model.hasTraffic || scenePhase != .active)) { timeline in
                Canvas { context, size in
                    PeerNetworkRenderer(
                        peers: model.visiblePeers,
                        locations: model.locations,
                        highlightedPeerID: model.highlightedPeerID,
                        time: timeline.date.timeIntervalSinceReferenceDate,
                        animate: !reduceMotion && scenePhase == .active && timeline.date.timeIntervalSince(model.sampledAt) < 2.5,
                        strongContrast: contrast == .increased,
                        translucent: !reduceTransparency
                    ).draw(in: context, size: size)
                }
            }
            .frame(height: model.visiblePeers.count < 3 ? 140 : 172)
            .accessibilityHidden(true)

            HStack(alignment: .top) {
                rate(model.downloadSpeed, label: "Receiving", symbol: "arrow.down", tint: .blue)
                Spacer()
                rate(model.uploadSpeed, label: "Sending", symbol: "arrow.up", tint: .teal)
            }

            if let regionSummary = model.regionSummary {
                HStack(spacing: 6) {
                    Text(regionSummary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Link("DB-IP", destination: URL(string: "https://db-ip.com/")!)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .help("Approximate country locations, looked up on your Mac using DB-IP Country Lite. No peer IP addresses are sent to a location service.")
            }
            Divider()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Peer network")
        .accessibilityValue("\(model.peers.count) connected peers. Receiving \(formattedRate(model.downloadSpeed)). Sending \(formattedRate(model.uploadSpeed)). \(model.regionSummary ?? "")")
        .help("Blue signals show incoming data; teal signals show outgoing data. Motion follows the latest peer transfer rates.\(model.peers.count > 24 ? " Showing 24 of \(model.peers.count) connections." : "")")
    }

    private func rate(_ bytes: Int64, label: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.caption)
                    .foregroundStyle(bytes > 0 ? tint : .secondary)
                Text(formattedRate(bytes))
                    .font(.system(size: 15, weight: .medium, design: .rounded).monospacedDigit())
            }
        }
    }

    private func formattedRate(_ rate: Int64) -> String {
        rate == 0 ? "0 B/s" : ByteCountFormatter.string(fromByteCount: rate, countStyle: .binary) + "/s"
    }
}
