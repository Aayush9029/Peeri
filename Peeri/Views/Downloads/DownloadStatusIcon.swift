import Models
import SwiftUI

struct DownloadStatusIcon: View {
    let status: DownloadStatus

    var body: some View {
        Image(systemName: status.symbol)
            .foregroundStyle(status.tint)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 16) {
        ForEach(
            [DownloadStatus.downloading, .seeding, .paused, .completed, .pending, .failed, .removed],
            id: \.self
        ) { status in
            DownloadStatusIcon(status: status)
        }
    }
    .font(.title2)
    .padding()
}
#endif
