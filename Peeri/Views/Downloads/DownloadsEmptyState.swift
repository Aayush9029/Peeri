import SwiftUI

struct DownloadsEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 40))
                .foregroundStyle(.quaternary)
            Text("No downloads yet")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Add a download to get started")
                .font(.body)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DownloadsEmptyState()
        .frame(width: 600, height: 400)
}
