import Models
import SwiftUI

struct DownloadRow: View {
    let download: DownloadFile
    @Environment(DownloadManager.self) private var downloadManager
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            // Status icon
            statusIcon
                .font(.body)
                .foregroundStyle(statusColor)
                .frame(width: 28)

            // Name
            Text(download.fileName)
                .font(.body)
                .lineLimit(1)
                .frame(minWidth: 120, alignment: .leading)

            Spacer(minLength: 12)

            // Progress bar
            progressBar
                .frame(minWidth: 100, maxWidth: 180, alignment: .leading)

            Spacer(minLength: 12)

            // Size
            Text(formattedSize)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            Spacer(minLength: 12)

            // Time left / Status
            Text(timeLeftText)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            Spacer(minLength: 12)

            // Speed
            Text(speedText)
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            // Seeds (only for torrents)
            if download.isTorrent {
                Spacer(minLength: 12)
                Text(download.numSeeders.map { "\($0)" } ?? "—")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .leading)

                Spacer(minLength: 12)
                Text(download.connections.map { "\($0)" } ?? "—")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .leading)
            }
        }
        .padding(12)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.gray.opacity(0.12) : Color.gray.opacity(0.05))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .trailing) {
            if isHovered {
                hoverActions
                    .transition(.opacity)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu { contextMenuItems }
    }

    // MARK: - Status Icon

    private var statusIcon: some View {
        Group {
            switch download.status {
            case .downloading:
                Image(systemName: "arrow.down")
            case .paused:
                Image(systemName: "pause")
            case .completed:
                Image(systemName: "checkmark.circle")
            case .pending:
                Image(systemName: "clock")
            case .failed:
                Image(systemName: "exclamationmark.triangle")
            case .seeding:
                Image(systemName: "arrow.up")
            case .removed:
                Image(systemName: "trash")
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.quaternary)

                RoundedRectangle(cornerRadius: 3)
                    .fill(progressGradient)
                    .frame(width: max(0, geo.size.width * download.progress))
            }
        }
        .frame(height: 6)
    }

    private var progressGradient: some ShapeStyle {
        switch download.status {
        case .completed:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.green.opacity(0.8), .green],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case .downloading:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.blue.opacity(0.7), .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        default:
            return AnyShapeStyle(Color.gray.opacity(0.5))
        }
    }

    // MARK: - Formatted Size

    private var formattedSize: String {
        if let fileSize = download.fileSize, fileSize > 0 {
            return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        } else if download.downloadedSize > 0 {
            return ByteCountFormatter.string(fromByteCount: download.downloadedSize, countStyle: .file)
        }
        return "—"
    }

    // MARK: - Speed

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

    // MARK: - Time Left

    private var timeLeftText: String {
        switch download.status {
        case .completed:
            return "Completed"
        case .paused:
            return "∞"
        case .failed:
            return "Failed"
        case .pending:
            return "Waiting"
        case .seeding:
            return "Seeding"
        case .removed:
            return "Removed"
        case .downloading:
            if let eta = download.eta {
                return formatETA(eta)
            }
            if let speed = download.downloadSpeed, speed > 0 {
                return "Calculating"
            }
            return "Starting"
        }
    }

    private func formatETA(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))sec"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))min"
        } else {
            let hours = Int(seconds / 3600)
            let mins = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(mins)m"
        }
    }

    // MARK: - Hover Actions

    private var hoverActions: some View {
        HStack(spacing: 4) {
            switch download.status {
            case .downloading:
                HoverableActionButton(icon: "pause.fill", tooltip: "Pause") { Task { await downloadManager.pauseDownload(download) } }
                HoverableActionButton(icon: "folder", tooltip: "Show in Finder") { downloadManager.showInFinder(download) }
                HoverableActionButton(icon: "trash", tooltip: "Cancel", hoverColor: .red) { Task { await downloadManager.cancelDownload(download) } }

            case .paused:
                HoverableActionButton(icon: "play.fill", tooltip: "Resume") { Task { await downloadManager.resumeDownload(download) } }
                HoverableActionButton(icon: "folder", tooltip: "Show in Finder") { downloadManager.showInFinder(download) }
                HoverableActionButton(icon: "trash", tooltip: "Cancel", hoverColor: .red) { Task { await downloadManager.cancelDownload(download) } }

            case .completed, .seeding:
                HoverableActionButton(icon: "folder", tooltip: "Show in Finder") { downloadManager.showInFinder(download) }
                HoverableActionButton(icon: "trash", tooltip: "Delete", hoverColor: .red) { downloadManager.removeDownload(download) }

            case .failed:
                HoverableActionButton(icon: "arrow.clockwise", tooltip: "Retry") { Task { await downloadManager.addDownload(url: download.url) } }
                HoverableActionButton(icon: "trash", tooltip: "Remove", hoverColor: .red) { downloadManager.removeDownload(download) }

            case .pending:
                HoverableActionButton(icon: "trash", tooltip: "Cancel", hoverColor: .red) { Task { await downloadManager.cancelDownload(download) } }

            case .removed:
                HoverableActionButton(icon: "trash", tooltip: "Remove", hoverColor: .red) { downloadManager.removeDownload(download) }
            }
        }
        .padding(.trailing, 12)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuItems: some View {
        switch download.status {
        case .downloading:
            Button { Task { await downloadManager.pauseDownload(download) } } label: { Label("Pause", systemImage: "pause.fill") }
            Button { downloadManager.showInFinder(download) } label: { Label("Show in Finder", systemImage: "folder") }
            Button(role: .destructive) { Task { await downloadManager.cancelDownload(download) } } label: { Label("Cancel", systemImage: "xmark.circle") }
        case .paused:
            Button { Task { await downloadManager.resumeDownload(download) } } label: { Label("Resume", systemImage: "play.fill") }
            Button { downloadManager.showInFinder(download) } label: { Label("Show in Finder", systemImage: "folder") }
            Button(role: .destructive) { Task { await downloadManager.cancelDownload(download) } } label: { Label("Cancel", systemImage: "xmark.circle") }
        case .completed, .seeding:
            Button { downloadManager.showInFinder(download) } label: { Label("Show in Finder", systemImage: "folder") }
            if let filePath = download.filePath {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(filePath, forType: .string)
                } label: { Label("Copy File Path", systemImage: "doc.on.doc") }
            }
            Divider()
            Button(role: .destructive) { downloadManager.removeDownload(download) } label: { Label("Remove from List", systemImage: "trash") }
        case .failed:
            Button { Task { await downloadManager.addDownload(url: download.url) } } label: { Label("Retry", systemImage: "arrow.clockwise") }
            Button(role: .destructive) { downloadManager.removeDownload(download) } label: { Label("Remove from List", systemImage: "trash") }
        case .pending:
            Button(role: .destructive) { Task { await downloadManager.cancelDownload(download) } } label: { Label("Cancel", systemImage: "xmark.circle") }
        case .removed:
            Button(role: .destructive) { downloadManager.removeDownload(download) } label: { Label("Remove from List", systemImage: "trash") }
        }

        Divider()
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(download.url.absoluteString, forType: .string)
        } label: { Label("Copy URL", systemImage: "link") }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch download.status {
        case .downloading: return .blue
        case .paused: return .gray
        case .completed: return .green
        case .pending: return .orange
        case .failed: return .red
        case .seeding: return .teal
        case .removed: return .gray
        }
    }
}

// MARK: - Hoverable Action Button

private struct HoverableActionButton: View {
    let icon: String
    let tooltip: String
    var hoverColor: Color = .primary
    let action: () -> Void
    @State private var isButtonHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(isButtonHovered ? hoverColor : .secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isButtonHovered = hovering
            }
        }
    }
}

#Preview("Downloading") {
    DownloadRow(
        download: DownloadFile(
            gid: "abc123",
            url: URL(string: "https://example.com/largefile.zip")!,
            fileName: "Royalty free classics",
            fileSize: 67_108_864,
            downloadedSize: 47_185_920,
            downloadSpeed: 15_728_640,
            connections: 8,
            numSeeders: 21,
            status: .downloading
        )
    )
    .environment(DownloadManager())
    .padding()
    .frame(width: 800)
}

#Preview("Completed") {
    DownloadRow(
        download: DownloadFile(
            gid: "ghi789",
            url: URL(string: "https://example.com/game-assets.zip")!,
            fileName: "Game assets pack v1.2",
            fileSize: 536_870_912,
            downloadedSize: 536_870_912,
            connections: 2,
            numSeeders: 9,
            status: .completed
        )
    )
    .environment(DownloadManager())
    .padding()
    .frame(width: 800)
}

#Preview("Paused") {
    DownloadRow(
        download: DownloadFile(
            gid: "def456",
            url: URL(string: "https://example.com/archive.tar.gz")!,
            fileName: "Game assets pack platform edition",
            fileSize: 329_252_864,
            downloadedSize: 82_313_216,
            status: .paused
        )
    )
    .environment(DownloadManager())
    .padding()
    .frame(width: 800)
}
