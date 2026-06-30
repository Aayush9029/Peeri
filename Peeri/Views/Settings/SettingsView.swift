import Models
import Shared
import SwiftUI

struct SettingsView: View {
    @Shared(.settings) var settings
    @State private var selectedTab: SettingsTab = .general
    @Environment(DownloadManager.self) var downloadManager

    enum SettingsTab {
        case general
        case downloads
        case bitTorrent
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(SettingsTab.general)

            DownloadsSettingsTab()
                .tabItem {
                    Label("Downloads", systemImage: "arrow.down.circle")
                }
                .tag(SettingsTab.downloads)

            BitTorrentSettingsTab()
                .tabItem {
                    Label("BitTorrent", systemImage: "network")
                }
                .tag(SettingsTab.bitTorrent)
        }
        .frame(minWidth: 500, minHeight: 400)
        .padding()
    }
}

#Preview {
    SettingsView()
        .environment(DownloadManager.preview())
}
