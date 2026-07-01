import SwiftUI

struct PeerRow: View {
    let peer: PeerDisplay

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(peer.isSeeder ? Color.green : Color.blue)
                .frame(width: 7, height: 7)
                .help(peer.isSeeder ? "Seeder" : "Leecher")

            Text(peer.ip)
                .font(.callout.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(minWidth: 92, alignment: .leading)

            MiniProgressBar(progress: peer.progress, tint: peer.isSeeder ? .green : .blue)
                .frame(width: 52)

            Text(percentText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)

            Spacer(minLength: 8)

            chokeBadges

            HStack(spacing: 4) {
                Image(systemName: "arrow.down")
                Text(peer.formattedDownloadSpeed)
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(peer.downloadSpeed > 0 ? .primary : .secondary)
            .frame(width: 74, alignment: .trailing)

            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                Text(peer.formattedUploadSpeed)
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(peer.uploadSpeed > 0 ? .primary : .secondary)
            .frame(width: 74, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.06))
        )
    }

    private var percentText: String {
        "\(Int((peer.progress * 100).rounded()))%"
    }

    private var chokeBadges: some View {
        HStack(spacing: 4) {
            if !peer.peerChoking {
                badge("Unchoked by peer", color: .green)
            }
            if !peer.amChoking {
                badge("Unchoking peer", color: .blue)
            }
        }
    }

    private func badge(_ tooltip: String, color: Color) -> some View {
        Circle()
            .fill(color.opacity(0.7))
            .frame(width: 5, height: 5)
            .help(tooltip)
    }
}

private struct MiniProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, geo.size.width * progress))
            }
        }
        .frame(height: 5)
    }
}

#Preview {
    VStack(spacing: 6) {
        PeerRow(peer: .preview(ip: "192.168.1.42", seeder: true, progress: 1.0))
        PeerRow(peer: .preview(ip: "2607:f8b0:4005:80a::200e", seeder: false, progress: 0.34))
    }
    .padding()
    .frame(width: 560)
}
