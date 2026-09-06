import Models
import Shared
import SwiftUI
import UniformTypeIdentifiers

struct AddDownloadView: View {
    let goBack: () -> Void
    @Environment(DownloadManager.self) private var downloadManager
    @Environment(\.dismiss) private var dismiss
    @Shared(.settings) private var settings
    @Bindable var model: AddDownloadModel
    @FocusState private var isURLFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 26, height: 26)
                        .background(.primary.opacity(0.05), in: .rect(cornerRadius: 7))
                }
                .buttonStyle(.plain)
                .help("Back to commands")
                .accessibilityLabel("Back to commands")
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $model.urlText)
                        .font(.system(size: 18))
                        .scrollContentBackground(.hidden)
                        .focused($isURLFieldFocused)
                        .accessibilityLabel("Download links")
                        .onKeyPress(keys: [.return], phases: .down) { key in
                            guard !key.modifiers.contains(.shift) else { return .ignored }
                            activateSelection()
                            return .handled
                        }
                    if model.isEmpty {
                        Text("Paste a link or magnet…")
                            .font(.system(size: 18))
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
                .frame(height: model.urlText.contains("\n") ? 76 : 26)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)

            VStack(alignment: .leading, spacing: 4) {
                if model.hasValidInput {
                    Button(action: addDownloads) {
                        CommandPanelRow(
                            title: DownloadLinks(model.urlText).summary,
                            subtitle: model.validURLs.count > 1 ? "Downloads" : "Ready to download",
                            symbol: "arrow.down.circle", selected: model.selection == .download
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(model.selection == .download ? .isSelected : [])
                }

                Button(action: openTorrent) {
                    CommandPanelRow(title: "Open Torrent File…", symbol: "doc", shortcut: "⌘O", selected: model.selection == .openTorrent)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("o", modifiers: .command)
                .accessibilityAddTraits(model.selection == .openTorrent ? .isSelected : [])

                Button(action: chooseDirectory) {
                    CommandPanelRow(
                        title: "Save to",
                        subtitle: ((model.destination?.path ?? settings.downloadDirectory) as NSString).abbreviatingWithTildeInPath,
                        symbol: "folder", selected: model.selection == .chooseDirectory
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(model.selection == .chooseDirectory ? .isSelected : [])

                Text(model.invalidURLCount > 0 ? "Enter a full download URL or magnet link." : "Paste multiple links on separate lines, or drop a torrent file.")
                    .font(.caption)
                    .foregroundStyle(model.invalidURLCount > 0 ? Color.red : Color.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)

            CommandPanelFooter {
                CommandPanelAction(title: "Cancel", key: "esc") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                CommandPanelAction(title: actionTitle, key: "↵", action: activateSelection)
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.selection == .download && !model.hasValidInput)
                    .opacity(model.selection == .download && !model.hasValidInput ? 0.4 : 1)
            }
        }
        .onDrop(of: [.url, .fileURL, .text], isTargeted: $model.isDroppingFile, perform: handleDrop)
        .overlay {
            if model.isDroppingFile {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.regularMaterial)
                    .overlay {
                        Label("Drop to add", systemImage: "arrow.down.doc")
                            .font(.title3)
                    }
                    .allowsHitTesting(false)
            }
        }
        .onAppear { isURLFieldFocused = true }
        .onChange(of: model.hasValidInput) { _, valid in
            model.selection = valid ? .download : .openTorrent
        }
        .onKeyPress(.downArrow) { model.moveSelection(1); return .handled }
        .onKeyPress(.upArrow) { model.moveSelection(-1); return .handled }
    }

    private var actionTitle: String {
        switch model.selection {
        case .download: model.validURLs.count > 1 ? "Add \(model.validURLs.count) Downloads" : "Add Download"
        case .openTorrent: "Open Torrent File"
        case .chooseDirectory: "Choose Folder"
        }
    }

    private func activateSelection() {
        switch model.selection {
        case .download: if model.hasValidInput { addDownloads() }
        case .openTorrent: openTorrent()
        case .chooseDirectory: chooseDirectory()
        }
    }

    private func chooseDirectory() {
        model.pickDirectory(startingAt: URL(fileURLWithPath: settings.downloadDirectory, isDirectory: true))
        model.selection = model.hasValidInput ? .download : .openTorrent
        isURLFieldFocused = true
    }

    private func addDownloads() {
        for url in model.validURLs {
            Task { await downloadManager.addDownload(url: url, destination: model.destination) }
        }
        dismiss()
    }

    private func openTorrent() {
        guard let fileURL = model.pickTorrentFile() else { return }
        Task {
            await downloadManager.addTorrent(fileURL: fileURL, destination: model.destination)
            dismiss()
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                    guard let value = Self.droppedText(item),
                          let fileURL = URL(string: value) else { return }
                    DispatchQueue.main.async {
                        if fileURL.pathExtension.lowercased() == "torrent" {
                            Task {
                                await downloadManager.addTorrent(fileURL: fileURL, destination: model.destination)
                                dismiss()
                            }
                        } else {
                            model.append(fileURL.absoluteString)
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
                    guard let text = Self.droppedText(item) else { return }
                    DispatchQueue.main.async { model.append(text) }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.text.identifier) { item, _ in
                    guard let text = Self.droppedText(item) else { return }
                    DispatchQueue.main.async { model.append(text) }
                }
            }
        }
        return true
    }

    nonisolated private static func droppedText(_ item: NSSecureCoding?) -> String? {
        if let url = item as? URL { return url.absoluteString }
        if let text = item as? String { return text }
        if let data = item as? Data { return String(data: data, encoding: .utf8) }
        return nil
    }
}
