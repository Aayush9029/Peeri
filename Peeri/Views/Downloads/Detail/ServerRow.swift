import SwiftUI

struct ServerRow: View {
    let server: ServerDisplay

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "server.rack")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(server.host)
                .font(.callout.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                Image(systemName: "arrow.down")
                Text(server.formattedDownloadSpeed)
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(server.downloadSpeed > 0 ? .primary : .secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.gray.opacity(0.06))
        )
    }
}
