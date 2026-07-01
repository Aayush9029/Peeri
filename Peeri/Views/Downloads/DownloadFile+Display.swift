import Foundation
import Models

extension DownloadFile {
    var isVideoDownload: Bool {
        gid.hasPrefix("yt-dlp:")
    }

    var displaySize: String {
        if let fileSize, fileSize > 0 {
            return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        } else if downloadedSize > 0 {
            return ByteCountFormatter.string(fromByteCount: downloadedSize, countStyle: .file)
        }
        return "—"
    }

    var displaySpeed: String {
        switch status {
        case .downloading:
            return formattedSpeed
        case .seeding:
            guard let uploadSpeed, uploadSpeed > 0 else { return "—" }
            return ByteCountFormatter.string(fromByteCount: uploadSpeed, countStyle: .binary) + "/s"
        default:
            return "—"
        }
    }

    var displayTimeLeft: String {
        switch status {
        case .completed: return "Completed"
        case .paused: return "Paused"
        case .failed: return "Failed"
        case .pending: return "Waiting"
        case .seeding: return "Seeding"
        case .removed: return "Removed"
        case .downloading:
            if let eta { return Self.etaText(eta) }
            if let downloadSpeed, downloadSpeed > 0 { return "Calculating" }
            return "Starting"
        }
    }

    private static func etaText(_ seconds: TimeInterval) -> String {
        if seconds < 60 { return "\(Int(seconds))s" }
        if seconds < 3600 { return "\(Int(seconds / 60))m" }
        let hours = Int(seconds / 3600)
        let minutes = Int(seconds.truncatingRemainder(dividingBy: 3600) / 60)
        return "\(hours)h \(minutes)m"
    }
}
