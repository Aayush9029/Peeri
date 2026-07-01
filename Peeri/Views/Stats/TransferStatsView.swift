import SwiftUI

struct TransferStatsView: View {
    let downloadRate: Int64
    let uploadRate: Int64
    let downloadHistory: [Double]
    let uploadHistory: [Double]
    let totalDownloaded: Int64
    let totalUploaded: Int64
    var allPaused: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            TransferStatTile(
                title: "Download",
                systemImage: "arrow.down",
                tint: .blue,
                rate: downloadRate,
                total: totalDownloaded,
                history: downloadHistory,
                dimmed: allPaused
            )
            TransferStatTile(
                title: "Upload",
                systemImage: "arrow.up",
                tint: .green,
                rate: uploadRate,
                total: totalUploaded,
                history: uploadHistory,
                dimmed: allPaused
            )
        }
    }
}

#if DEBUG
#Preview("Active") {
    TransferStatsView(
        downloadRate: 15_728_640,
        uploadRate: 2_097_152,
        downloadHistory: (0..<60).map { 12_000_000 * (1 + sin(Double($0) / 6)) },
        uploadHistory: (0..<60).map { 1_500_000 * (1 + cos(Double($0) / 5)) },
        totalDownloaded: 3_220_000_000,
        totalUploaded: 1_073_741_824
    )
    .frame(width: 680)
    .padding()
}

#Preview("Paused") {
    TransferStatsView(
        downloadRate: 0,
        uploadRate: 0,
        downloadHistory: Array(repeating: 0, count: 60),
        uploadHistory: Array(repeating: 0, count: 60),
        totalDownloaded: 536_870_912,
        totalUploaded: 0,
        allPaused: true
    )
    .frame(width: 680)
    .padding()
}
#endif
