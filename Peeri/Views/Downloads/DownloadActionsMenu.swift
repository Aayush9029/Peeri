import Models
import SwiftUI

struct DownloadActionsMenu: View {
    let download: DownloadFile
    var onShowDetails: () -> Void = {}

    @Environment(DownloadManager.self) private var downloadManager

    var body: some View {
        Button { downloadManager.openDownload(download) } label: { Label("Open", systemImage: "arrow.up.right.square") }
            .disabled(!hasLocalFile)
        Button(action: onShowDetails) { Label("Get Info", systemImage: "info.circle") }
        Button { downloadManager.showInFinder(download) } label: { Label("Show in Finder", systemImage: "folder") }
            .disabled(!hasLocalFile)
        if hasLocalFile {
            Button { downloadManager.copyFilePath(download) } label: { Label("Copy File Path", systemImage: "doc.on.doc") }
        }
        Button { downloadManager.copyURL(download) } label: { Label("Copy URL", systemImage: "link") }
        Divider()

        switch download.status {
        case .downloading where download.isVideoDownload:
            cancelItem
        case .downloading:
            Button { Task { await downloadManager.pauseDownload(download) } } label: { Label("Pause", systemImage: "pause.fill") }
            cancelItem
        case .paused:
            Button { Task { await downloadManager.resumeDownload(download) } } label: { Label("Resume", systemImage: "play.fill") }
            cancelItem
        case .completed, .seeding:
            removeItem()
        case .failed:
            Button { Task { await downloadManager.retryDownload(download) } } label: { Label("Retry", systemImage: "arrow.clockwise") }
            removeItem()
        case .pending:
            cancelItem
        case .removed:
            removeItem()
        }
    }

    private var cancelItem: some View {
        Button(role: .destructive) { Task { await downloadManager.cancelDownload(download) } } label: { Label("Cancel", systemImage: "xmark.circle") }
    }

    private func removeItem() -> some View {
        Button(role: .destructive) { downloadManager.removeDownload(download) } label: { Label("Remove Download", systemImage: "trash") }
    }

    private var hasLocalFile: Bool {
        downloadManager.resolvedFileURL(for: download) != nil
    }
}
