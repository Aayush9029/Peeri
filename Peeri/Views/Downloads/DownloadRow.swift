import Models
import SwiftUI

struct DownloadRow: View {
    let download: DownloadFile
    var onShowDetails: () -> Void = {}
    @Environment(DownloadManager.self) private var downloadManager
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            DownloadStatusIcon(status: download.status)
                .frame(width: 28)

            Text(download.fileName)
                .lineLimit(1)
                .frame(minWidth: 120, alignment: .leading)

            Spacer(minLength: 12)

            DownloadProgressBar(progress: download.progress, status: download.status)
                .frame(minWidth: 100, maxWidth: 180, alignment: .leading)

            Spacer(minLength: 12)
            column(formattedSize, width: 80)

            Spacer(minLength: 12)
            column(timeLeftText, width: 90)

            Spacer(minLength: 12)
            column(speedText, width: 90)

            if download.isTorrent {
                Spacer(minLength: 12)
                column(download.numSeeders.map(String.init) ?? "—", width: 50)
                Spacer(minLength: 12)
                column(download.connections.map(String.init) ?? "—", width: 50)
            }
        }
        .font(.body)
        .padding(12)
        .frame(minHeight: 44)
        .background(rowBackground)
        .clipShape(.rect(cornerRadius: 8))
        .contentShape(.rect(cornerRadius: 8))
        .overlay(alignment: .trailing) {
            if isHovered {
                DownloadRowActions(download: download, onShowDetails: onShowDetails)
                    .transition(.opacity)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering }
        }
        .onTapGesture(count: 2) { onShowDetails() }
        .contextMenu { contextMenu }
    }

    private func column(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: .leading)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(isHovered ? 0.12 : 0.05))
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button(action: onShowDetails) { Label("Show Details", systemImage: "rectangle.grid.3x3") }
        Divider()

        switch download.status {
        case .downloading:
            Button { Task { await downloadManager.pauseDownload(download) } } label: { Label("Pause", systemImage: "pause.fill") }
            finderItem
            cancelItem
        case .paused:
            Button { Task { await downloadManager.resumeDownload(download) } } label: { Label("Resume", systemImage: "play.fill") }
            finderItem
            cancelItem
        case .completed, .seeding:
            finderItem
            if download.filePath != nil {
                Button { downloadManager.copyFilePath(download) } label: { Label("Copy File Path", systemImage: "doc.on.doc") }
            }
            Divider()
            removeItem(title: "Remove from List")
        case .failed:
            Button { Task { await downloadManager.retryDownload(download) } } label: { Label("Retry", systemImage: "arrow.clockwise") }
            removeItem(title: "Remove from List")
        case .pending:
            cancelItem
        case .removed:
            removeItem(title: "Remove from List")
        }

        Divider()
        Button { downloadManager.copyURL(download) } label: { Label("Copy URL", systemImage: "link") }
    }

    private var finderItem: some View {
        Button { downloadManager.showInFinder(download) } label: { Label("Show in Finder", systemImage: "folder") }
    }

    private var cancelItem: some View {
        Button(role: .destructive) { Task { await downloadManager.cancelDownload(download) } } label: { Label("Cancel", systemImage: "xmark.circle") }
    }

    private func removeItem(title: String) -> some View {
        Button(role: .destructive) { downloadManager.removeDownload(download) } label: { Label(title, systemImage: "trash") }
    }

    private var formattedSize: String {
        if let fileSize = download.fileSize, fileSize > 0 {
            return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        } else if download.downloadedSize > 0 {
            return ByteCountFormatter.string(fromByteCount: download.downloadedSize, countStyle: .file)
        }
        return "—"
    }

    private var speedText: String {
        switch download.status {
        case .downloading:
            return download.formattedSpeed
        case .seeding:
            guard let speed = download.uploadSpeed, speed > 0 else { return "—" }
            return ByteCountFormatter.string(fromByteCount: speed, countStyle: .binary) + "/s"
        default:
            return "—"
        }
    }

    private var timeLeftText: String {
        switch download.status {
        case .completed: return "Completed"
        case .paused: return "∞"
        case .failed: return "Failed"
        case .pending: return "Waiting"
        case .seeding: return "Seeding"
        case .removed: return "Removed"
        case .downloading:
            if let eta = download.eta { return formatETA(eta) }
            if let speed = download.downloadSpeed, speed > 0 { return "Calculating" }
            return "Starting"
        }
    }

    private func formatETA(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))sec"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))min"
        }
        let hours = Int(seconds / 3600)
        let mins = Int(seconds.truncatingRemainder(dividingBy: 3600) / 60)
        return "\(hours)h \(mins)m"
    }
}

#Preview("Downloading") {
    DownloadRow(download: .sampleDownloading)
        .environment(DownloadManager.preview())
        .padding()
        .frame(width: 800)
}

#Preview("Torrent") {
    DownloadRow(download: .sampleTorrent)
        .environment(DownloadManager.preview())
        .padding()
        .frame(width: 800)
}

#Preview("Completed") {
    DownloadRow(download: .sampleCompleted)
        .environment(DownloadManager.preview())
        .padding()
        .frame(width: 800)
}

#Preview("Paused") {
    DownloadRow(download: .samplePaused)
        .environment(DownloadManager.preview())
        .padding()
        .frame(width: 800)
}
