import Models
import SwiftUI

struct DownloadActionsMenu: View {
    let download: DownloadFile
    var onShowDetails: () -> Void = {}
    @Environment(DownloadManager.self) private var downloadManager

    var body: some View {
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
}
