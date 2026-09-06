import AppKit
import Models
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class AddDownloadModel {
    var urlText: String
    var isDroppingFile = false
    var destination: URL?
    var selection = Action.download

    enum Action { case download, openTorrent, chooseDirectory }

    var availableActions: [Action] {
        hasValidInput ? [.download, .openTorrent, .chooseDirectory] : [.openTorrent, .chooseDirectory]
    }

    func moveSelection(_ offset: Int) {
        guard let index = availableActions.firstIndex(of: selection) else {
            selection = offset > 0 ? availableActions[0] : availableActions[availableActions.count - 1]
            return
        }
        selection = availableActions[(index + offset + availableActions.count) % availableActions.count]
    }

    func pickDirectory(startingAt directory: URL) {
        let panel = NSOpenPanel()
        panel.title = "Download Folder"
        panel.prompt = "Choose Folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = destination ?? directory
        if panel.runModal() == .OK { destination = panel.url }
    }

    init(text: String = "") { urlText = text }

    var validURLs: [URL] { DownloadLinks(urlText).urls }
    var invalidURLCount: Int { DownloadLinks(urlText).invalidCount }
    var hasValidInput: Bool { DownloadLinks(urlText).isValid }
    var isEmpty: Bool { urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

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

}
