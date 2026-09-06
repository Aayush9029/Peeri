import Aria2Kit
import Models
import Shared
import SwiftUI

struct DownloadInspectorView: View {
    let downloadID: DownloadFile.ID

    @Environment(DownloadManager.self) private var downloadManager

    @State private var peerNetwork = PeerNetworkModel()

    private var download: DownloadFile? { downloadManager.downloads[id: downloadID] }

    var body: some View {
        Group {
            if let download {
                GeometryReader { geometry in
                    ScrollView {
                        if download.isVideoDownload {
                            VideoDownloadInspectorView(download: download, artworkHeight: max(220, min(360, geometry.size.height * 0.48)))
                        } else {
                            VStack(alignment: .leading, spacing: 22) {
                                summary(download)
                                metricStrip(download)
                                if !peerNetwork.peers.isEmpty { peersSection }
                                if download.isTorrent && download.hasPieceData {
                                    piecesSection(download)
                                }
                                sourceSection(download)
                            }
                            .padding(20)
                        }
                    }
                }
            } else {
                ContentUnavailableView("Download Unavailable", systemImage: "questionmark.folder")
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(alignment: .top) {
            if let download, !download.isVideoDownload {
                TransferAtmosphere(tint: download.status.tint, animated: [.downloading, .seeding].contains(download.status))
                    .frame(height: 240)
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal, 12)
            }
        }
        .task(id: downloadID) {
            peerNetwork.update([])
            guard download?.isTorrent == true else { return }
            while !Task.isCancelled {
                await refreshTorrentDetail()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func refreshTorrentDetail() async {
        guard let download, download.isTorrent, [.downloading, .seeding].contains(download.status) else { peerNetwork.update([]); return }
        let peers = await downloadManager.peers(for: download.gid)
        guard !Task.isCancelled else { return }
        peerNetwork.update(.from(peers, numPieces: download.numPieces ?? 0))
        let locations = await PeerCountryLookup.shared.locations(for: peers.map(\.ip))
        guard !Task.isCancelled else { return }
        peerNetwork.updateLocations(locations)
    }

    private func summary(_ download: DownloadFile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                TransferOrbit(download: download)

                VStack(alignment: .leading, spacing: 4) {
                    Text(download.fileName)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)
                        .truncationMode(.middle)

                    Label(statusText(download), systemImage: download.status.symbol)
                        .font(.caption)
                        .foregroundStyle(download.status.tint)
                        .labelStyle(.titleAndIcon)
                }

                Spacer(minLength: 0)
            }

        }
    }

    private func metricStrip(_ download: DownloadFile) -> some View {
        HStack(spacing: 12) {
            metric("Progress", download.progressPercentage)
            metric("Size", download.displaySize)

            if download.isTorrent {
                if let connections = download.connections, connections > 0 {
                    metric("Peers", String(connections))
                }
                if let numPieces = download.numPieces, numPieces > 0 {
                    metric("Pieces", "\(numPieces)")
                }
            }
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 17, weight: .medium, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
    }

    private func sourceSection(_ download: DownloadFile) -> some View {
        HStack {
            Button { downloadManager.copyURL(download) } label: {
                Label("Copy Link", systemImage: "link")
            }
            Spacer()
            if downloadManager.resolvedFileURL(for: download) != nil {
                Button { downloadManager.showInFinder(download) } label: {
                    Label("Show in Finder", systemImage: "folder")
                }
            }
        }
        .buttonStyle(.borderless)
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func piecesSection(_ download: DownloadFile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Pieces")
            if download.hasPieceData {
                PieceGridView(
                    bitfield: download.bitfield,
                    numPieces: download.numPieces ?? 0,
                    isComplete: download.status == .completed || download.status == .seeding,
                    tint: download.status.tint
                )
            } else {
                Text("Waiting for torrent metadata")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
        }
    }

    private var peersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Peers", count: peerNetwork.peers.count)
            PeerNetworkView(model: peerNetwork)
            peerList
        }
    }

    private var peerList: some View {
        LazyVStack(spacing: 6) {
            ForEach(peerNetwork.peers) { peer in
                PeerRow(peer: peer, location: peerNetwork.locations[peer.ip] ?? .unavailable)
                    .onHover { hovering in
                        peerNetwork.highlightedPeerID = hovering ? peer.id : nil
                    }
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int? = nil) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if let count {
                Text("\(count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func statusText(_ download: DownloadFile) -> String {
        switch download.status {
        case .downloading:
            download.displaySpeed == "—" ? "Downloading" : download.displaySpeed
        case .seeding:
            "Seeding"
        case .paused:
            "Paused"
        case .completed:
            "Completed"
        case .failed:
            "Failed"
        case .pending:
            "Preparing"
        case .removed:
            "Removed"
        }
    }
}
