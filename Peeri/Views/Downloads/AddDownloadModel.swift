import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class AddDownloadModel {
    var urlText = ""
    var isDroppingFile = false

    var validURLs: [URL] {
        lines.compactMap { Self.downloadURL(from: $0) }
    }

    var invalidURLCount: Int {
        lines.count - validURLs.count
    }

    var hasValidInput: Bool {
        !validURLs.isEmpty && invalidURLCount == 0
    }

    var isEmpty: Bool {
        urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var lines: [String] {
        urlText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static let supportedURLSchemes: Set<String> = [
        "http",
        "https",
        "ftp",
        "sftp",
        "magnet"
    ]

    var clipboardPreview: String? {
        guard let content = NSPasteboard.general.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !content.isEmpty,
            Self.downloadURL(from: content) != nil
        else { return nil }
        return String(content.prefix(60)) + (content.count > 60 ? "..." : "")
    }

    func pasteClipboard() {
        guard let content = NSPasteboard.general.string(forType: .string) else { return }
        urlText = content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func append(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        urlText = urlText.isEmpty ? trimmed : urlText + "\n" + trimmed
    }

    func pickTorrentFile() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "torrent") ?? .data]
        panel.allowsMultipleSelection = false
        return panel.runModal() == .OK ? panel.url : nil
    }

    private static func downloadURL(from line: String) -> URL? {
        guard let url = URL(string: line),
              let scheme = url.scheme?.lowercased(),
              supportedURLSchemes.contains(scheme)
        else { return nil }
        return url
    }
}
