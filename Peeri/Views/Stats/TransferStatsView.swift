import SwiftUI

struct TransferStatsView: View {
    let downloadRate: Int64
    let uploadRate: Int64
    let downloadHistory: [Double]
    let uploadHistory: [Double]
    let totalDownloaded: Int64
    let totalUploaded: Int64
    var allPaused: Bool = false

    private var hasUploadActivity: Bool {
        uploadHistory.contains { $0 > 0 }
    }

    var body: some View {
        HStack(alignment: .top) {
            ZStack {
                TransferChart(numbers: downloadHistory, tint: .blue)
                if hasUploadActivity {
                    TransferChart(numbers: uploadHistory, tint: .green)
                }
            }
            .saturation(allPaused ? 0 : 1)
            .opacity(allPaused ? 0.5 : 1)

            VStack(alignment: .leading) {
                Text("DOWNLOAD / UPLOAD PER SEC")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack {
                    HStack {
                        Image(systemName: "arrow.down")
                        Text(formattedDownloadRate)
                    }
                    Spacer()
                    HStack {
                        Image(systemName: "arrow.up")
                        Text(formattedUploadRate)
                    }
                }
                .font(.title.bold())
                Spacer()
                VStack(alignment: .leading, spacing: 32) {
                    totalColumn("Total Downloaded", totalDownloaded)
                    totalColumn("Total Uploaded", totalUploaded)
                }
                .font(.title)
                Spacer()
            }
            .padding()
        }
    }

    private func totalColumn(_ label: String, _ bytes: Int64) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .binary))
        }
    }

    private var formattedDownloadRate: String {
        ByteCountFormatter.string(fromByteCount: downloadRate, countStyle: .binary) + "/s"
    }

    private var formattedUploadRate: String {
        ByteCountFormatter.string(fromByteCount: uploadRate, countStyle: .binary) + "/s"
    }
}

#Preview("Active") {
    TransferStatsView(
        downloadRate: 15_728_640,
        uploadRate: 2_097_152,
        downloadHistory: (0..<60).map { 12_000_000 * (1 + sin(Double($0) / 6)) },
        uploadHistory: (0..<60).map { 1_500_000 * (1 + cos(Double($0) / 5)) },
        totalDownloaded: 3_220_000_000,
        totalUploaded: 1_073_741_824
    )
    .frame(width: 640, height: 320)
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
    .frame(width: 640, height: 320)
    .padding()
}
