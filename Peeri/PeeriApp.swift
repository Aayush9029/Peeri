import Models
import Shared
import SwiftUI

@main
struct PeeriApp: App {
    @Environment(\.openWindow) private var openWindow

    @State private var downloadManager: DownloadManager
    @State private var daemonManager: Aria2DaemonManager
    @State private var blocklistUpdater = TrackerBlocklistUpdater()
    @State private var appUI = AppUIModel()

    init() {
        _downloadManager = State(initialValue: DownloadManager())
        _daemonManager = State(initialValue: Aria2DaemonManager())
    }

    var body: some Scene {
        Window("Peeri", id: "main") {
            ContentView()
                .environment(downloadManager)
                .environment(appUI)
                .task { await blocklistUpdater.runAutomaticUpdates() }
                .onOpenURL { url in
                    Task {
                        if url.isFileURL && url.pathExtension.lowercased() == "torrent" {
                            await downloadManager.addTorrent(fileURL: url)
                        } else {
                            await downloadManager.addDownload(url: url)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    daemonManager.stop()
                }
        }
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1060, height: 660)
        .commands {
            SidebarCommands()
            TransferCommands(
                showPalette: {
                    openWindow(id: "main")
                    appUI.present(.commands)
                },
                pauseAll: { Task { await downloadManager.pauseAll() } },
                resumeAll: { Task { await downloadManager.resumeAll() } }
            )
            CommandGroup(replacing: .newItem) {
                Button {
                    openWindow(id: "main")
                    appUI.present(.addDownload)
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
                .environment(blocklistUpdater)
                .environment(downloadManager)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 740, height: 680)
    }
}
