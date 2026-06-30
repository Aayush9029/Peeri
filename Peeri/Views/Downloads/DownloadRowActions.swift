import Models
import SwiftUI

struct DownloadRowActions: View {
    let download: DownloadFile
    var onShowDetails: () -> Void = {}
    @Environment(DownloadManager.self) private var downloadManager

    var body: some View {
        HStack(spacing: 4) {
            HoverableActionButton(icon: "rectangle.grid.3x3.fill", tooltip: "Details", action: onShowDetails)

            switch download.status {
            case .downloading:
                pauseButton
                finderButton
                cancelButton
            case .paused:
                resumeButton
                finderButton
                cancelButton
            case .completed, .seeding:
                finderButton
                removeButton(tooltip: "Delete")
            case .failed:
                HoverableActionButton(icon: "arrow.clockwise", tooltip: "Retry") {
                    Task { await downloadManager.retryDownload(download) }
                }
                removeButton(tooltip: "Remove")
            case .pending:
                cancelButton
            case .removed:
                removeButton(tooltip: "Remove")
            }
        }
        .padding(.trailing, 12)
    }

    private var pauseButton: some View {
        HoverableActionButton(icon: "pause.fill", tooltip: "Pause") {
            Task { await downloadManager.pauseDownload(download) }
        }
    }

    private var resumeButton: some View {
        HoverableActionButton(icon: "play.fill", tooltip: "Resume") {
            Task { await downloadManager.resumeDownload(download) }
        }
    }

    private var finderButton: some View {
        HoverableActionButton(icon: "folder", tooltip: "Show in Finder") {
            downloadManager.showInFinder(download)
        }
    }

    private var cancelButton: some View {
        HoverableActionButton(icon: "trash", tooltip: "Cancel", hoverColor: .red) {
            Task { await downloadManager.cancelDownload(download) }
        }
    }

    private func removeButton(tooltip: String) -> some View {
        HoverableActionButton(icon: "trash", tooltip: tooltip, hoverColor: .red) {
            downloadManager.removeDownload(download)
        }
    }
}

#Preview {
    DownloadRowActions(download: .sampleDownloading)
        .environment(DownloadManager.preview())
        .padding()
}
