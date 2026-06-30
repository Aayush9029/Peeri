import SwiftUI

struct DownloadStatsFooter: View {
    @Environment(DownloadManager.self) private var downloadManager
    @Binding var collapsed: Bool
    let allPaused: Bool

    var body: some View {
        VStack(spacing: 0) {
            collapseToggle

            if collapsed {
                CompactStatsBar(
                    downloadRate: downloadManager.totalDownloadRate,
                    uploadRate: downloadManager.totalUploadRate,
                    totalDownloaded: downloadManager.sessionDownloaded,
                    totalUploaded: downloadManager.sessionUploaded
                )
                .transition(.opacity)
            } else {
                TransferStatsView(
                    downloadRate: downloadManager.totalDownloadRate,
                    uploadRate: downloadManager.totalUploadRate,
                    downloadHistory: downloadManager.downloadSpeedHistory,
                    uploadHistory: downloadManager.uploadSpeedHistory,
                    totalDownloaded: downloadManager.sessionDownloaded,
                    totalUploaded: downloadManager.sessionUploaded,
                    allPaused: allPaused
                )
                .frame(height: 320)
                .padding()
                .transition(.opacity)
            }
        }
    }

    private var collapseToggle: some View {
        ZStack {
            Divider()
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { collapsed.toggle() }
            } label: {
                Image(systemName: collapsed ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 16)
                    .background(.bar)
                    .clipShape(.rect(cornerRadius: 4))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DownloadStatsFooter(collapsed: .constant(false), allPaused: false)
        .environment(DownloadManager.preview())
        .frame(width: 700)
}
