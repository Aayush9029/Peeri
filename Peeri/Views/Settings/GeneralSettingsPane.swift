import Models
import Shared
import SwiftUI

struct GeneralSettingsPane: View {
    @Shared(.settings) private var settings
    @State private var showRestoreAlert = false
    @State private var folderError: String?

    var body: some View {
        SettingsForm {
            Section("Downloads") {
                Toggle("Resume incomplete downloads", isOn: Binding($settings.continueDownloads))
                Toggle("Verify downloaded files", isOn: Binding($settings.checkIntegrity))
                Text("Resume partial web downloads and check files when a checksum is available.")
                    .settingDescription()
            }
            Section("Downloads Folder") {
                HStack(spacing: 8) {
                    Text("Location")
                    Spacer(minLength: 12)
                    HStack(spacing: 8) {
                        Text(settings.downloadDirectory)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Button("Choose Folder…") {
                            selectDownloadDirectory()
                        }
                    }
                }

                LabeledContent("Access") {
                    if settings.downloadDirectoryBookmark == nil {
                        Text("Default")
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Text("Save new downloads in this folder.")
                    .settingDescription()

                if let folderError {
                    Text(folderError)
                        .foregroundStyle(.red)
                        .settingDescription()
                }
            }

            Section("Logging") {
                Picker("Log Level", selection: Binding($settings.logLevel)) {
                    Text("Debug").tag("debug")
                    Text("Info").tag("info")
                    Text("Notice").tag("notice")
                    Text("Warning").tag("warn")
                    Text("Error").tag("error")
                }
                Text("Controls how much detail appears in the download log.")
                    .settingDescription()
            }

            Section("Defaults") {
                Button("Restore Defaults", role: .destructive) {
                    showRestoreAlert = true
                }
            }
        }
        .alert("Restore Defaults?", isPresented: $showRestoreAlert) {
            Button("Restore", role: .destructive) {
                $settings.withLock { $0 = .default }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all Peeri settings to their default values.")
        }
    }

    private func selectDownloadDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Choose where Peeri saves downloads."

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let bookmark = try DownloadDirectoryAccess.bookmarkData(for: url)
            $settings.withLock {
                $0.downloadDirectory = url.path
                $0.downloadDirectoryBookmark = bookmark
            }
            folderError = nil
        } catch {
            folderError = "Peeri could not save access to this folder: \(error.localizedDescription)"
        }
    }
}
