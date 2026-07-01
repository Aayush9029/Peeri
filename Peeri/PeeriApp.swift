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
                Button {
                    appUI.isAddDownloadPresented = true
                } label: {
                    Label("Add Download…", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(downloadManager)
        }
        .windowToolbarStyle(.unified)
        .defaultSize(width: 740, height: 680)
    }
}
