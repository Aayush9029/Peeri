import Models
import Shared
import SwiftUI

struct GeneralSettingsTab: View {
    @Shared(.settings) var settings
    @State private var showRestoreAlert = false

    var body: some View {
        Form {
            Section("General") {
                HStack {
                    Text("Downloads Folder")
                        .frame(width: 150, alignment: .leading)

                    TextField("", text: Binding($settings.downloadDirectory))
                        .textFieldStyle(.roundedBorder)

                    Button(action: selectDownloadDirectory) {
                        Image(systemName: "folder")
                    }
                    .help("Choose a folder")
                }

                Picker("Log Level", selection: Binding($settings.logLevel)) {
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
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all settings to their default values.")
        }
    }

    private func selectDownloadDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Downloads Folder"

        if panel.runModal() == .OK, let url = panel.url {
            $settings.withLock { $0.downloadDirectory = url.path }
        }
    }
}

#Preview {
    GeneralSettingsTab()
}
