import Models
import Shared
import SwiftUI

struct DownloadTable: View {
    @Environment(DownloadManager.self) private var downloadManager

    let downloads: [DownloadFile]
    var emptyTitle = "No downloads yet"
    var emptyDescription = "Add a download to get started."

    @Binding var selection: Set<DownloadFile.ID>
    let showDetail: (DownloadFile) -> Void

    @State private var sortOrder = [KeyPathComparator(\DownloadFile.displayName)]

    private var sortedDownloads: [DownloadFile] { downloads.sorted(using: sortOrder) }

    var body: some View {
        Table(sortedDownloads, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.displayName) { download in
                HStack(spacing: 9) {
                    DownloadArtworkView(download: download)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(download.displayName)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text(download.status.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

            }
            .width(min: 220, ideal: 320)

            TableColumn("Progress", value: \.progress) { download in
                VStack(alignment: .leading, spacing: 5) {
                    DownloadProgressBar(progress: download.progress, status: download.status)
                    Text(download.progressPercentage)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
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
        }
        .tableStyle(.inset)
        .scrollContentBackground(.hidden)
        .alternatingRowBackgrounds(.disabled)
        .contextMenu(forSelectionType: DownloadFile.ID.self) { ids in
            if let download = download(for: ids) {
                DownloadActionsMenu(download: download) {
                    showDetail(download)
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
                    emptyTitle,
                    systemImage: "arrow.down.circle",
                    description: Text(emptyDescription)
                )
            }
        }
    }

    private func download(for ids: Set<DownloadFile.ID>) -> DownloadFile? {
        guard let id = ids.first else { return nil }
        return downloads.first { $0.id == id }
    }


}
