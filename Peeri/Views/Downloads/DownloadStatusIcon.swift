import Models
import SwiftUI

struct DownloadStatusIcon: View {
    let status: DownloadStatus

    var body: some View {
        Image(systemName: symbol)
            .foregroundStyle(color)
    }

    private var symbol: String {
        switch status {
        case .downloading: "arrow.down"
        case .paused: "pause"
        case .completed: "checkmark.circle"
        case .pending: "clock"
        case .failed: "exclamationmark.triangle"
        case .seeding: "arrow.up"
        case .removed: "trash"
        }
    }

    private var color: Color {
        switch status {
        case .downloading: .blue
        case .paused: .gray
        case .completed: .green
        case .pending: .orange
        case .failed: .red
        case .seeding: .teal
        case .removed: .gray
        }
    }
}

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
