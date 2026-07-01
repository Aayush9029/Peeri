import SwiftUI

struct TransferStatTile: View {
    let title: String
    let systemImage: String
    let tint: Color
    let rate: Int64
    let total: Int64
    let history: [Double]
    var dimmed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Total " + ByteCountFormatter.peeri(total))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }

            Text(ByteCountFormatter.peeri(rate) + "/s")
                .font(.title2.weight(.semibold).monospacedDigit())

            TransferChart(samples: history, tint: tint)
                .frame(height: 56)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 12))
        .saturation(dimmed ? 0 : 1)
        .opacity(dimmed ? 0.6 : 1)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 12) {
        TransferStatTile(
            title: "Download",
            systemImage: "arrow.down",
            tint: .blue,
            rate: 15_728_640,
            total: 3_220_000_000,
            history: (0..<60).map { 12_000_000 * (1 + sin(Double($0) / 6)) }
        )
        TransferStatTile(
            title: "Upload",
            systemImage: "arrow.up",
            tint: .green,
            rate: 2_097_152,
            total: 1_073_741_824,
            history: (0..<60).map { 1_500_000 * (1 + cos(Double($0) / 5)) }
        )
    }
    .frame(width: 640)
    .padding()
}
#endif
