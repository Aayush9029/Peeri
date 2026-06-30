import Models
import SwiftUI

struct DownloadListView: View {
    let downloads: [DownloadFile]
    var onShowDetails: (DownloadFile) -> Void = { _ in }

    private var hasTorrents: Bool {
        downloads.contains { $0.isTorrent }
    }

    var body: some View {
        if downloads.isEmpty {
            DownloadsEmptyState()
        } else {
            VStack(spacing: 0) {
                DownloadListHeader(showsTorrentColumns: hasTorrents)
                    .padding(12)

                Divider()
                    .padding(.horizontal, 8)

                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(downloads) { download in
                            DownloadRow(download: download) { onShowDetails(download) }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 6)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
}

#Preview("Populated") {
    DownloadListView(downloads: .sampleList)
        .environment(DownloadManager.preview())
        .frame(width: 820, height: 440)
}

#Preview("Empty") {
    DownloadListView(downloads: [])
        .environment(DownloadManager.preview(downloads: []))
        .frame(width: 820, height: 440)
}
