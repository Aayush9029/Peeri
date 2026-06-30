import Models
import Shared
import SwiftUI

struct DownloadTable: View {
    let downloads: [DownloadFile]
    var onShowDetails: (DownloadFile) -> Void = { _ in }

    @State private var selection: Set<DownloadFile.ID> = []

    var body: some View {
        Table(downloads, selection: $selection) {
            TableColumn("Name") { download in
                Label {
                    Text(download.fileName)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } icon: {
                    DownloadStatusIcon(status: download.status)
                }
            }
            .width(min: 180, ideal: 280)

            TableColumn("Progress") { download in
                HStack(spacing: 8) {
                    DownloadProgressBar(progress: download.progress, status: download.status)
                    Text(download.progressPercentage)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                }
            }
            .width(min: 140, ideal: 200)

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

            TableColumn("Seeds") { download in
                Text(download.numSeeders.map(String.init) ?? "—").monospacedDigit().foregroundStyle(.secondary)
            }
            .width(min: 50, ideal: 64)

            TableColumn("Peers") { download in
                Text(download.connections.map(String.init) ?? "—").monospacedDigit().foregroundStyle(.secondary)
            }
            .width(min: 50, ideal: 64)
        }
        .tableStyle(.inset)
        .contextMenu(forSelectionType: DownloadFile.ID.self) { ids in
            if let download = download(for: ids) {
                DownloadActionsMenu(download: download) { onShowDetails(download) }
            }
        } primaryAction: { ids in
            if let download = download(for: ids) { onShowDetails(download) }
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
}

#Preview("Populated") {
    DownloadTable(downloads: .sampleList)
        .environment(DownloadManager.preview())
        .frame(width: 860, height: 420)
}

#Preview("Empty") {
    DownloadTable(downloads: [])
        .environment(DownloadManager.preview(downloads: []))
        .frame(width: 860, height: 420)
}
