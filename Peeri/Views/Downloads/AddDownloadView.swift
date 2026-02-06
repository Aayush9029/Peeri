import SwiftUI
import UniformTypeIdentifiers

struct AddDownloadView: View {
    @Binding var isPresented: Bool
    let downloadManager: DownloadManager

    @State private var urlText: String = ""
    @State private var isDroppingFile = false

    private var urls: [String] {
        urlText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var validURLs: [URL] {
        urls.compactMap { text in
            if text.hasPrefix("magnet:?") { return URL(string: text) }
            return URL(string: text)
        }
    }

    private var hasValidInput: Bool {
        !validURLs.isEmpty
    }

    private var clipboardPreview: String? {
        guard let content = NSPasteboard.general.string(forType: .string),
              !content.isEmpty else { return nil }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http") || trimmed.hasPrefix("magnet:?") || trimmed.hasPrefix("ftp") {
            return String(trimmed.prefix(60)) + (trimmed.count > 60 ? "..." : "")
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Download")
                    .font(.title2.bold())
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // URL Input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("URL or Magnet Link")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !urlText.isEmpty {
                        if hasValidInput {
                            Label("\(validURLs.count) valid", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Label("Invalid URL", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                TextEditor(text: $urlText)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(height: 80)
                    .background(.gray.opacity(0.08))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isDroppingFile ? Color.accentColor : .clear, lineWidth: 2)
                    )
                    .overlay(alignment: .topLeading) {
                        if urlText.isEmpty {
                            Text("Paste URLs (one per line) or drag files here...")
                                .foregroundStyle(.tertiary)
                                .padding(12)
                                .allowsHitTesting(false)
                        }
                    }
                    .onDrop(of: [.url, .fileURL, .text], isTargeted: $isDroppingFile) { providers in
                        handleDrop(providers)
                    }
            }
            .padding(.horizontal, 24)

            // Quick Actions
            HStack(spacing: 8) {
                if let preview = clipboardPreview {
                    Button {
                        if let content = NSPasteboard.general.string(forType: .string) {
                            urlText = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.clipboard")
                            Text(preview)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    openTorrentFile()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.badge.plus")
                        Text("Open .torrent")
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer()

            // Footer
            HStack {
                if validURLs.count > 1 {
                    Text("\(validURLs.count) downloads")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button(validURLs.count > 1 ? "Add All" : "Add") {
                    addDownloads()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(!hasValidInput)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 560, height: 320)
    }

    // MARK: - Actions

    private func addDownloads() {
        for url in validURLs {
            Task {
                await downloadManager.addDownload(url: url)
            }
        }
        isPresented = false
    }

    private func openTorrentFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "torrent") ?? .data]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let fileURL = panel.url {
            Task {
                await downloadManager.addTorrent(fileURL: fileURL)
                isPresented = false
            }
        }
    }

    @MainActor private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            if urlText.isEmpty {
                                urlText = url.absoluteString
                            } else {
                                urlText += "\n" + url.absoluteString
                            }
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                    if let data = item as? Data, let fileURL = URL(dataRepresentation: data, relativeTo: nil) {
                        if fileURL.pathExtension == "torrent" {
                            Task { @MainActor in
                                await downloadManager.addTorrent(fileURL: fileURL)
                                isPresented = false
                            }
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.text.identifier) { item, _ in
                    if let data = item as? Data, let text = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            if urlText.isEmpty {
                                urlText = text
                            } else {
                                urlText += "\n" + text
                            }
                        }
                    }
                }
            }
        }
        return true
    }
}
