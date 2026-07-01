import Models
import Shared
import SwiftUI

struct DownloadTable: View {
    @Environment(DownloadManager.self) private var downloadManager

    let downloads: [DownloadFile]

    @Binding var selection: Set<DownloadFile.ID>
    @Binding var detailDownload: DownloadFile?

    private var hasTorrents: Bool {
        downloads.contains(where: \.isTorrent)
    }

    var body: some View {
        Table(downloads, selection: $selection) {
            TableColumn("Name") { download in
                HStack(spacing: 9) {
                    DownloadArtworkView(download: download)
                    Text(download.fileName)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .popover(isPresented: detailPresentation(for: download), arrowEdge: .trailing) {
                    DownloadDetailPopoverView(downloadID: download.id)
                        .environment(downloadManager)
                }
            }
            .width(min: 220, ideal: 320)

            TableColumn("Progress") { download in
                DownloadProgressBar(
                    progress: download.progress,
                    status: download.status
                )
            }
            .width(min: 132, ideal: 190)

            TableColumn("Size") { download in
                Text(download.displaySize).monospacedDigit().foregroundStyle(.secondary)
            }
            .width(min: 70, ideal: 90)

            TableColumn("Time Left") { download in
                Text(download.displayTimeLeft).foregroundStyle(.secondary)
            }
            .width(min: 80, ideal: 100)

            TableColumn("Speed") { download in
                Text(download.displaySpeed).monospacedDigit().foregroundStyle(.secondary)
            }
            .width(min: 80, ideal: 100)

            if hasTorrents {
                TableColumn("Seeds") { download in
                    Text(download.numSeeders.map(String.init) ?? "—").monospacedDigit().foregroundStyle(.secondary)
                }
                .width(min: 50, ideal: 64)

                TableColumn("Peers") { download in
                    Text(download.connections.map(String.init) ?? "—").monospacedDigit().foregroundStyle(.secondary)
                }
                .width(min: 50, ideal: 64)
            }
        }
        .tableStyle(.inset)
        .contextMenu(forSelectionType: DownloadFile.ID.self) { ids in
            if let download = download(for: ids) {
                DownloadActionsMenu(download: download) {
                    detailDownload = download
                }
            }
        } primaryAction: { ids in
            if let download = download(for: ids) {
                downloadManager.openDownload(download)
            }
        }
        .overlay {
            if downloads.isEmpty {
                ContentUnavailableView(
                    "No downloads yet",
                    systemImage: "arrow.down.circle",
                    description: Text("Add a download to get started")
                )
            }
        }
    }

    private func download(for ids: Set<DownloadFile.ID>) -> DownloadFile? {
        guard let id = ids.first else { return nil }
        return downloads.first { $0.id == id }
    }

    private func detailPresentation(for download: DownloadFile) -> Binding<Bool> {
        Binding(
            get: { detailDownload?.id == download.id },
            set: { isPresented in
                if !isPresented, detailDownload?.id == download.id {
                    detailDownload = nil
                }
            }
        )
    }
}

#if DEBUG
#Preview("Populated") {
    DownloadTable(
        downloads: .sampleList,
        selection: .constant([]),
        detailDownload: .constant(nil)
    )
        .environment(DownloadManager.preview())
        .frame(width: 860, height: 420)
}

#Preview("Empty") {
    DownloadTable(
        downloads: [],
        selection: .constant([]),
        detailDownload: .constant(nil)
    )
        .environment(DownloadManager.preview(downloads: []))
        .frame(width: 860, height: 420)
}
#endif
