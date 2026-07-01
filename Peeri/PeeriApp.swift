import Models
import Shared
import SwiftUI

@main
struct PeeriApp: App {
    @Environment(\.openWindow) private var openWindow

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

            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    openWindow(id: "settings")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        Window("Peeri Settings", id: "settings") {
            SettingsView()
                .environment(downloadManager)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 740, height: 680)
    }
}
