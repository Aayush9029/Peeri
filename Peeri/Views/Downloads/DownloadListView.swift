import Models
import SwiftUI

struct DownloadListView: View {
    let downloads: [DownloadFile]

    private var hasTorrents: Bool {
        downloads.contains { $0.isTorrent }
    }

    var body: some View {
        if downloads.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(.quaternary)
                Text("No downloads yet")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("Add a download to get started")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        } else {
            VStack(spacing: 0) {
                // Column headers — pinned above scroll
                columnHeaders
                    .padding(12)

                Divider()
                    .padding(.horizontal, 8)

                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(downloads) { download in
                            DownloadRow(download: download)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 6)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 28)

            Text("NAME")
                .frame(minWidth: 120, alignment: .leading)

            Spacer(minLength: 12)

            Text("PROGRESS")
                .frame(minWidth: 100, maxWidth: 180, alignment: .leading)

            Spacer(minLength: 12)

            Text("SIZE")
                .frame(width: 80, alignment: .leading)

            Spacer(minLength: 12)

            Text("TIME LEFT")
                .frame(width: 90, alignment: .leading)

            Spacer(minLength: 12)

            Text("SPEED")
                .frame(width: 90, alignment: .leading)

            if hasTorrents {
                Spacer(minLength: 12)

                Text("SEEDS")
                    .frame(width: 50, alignment: .leading)

                Spacer(minLength: 12)

                Text("PEERS")
                    .frame(width: 50, alignment: .leading)
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
    }
}
