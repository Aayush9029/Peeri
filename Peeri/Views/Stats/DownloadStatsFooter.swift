import SwiftUI

struct DownloadStatsFooter: View {
    @Environment(DownloadManager.self) private var downloadManager
    let allPaused: Bool
    @State private var showingCharts = false

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 14) {
                rate(systemImage: "arrow.down", tint: .blue, bytes: downloadManager.totalDownloadRate)
                rate(systemImage: "arrow.up", tint: .green, bytes: downloadManager.totalUploadRate)

                Spacer()

                total("DL", downloadManager.sessionDownloaded)
                total("UL", downloadManager.sessionUploaded)

                chartsButton
            }
            .font(.callout)
            .padding(.horizontal, 12)
            .frame(height: 30)
        }
        .background(.bar)
        .opacity(allPaused ? 0.6 : 1)
    }

    private var chartsButton: some View {
        Button { showingCharts.toggle() } label: {
            Image(systemName: "chart.xyaxis.line")
        }
        .buttonStyle(.borderless)
        .help("Transfer Activity")
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
            Image(systemName: systemImage).foregroundStyle(tint)
            Text(ByteCountFormatter.peeri(bytes) + "/s")
                .monospacedDigit()
        }
    }

    private func total(_ label: String, _ bytes: Int64) -> some View {
        Text("\(label) " + ByteCountFormatter.peeri(bytes))
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
    }
}

#if DEBUG
#Preview {
    DownloadStatsFooter(allPaused: false)
        .environment(DownloadManager.preview())
        .frame(width: 700)
}
#endif
