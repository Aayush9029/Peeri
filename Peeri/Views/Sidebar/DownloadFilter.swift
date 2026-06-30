import Models
import Shared

enum DownloadFilter: String, CaseIterable, Identifiable, Hashable {
    case all = "All"
    case downloading = "Downloading"
    case seeding = "Seeding"
    case paused = "Paused"
    case completed = "Completed"
    case failed = "Failed"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: "square.grid.2x2"
        case .downloading: "arrow.down"
        case .seeding: "arrow.up"
        case .paused: "pause"
        case .completed: "checkmark"
        case .failed: "exclamationmark.triangle"
        }
    }

    func matches(_ download: DownloadFile) -> Bool {
        switch self {
        case .all: true
        case .downloading: download.status == .downloading || download.status == .pending
        case .seeding: download.status == .seeding
        case .paused: download.status == .paused
        case .completed: download.status == .completed
        case .failed: download.status == .failed
        }
    }

    func filter(_ downloads: IdentifiedArrayOf<DownloadFile>) -> [DownloadFile] {
        downloads.filter(matches)
    }

    func count(in downloads: IdentifiedArrayOf<DownloadFile>) -> Int {
        downloads.reduce(0) { $0 + (matches($1) ? 1 : 0) }
    }
}
