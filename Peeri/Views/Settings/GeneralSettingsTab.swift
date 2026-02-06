import Models
import Shared
import SwiftUI

struct GeneralSettingsTab: View {
    @Shared(.settings) var settings
    @State private var downloadDirectory: String
    @State private var logLevel: String
    @State private var showRestoreAlert = false

    init() {
        let settings = Shared(.settings).wrappedValue
        _downloadDirectory = State(initialValue: settings.downloadDirectory)
        _logLevel = State(initialValue: settings.logLevel)
    }

    var body: some View {
        Form {
            Section("General") {
                HStack {
                    Text("Downloads Folder")
                        .frame(width: 150, alignment: .leading)

                    TextField("", text: $downloadDirectory)
                        .textFieldStyle(.roundedBorder)

                    Button(action: selectDownloadDirectory) {
                        Image(systemName: "folder")
                    }
                    .help("Choose a folder")
                }

                Picker("Log Level", selection: $logLevel) {
                    Text("Debug").tag("debug")
                    Text("Info").tag("info")
                    Text("Notice").tag("notice")
                    Text("Warning").tag("warn")
                    Text("Error").tag("error")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section {
                Button(role: .destructive, action: { showRestoreAlert = true }) {
                    Text("Restore Defaults")
                }
            }
        }
        .formStyle(.grouped)
        .alert("Restore Defaults?", isPresented: $showRestoreAlert) {
            Button("Restore", role: .destructive) {
                $settings.withLock { $0 = .default }
                downloadDirectory = .default.downloadDirectory
                logLevel = .default.logLevel
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all settings to their default values.")
        }
        .onChange(of: downloadDirectory) { _, newValue in
            $settings.withLock { $0.downloadDirectory = newValue }
        }
        .onChange(of: logLevel) { _, newValue in
            $settings.withLock { $0.logLevel = newValue }
        }
    }

    private func selectDownloadDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Downloads Folder"

        if panel.runModal() == .OK, let url = panel.url {
            settings.downloadDirectory = url.path
        }
    }
}

#Preview {
    GeneralSettingsTab()
}
