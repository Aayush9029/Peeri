import Models
import Shared
import SwiftUI

@main
struct PeeriApp: App {
    @State private var downloadManager = DownloadManager()
    @State private var daemonManager = Aria2DaemonManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(downloadManager)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Download...") {
                    addDownload()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(downloadManager)
        }
    }

    private func addDownload() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.text, .url]
        panel.prompt = "Add URL"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task {
                    if let fileContents = try? String(contentsOf: url), let downloadURL = URL(string: fileContents.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        await downloadManager.addDownload(url: downloadURL)
                    }
                }
            }
        }
    }
}
