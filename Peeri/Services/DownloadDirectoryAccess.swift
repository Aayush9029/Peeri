import Foundation
import Models

struct DownloadDirectoryAccess {
    let url: URL
    let isSecurityScoped: Bool

    init(settings: PeeriSettings) {
        if let bookmarkedURL = Self.bookmarkedURL(from: settings) {
            url = bookmarkedURL
            isSecurityScoped = true
        } else {
            url = URL(fileURLWithPath: settings.downloadDirectory, isDirectory: true)
            isSecurityScoped = false
        }
    }

    func startAccessing() -> Bool {
        guard isSecurityScoped else { return false }
        return url.startAccessingSecurityScopedResource()
    }

    func stopAccessing(_ didStartAccessing: Bool) {
        guard didStartAccessing else { return }
        url.stopAccessingSecurityScopedResource()
    }

    static func bookmarkData(for url: URL) throws -> Data {
        try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    private static func bookmarkedURL(from settings: PeeriSettings) -> URL? {
        guard let bookmark = settings.downloadDirectoryBookmark else { return nil }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ), !isStale else { return nil }
        return url
    }
}
