import Models
import Shared
import SwiftUI

@main
struct PeeriApp: App {
    @State private var downloadManager = DownloadManager()
    @State private var daemonManager = Aria2DaemonManager()
    @State private var appUI = AppUIModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(downloadManager)
                .environment(appUI)
        }
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Download…") {
                    appUI.isAddDownloadPresented = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(downloadManager)
        }
    }
}
