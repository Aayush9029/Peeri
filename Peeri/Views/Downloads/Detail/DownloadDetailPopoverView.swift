import Aria2Kit
import Models
import Shared
import SwiftUI

struct DownloadDetailPopoverView: View {
    let downloadID: DownloadFile.ID

    @Environment(DownloadManager.self) private var downloadManager

    @State private var peers: IdentifiedArrayOf<PeerDisplay> = []

    private var download: DownloadFile? { downloadManager.downloads[id: downloadID] }

    var body: some View {
        Group {
            if let download {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summary(download)
                        metricStrip(download)
                        sourceSection(download)

                        if download.isTorrent {
                            piecesSection(download)
                            peersSection
                        }
                    }
                    .padding(16)
                }
            } else {
                ContentUnavailableView("Download Unavailable", systemImage: "questionmark.folder")
                    .frame(width: 380, height: 240)
            }
        }
        .frame(width: download?.isTorrent == true ? 440 : 380, height: download?.isTorrent == true ? 460 : 300)
        .task(id: downloadID) {
            guard download?.isTorrent == true else { return }
            while !Task.isCancelled {
                await refreshTorrentDetail()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func refreshTorrentDetail() async {
        guard let download, download.isTorrent else { return }
        peers = .from(await downloadManager.peers(for: download.gid), numPieces: download.numPieces ?? 0)
    }

    private func summary(_ download: DownloadFile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                DownloadArtworkView(download: download, size: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text(download.fileName)
                        .font(.headline)
                        .lineLimit(2)
                        .truncationMode(.middle)

                    Label(statusText(download), systemImage: download.status.symbol)
                        .font(.caption)
                        .foregroundStyle(download.status.tint)
                        .labelStyle(.titleAndIcon)
                }

                Spacer(minLength: 0)
            }

            ProgressView(value: download.progress)
                .tint(download.status.tint)
        }
    }

    private func metricStrip(_ download: DownloadFile) -> some View {
        HStack(spacing: 10) {
            metric("Progress", download.progressPercentage)
            metric("Size", download.displaySize)

            if download.isTorrent {
                metric("Peers", download.connections.map(String.init) ?? "0")
                if let numPieces = download.numPieces {
                    metric("Pieces", "\(numPieces)")
                }
            }
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.callout.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary, in: .rect(cornerRadius: 8))
    }

    private func sourceSection(_ download: DownloadFile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("SOURCE")

            VStack(alignment: .leading, spacing: 4) {
                Text(download.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let filePath = download.filePath {
                    Text(filePath)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }

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
                Text("Waiting for torrent metadata")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
        }
    }

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

    private func emptyHint(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, minHeight: 48)
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

#if DEBUG
#Preview("Video") {
    DownloadDetailPopoverView(downloadID: DownloadFile.sampleDownloading.id)
        .environment(DownloadManager.preview())
}

#Preview("Torrent") {
    DownloadDetailPopoverView(downloadID: DownloadFile.sampleTorrent.id)
        .environment(DownloadManager.preview())
}
#endif
