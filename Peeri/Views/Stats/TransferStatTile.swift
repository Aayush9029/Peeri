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
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(tint.opacity(0.15)) }
        .saturation(dimmed ? 0 : 1)
        .opacity(dimmed ? 0.6 : 1)
    }
}
