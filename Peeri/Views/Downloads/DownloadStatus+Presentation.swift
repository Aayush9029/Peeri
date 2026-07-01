import Models
import SwiftUI

extension DownloadStatus {
    var symbol: String {
        switch self {
        case .downloading: "arrow.down"
        case .paused: "pause"
        case .completed: "checkmark.circle"
        case .pending: "clock"
        case .failed: "exclamationmark.triangle"
        case .seeding: "arrow.up"
        case .removed: "trash"
        }
    }

    var tint: Color {
        switch self {
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
