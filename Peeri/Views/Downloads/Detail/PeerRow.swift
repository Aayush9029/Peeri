import SwiftUI

struct PeerRow: View {
    let peer: PeerDisplay
    var location: PeerLocation = .unavailable

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if let name = location.name {
                        Text([location.flag, name].compactMap { $0 }.joined(separator: " "))
                            .font(.callout.weight(.medium))
                            .lineLimit(1)
                            .help("Approximate location from the bundled DB-IP Country Lite database. Country lookup happens on your Mac.")
                    }
                    Text(peer.ip)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 4) {
                    Label(peer.formattedDownloadSpeed, systemImage: "arrow.down")
                    Label(peer.formattedUploadSpeed, systemImage: "arrow.up")
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }
            HStack {
                Text(peer.isSeeder ? "Seeder" : "Peer")
                Spacer()
                Text(peer.progress, format: .percent.precision(.fractionLength(0)))
                    .monospacedDigit()
                    .accessibilityLabel("Peer progress")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.quaternary)
                .frame(height: 0.5)
        }
    }
}
