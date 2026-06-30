import SwiftUI

struct CompactStatsBar: View {
    let downloadRate: Int64
    let uploadRate: Int64
    let totalDownloaded: Int64
    let totalUploaded: Int64

    var body: some View {
        HStack(spacing: 16) {
            rate(icon: "arrow.down", color: .blue, bytes: downloadRate)
            rate(icon: "arrow.up", color: .green, bytes: uploadRate)
            Spacer()
            total("DL", totalDownloaded)
            total("UL", totalUploaded)
        }
        .padding(.horizontal)
        .frame(height: 32)
    }

    private func rate(icon: String, color: Color, bytes: Int64) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(color)
            Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .binary) + "/s")
                .font(.body.monospacedDigit())
        }
    }

    private func total(_ label: String, _ bytes: Int64) -> some View {
        Text("\(label): " + ByteCountFormatter.string(fromByteCount: bytes, countStyle: .binary))
            .font(.callout)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    CompactStatsBar(
        downloadRate: 15_728_640,
        uploadRate: 2_097_152,
        totalDownloaded: 3_220_000_000,
        totalUploaded: 1_073_741_824
    )
    .frame(width: 600)
    .padding()
}
