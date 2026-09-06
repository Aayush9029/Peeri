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
