import Aria2Kit
import Models
import Shared
import SwiftUI

/// Inspector sheet for a single download: a GitHub-style piece grid plus a live
/// view of connected peers (torrents) or servers (HTTP/FTP).
struct DownloadDetailView: View {
    let downloadID: DownloadFile.ID

    @Environment(DownloadManager.self) private var downloadManager
    @Environment(\.dismiss) private var dismiss

    @State private var peers: IdentifiedArrayOf<PeerDisplay> = []
    @State private var servers: IdentifiedArrayOf<ServerDisplay> = []

    private var download: DownloadFile? { downloadManager.downloads[id: downloadID] }

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Divider()
            if let download {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header(download)
                        piecesSection(download)
                        if download.isTorrent {
                            peersSection
                        } else {
                            serversSection
                        }
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView("Download Unavailable", systemImage: "questionmark.folder")
            }
        }
        .frame(width: 660, height: 640)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
        .task(id: downloadID) {
            while !Task.isCancelled {
                await refreshDetail()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func refreshDetail() async {
        guard let download else { return }
        if download.isTorrent {
            peers = .from(await downloadManager.peers(for: download.gid), numPieces: download.numPieces ?? 0)
        } else {
            servers = .from(await downloadManager.servers(for: download.gid))
        }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack {
            Text(download?.fileName ?? "Details")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Header

    private func header(_ download: DownloadFile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                statColumn("PROGRESS", download.progressPercentage)
                statColumn("SIZE", download.formattedSize)
                if let pieces = download.numPieces {
                    statColumn("PIECES", "\(pieces)")
                }
                if let pieceLength = download.pieceLength, pieceLength > 0 {
                    statColumn("PIECE SIZE", ByteCountFormatter.string(fromByteCount: pieceLength, countStyle: .binary))
                }
                if download.isTorrent {
                    statColumn("PEERS", "\(peers.count)")
                    statColumn("SEEDS", download.numSeeders.map { "\($0)" } ?? "—")
                }
                Spacer()
            }

            ProgressView(value: min(max(download.progress, 0), 1))
                .tint(download.status == .completed || download.status == .seeding ? .green : .blue)
        }
    }

    private func statColumn(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.callout.monospacedDigit())
        }
    }

    // MARK: - Pieces

    private func piecesSection(_ download: DownloadFile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("PIECES")
            if download.hasPieceData {
                PieceGridView(
                    bitfield: download.bitfield,
                    numPieces: download.numPieces ?? 0,
                    isComplete: download.status == .completed || download.status == .seeding
                )
            } else {
                ContentUnavailableView(
                    "Waiting for Metadata",
                    systemImage: "square.grid.3x3.square",
                    description: Text("Piece information appears once aria2 receives the torrent metadata.")
                )
                .frame(height: 120)
            }
        }
    }

    // MARK: - Peers

    private var peersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("PEERS", count: peers.count)
            if peers.isEmpty {
                emptyHint("No peers connected yet")
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(peers) { peer in
                        PeerRow(peer: peer)
                    }
                }
            }
        }
    }

    // MARK: - Servers

    private var serversSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("SERVERS", count: servers.count)
            if servers.isEmpty {
                emptyHint("No active servers")
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(servers) { server in
                        ServerRow(server: server)
                    }
                }
            }
        }
    }

    // MARK: - Shared

    private func sectionHeader(_ title: String, count: Int? = nil) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            if let count {
                Text("\(count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func emptyHint(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, minHeight: 60)
    }
}
