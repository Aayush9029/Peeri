import SwiftUI

struct DownloadStatsFooter: View {
    @Environment(DownloadManager.self) private var downloadManager
    let allPaused: Bool
    @State private var showingCharts = false

    var body: some View {
        HStack(spacing: 14) {
            rate(systemImage: "arrow.down", tint: .blue, bytes: downloadManager.totalDownloadRate)
            rate(systemImage: "arrow.up", tint: .green, bytes: downloadManager.totalUploadRate)

            Spacer()

            Text("\(downloadManager.downloads.count) transfers")
                .font(.caption)
                .foregroundStyle(.secondary)

            chartsButton
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background {
            VisualEffectView(material: .headerView, blendingMode: .withinWindow)
        }
        .overlay(alignment: .top) { Divider() }
    }

    private var chartsButton: some View {
        Button { showingCharts.toggle() } label: {
            TransferActivityPreview(downloads: downloadManager.downloadSpeedHistory, uploads: downloadManager.uploadSpeedHistory)
                .contentShape(.rect)
        }
        .buttonStyle(.borderless)
        .help("Transfer Activity")
        .accessibilityLabel("Transfer Activity")
        .popover(isPresented: $showingCharts, arrowEdge: .bottom) {
            TransferStatsView(
                downloadRate: downloadManager.totalDownloadRate,
                uploadRate: downloadManager.totalUploadRate,
                downloadHistory: downloadManager.downloadSpeedHistory,
                uploadHistory: downloadManager.uploadSpeedHistory,
                totalDownloaded: downloadManager.sessionDownloaded,
                totalUploaded: downloadManager.sessionUploaded,
                allPaused: allPaused
            )
            .frame(width: 460)
            .padding()
        }
    }

    private func rate(systemImage: String, tint: Color, bytes: Int64) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .foregroundStyle(bytes > 0 ? tint : Color.secondary)
                .shadow(color: tint.opacity(bytes > 0 ? 0.5 : 0), radius: 4)
            Text(ByteCountFormatter.peeri(bytes) + "/s")
                .monospacedDigit()
                .foregroundStyle(bytes > 0 ? .primary : .secondary)
        }
        .animation(.smooth(duration: 0.25), value: bytes > 0)
    }
}
