import SwiftUI

extension SettingsTab {
    var title: String {
        switch self {
        case .general: "General"
        case .downloads: "Downloads"
        case .bitTorrent: "BitTorrent"
        case .video: "Video"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .downloads: "arrow.down.circle"
        case .bitTorrent: "network"
        case .video: "play.rectangle"
        }
    }

    var fill: Color {
        switch self {
        case .general: .indigo
        case .downloads: .blue
        case .bitTorrent: .green
        case .video: .orange
        }
    }
}
