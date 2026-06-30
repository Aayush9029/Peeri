import SwiftUI
import UniformTypeIdentifiers

struct AddDownloadView: View {
    @Environment(DownloadManager.self) private var downloadManager
    @Environment(\.dismiss) private var dismiss
    @State private var model = AddDownloadModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            urlInput
                .padding(.horizontal, 24)
            quickActions
                .padding(.horizontal, 24)
                .padding(.top, 12)
            Spacer()
            footer
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
        .frame(width: 560, height: 320)
    }

    private var header: some View {
        HStack {
            Text("Add Download")
                .font(.title2.bold())
            Spacer()
            Button { dismiss() } label: {
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
    }

    private var urlInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("URL or Magnet Link")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                validityLabel
            }

            TextEditor(text: $model.urlText)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(height: 80)
                .background(.gray.opacity(0.08))
                .clipShape(.rect(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(model.isDroppingFile ? Color.accentColor : .clear, lineWidth: 2)
                )
                .overlay(alignment: .topLeading) {
                    if model.urlText.isEmpty {
                        Text("Paste URLs (one per line) or drag files here...")
                            .foregroundStyle(.tertiary)
                            .padding(12)
                            .allowsHitTesting(false)
                    }
                }
                .onDrop(of: [.url, .fileURL, .text], isTargeted: $model.isDroppingFile) { providers in
                    handleDrop(providers)
                }
        }
    }

    @ViewBuilder
    private var validityLabel: some View {
        if !model.isEmpty {
            if model.hasValidInput {
                Label("\(model.validURLs.count) valid", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Label("Invalid URL", systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 8) {
            if let preview = model.clipboardPreview {
                chipButton(icon: "doc.on.clipboard", text: preview) { model.pasteClipboard() }
            }
            chipButton(icon: "doc.badge.plus", text: "Open .torrent") { openTorrent() }
            Spacer()
        }
    }

    private func chipButton(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(text)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.gray.opacity(0.1))
            .clipShape(.rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            if model.validURLs.count > 1 {
                Text("\(model.validURLs.count) downloads")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.escape, modifiers: [])

            Button(model.validURLs.count > 1 ? "Add All" : "Add") { addDownloads() }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(!model.hasValidInput)
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Actions

    private func addDownloads() {
        for url in model.validURLs {
            Task { await downloadManager.addDownload(url: url) }
        }
        dismiss()
    }

    private func openTorrent() {
        guard let fileURL = model.pickTorrentFile() else { return }
        Task {
            await downloadManager.addTorrent(fileURL: fileURL)
            dismiss()
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                    guard let data = item as? Data,
                          let fileURL = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    DispatchQueue.main.async {
                        if fileURL.pathExtension == "torrent" {
                            Task {
                                await downloadManager.addTorrent(fileURL: fileURL)
                                dismiss()
                            }
                        } else {
                            model.append(fileURL.absoluteString)
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    DispatchQueue.main.async { model.append(url.absoluteString) }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.text.identifier) { item, _ in
                    guard let data = item as? Data, let text = String(data: data, encoding: .utf8) else { return }
                    DispatchQueue.main.async { model.append(text) }
                }
            }
        }
        return true
    }
}

#Preview {
    AddDownloadView()
        .environment(DownloadManager.preview())
}
