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

    var description: String {
        switch self {
        case .general:
            "App defaults, save location, and logging."
        case .downloads:
            "Connection, speed, and file handling behavior."
        case .bitTorrent:
            "Peer discovery and torrent connection limits."
        case .video:
            "YouTube and video download handling through yt-dlp."
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
