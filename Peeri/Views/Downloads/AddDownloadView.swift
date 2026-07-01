import SwiftUI
import UniformTypeIdentifiers

struct AddDownloadView: View {
    @Environment(DownloadManager.self) private var downloadManager
    @Environment(\.dismiss) private var dismiss

    @State private var model = AddDownloadModel()
    @FocusState private var isURLFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                header
                linkInput
                sourceActions
            }
            .padding(22)

            Divider()

            footer
        }
        .frame(width: 500)
        .onAppear { isURLFieldFocused = true }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 34, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Add Download")
                    .font(.title3.weight(.semibold))

                Text("HTTP, FTP, SFTP, magnet, and video links")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    private var linkInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("URL or Magnet Link")
                    .font(.callout.weight(.semibold))
                Spacer()
                validityLabel
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.urlText)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .focused($isURLFieldFocused)
                    .accessibilityLabel("URL or magnet link")

                if model.isEmpty {
                    placeholder
                }

                if model.isDroppingFile {
                    dropOverlay
                }
            }
            .frame(height: 136)
            .background(inputBackground)
            .overlay(inputBorder)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onDrop(of: [.url, .fileURL, .text], isTargeted: $model.isDroppingFile) { handleDrop($0) }
            .animation(.easeInOut(duration: 0.12), value: model.isDroppingFile)
            .animation(.easeInOut(duration: 0.12), value: model.invalidURLCount)
        }
    }

    private var sourceActions: some View {
        HStack(spacing: 10) {
            sourceAction(
                title: "Paste Link",
                subtitle: model.clipboardPreview ?? "No supported link on clipboard",
                systemImage: "doc.on.clipboard",
                tint: .blue,
                isEnabled: model.clipboardPreview != nil
            ) {
                model.pasteClipboard()
                isURLFieldFocused = true
            }

            sourceAction(
                title: "Open Torrent",
                subtitle: "Choose a .torrent file",
                systemImage: "doc.badge.plus",
                tint: .orange
            ) {
                openTorrent()
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            footerMessage

            Spacer(minLength: 12)

            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)

            Button(addButtonTitle) { addDownloads() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!model.hasValidInput)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.bar)
    }

    @ViewBuilder
    private var validityLabel: some View {
        if model.invalidURLCount > 0 {
            Label("\(model.invalidURLCount) invalid", systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        } else if !model.validURLs.isEmpty {
            Label(readyCountText, systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(verbatim: "https://example.com/file.zip")
            Text(verbatim: "magnet:?xt=urn:btih:...")
            Text(verbatim: "https://youtube.com/watch?v=...")
                .foregroundStyle(.quaternary)
            Text(verbatim: "one per line")
                .foregroundStyle(.quaternary)
        }
        .font(.system(.body, design: .monospaced))
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .allowsHitTesting(false)
    }

    private var dropOverlay: some View {
        ZStack {
            Color.accentColor.opacity(0.12)

            VStack(spacing: 8) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                Text("Drop to add")
                    .font(.callout.weight(.semibold))
            }
            .foregroundStyle(Color.accentColor)
        }
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(.quaternary.opacity(0.35))
    }

    private var inputBorder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(inputBorderColor, lineWidth: model.isDroppingFile ? 2 : 1)
    }

    private var inputBorderColor: Color {
        if model.isDroppingFile {
            return .accentColor
        } else if model.invalidURLCount > 0 {
            return .red.opacity(0.65)
        } else {
            return .primary.opacity(0.12)
        }
    }

    private var addButtonTitle: String {
        model.validURLs.count > 1 ? "Add \(model.validURLs.count)" : "Add"
    }

    private var readyCountText: String {
        model.validURLs.count == 1 ? "1 ready" : "\(model.validURLs.count) ready"
    }

    @ViewBuilder
    private var footerMessage: some View {
        if model.invalidURLCount > 0 {
            Label("Fix invalid links before adding", systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        } else if !model.validURLs.isEmpty {
            Label(
                model.validURLs.count == 1 ? "1 download ready" : "\(model.validURLs.count) downloads ready",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.secondary)
        }
    }

    private func sourceAction(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.quaternary.opacity(0.28))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.primary.opacity(0.08))
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(isEnabled ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
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
                        if fileURL.pathExtension.lowercased() == "torrent" {
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
